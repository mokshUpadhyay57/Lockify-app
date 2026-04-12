const functions = require("firebase-functions");
const { getAuth } = require("firebase-admin/auth");
const axios = require("axios");
const logger = require("firebase-functions/logger");
const { createOrder } = require("./payments/createOrder");
const { paymentSuccessWebhook } = require("./payments/success");
const { verifyPayment } = require("./payments/verifyPayment");
const { admin } = require("./config/firebase");
const { setGlobalOptions } = require("firebase-functions/v2");

// ✅ Applies to ALL v2 functions in this file (and imports)
setGlobalOptions({
  memory: "256MiB",
  timeoutSeconds: 10,
  concurrency: 10,
  maxInstances: 1,
});

// Create Order HTTP Function (used by client to initiate payment)
exports.createOrder = createOrder;
exports.paymentSuccessWebhook = paymentSuccessWebhook;
exports.verifyPayment = verifyPayment;

// Cashfree credentials
const clientId = "CF10622351D0PD6TVEJ5OS739PLQLG";
const clientSecret = "cfsk_ma_test_f591e873df5b0e07c0e052494848479c_96a8b0b7";
const authURL = "https://payout-gamma.cashfree.com/payout/v1";
const baseURL = "https://sandbox.cashfree.com/payout";

const auth = getAuth();

// Get Auth Token
async function getAuthToken() {
  const response = await axios.post(`${authURL}/authorize`, {}, {
    headers: {
      'x-client-id': clientId,
      'x-client-secret': clientSecret,
    }
  });

  console.log("Cashfree /authorize response:", response.data);

  if (!response.data || !response.data.data || !response.data.data.token) {
    logger.log("Invalid response from Cashfree /authorize:", response.data);
    throw new Error("Invalid response from Cashfree /authorize: " + JSON.stringify(response.data));
  }

  return response.data.data.token;
}

// Verify Token
async function verifyToken(token) {
  try {
    const response = await axios.post(`${authURL}/verifyToken`, {}, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return response.data;
  } catch (err) {
    console.error("Token verification failed:", err.message);
    throw new functions.https.HttpsError("unauthenticated", "Invalid token");
  }
}

// Verify Firebase Token
async function verifyFirebaseToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('No token provided');
  }
  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken.uid;
  } catch (err) {
    throw new Error('Invalid token');
  }
}

// -----------------------------
// 🔁 addBeneficiary HTTP Function
// -----------------------------
exports.addBeneficiary = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send({ error: "Method Not Allowed" });
  }

  try {
    const uid = await verifyFirebaseToken(req);
    logger.log("addBeneficiary called by UID:", uid);
    logger.log("Request body:", req.body);

    const token = await getAuthToken();
    await verifyToken(token);

    const response = await axios.post(`${baseURL}/beneficiary`, req.body, {
      headers: { 
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'x-client-id': clientId,
        'x-client-secret': clientSecret,
        'x-api-version': '2024-01-01',
        'x-request-id': `req-${Date.now()}`, // Unique request ID for tracing
      },

    });

    logger.log("addBeneficiary response:", response.data);
    return res.status(200).send(response.data);
  } catch (err) {
    const errorMsg = err.response?.data?.message || err.message || "Unknown error";
    logger.error("addBeneficiary error:", errorMsg);
    return res.status(500).send({ error: errorMsg });
  }
});

// Request Transfer (Payout)
exports.requestTransfer = functions.https.onCall(async (data, context) => {
  try {
    const token = await getAuthToken();
    await verifyToken(token);

    const response = await axios.post(`${payoutTestURL}/requestTransfer`, data, {
      headers: { Authorization: `Bearer ${token}` },
    });

    return response.data;
  } catch (err) {
    let errorMsg = "Unknown error";
    if (err.response && err.response.data && err.response.data.message) {
      errorMsg = err.response.data.message;
    } else if (err.message) {
      errorMsg = err.message;
    }
    console.error("requestTransfer error:", errorMsg);
    throw new functions.https.HttpsError("internal", errorMsg);
  }
});
