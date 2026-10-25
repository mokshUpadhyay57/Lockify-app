const functions = require("firebase-functions");
const { getAuth } = require("firebase-admin/auth");
const axios = require("axios");
const logger = require("firebase-functions/logger");
const { defineString } = require("firebase-functions/params");
const { createOrder, createEasySplitOrder } = require("./payments/createOrder");
const { paymentSuccessWebhook } = require("./payments/success");
const { verifyPayment } = require("./payments/verifyPayment");
const { getUnlockedContent } = require("./payments/getUnlockedContent");
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
exports.createEasySplitOrder = createEasySplitOrder;
exports.paymentSuccessWebhook = paymentSuccessWebhook;
exports.verifyPayment = verifyPayment;
exports.getUnlockedContent = getUnlockedContent;

const payoutClientId = defineString("CF_PAYOUT_CLIENT_ID", { default: "" });
const payoutClientSecret = defineString("CF_PAYOUT_CLIENT_SECRET", { default: "" });
const payoutAuthURL = defineString("CF_PAYOUT_AUTH_URL", {
  default: "https://payout-gamma.cashfree.com/payout/v1",
});
const payoutBaseURL = defineString("CF_PAYOUT_BASE_URL", {
  default: "https://sandbox.cashfree.com/payout",
});

// Easy Split Sandbox configurations
const easySplitClientId = defineString("CF_EASY_SPLIT_CLIENT_ID", { default: "" });
const easySplitClientSecret = defineString("CF_EASY_SPLIT_CLIENT_SECRET", { default: "" });
const easySplitBaseURL = defineString("CF_EASY_SPLIT_BASE_URL", {
  default: "https://sandbox.cashfree.com/pg",
});

const auth = getAuth();

// Get Auth Token
async function getAuthToken() {
  const clientId = payoutClientId.value();
  const clientSecret = payoutClientSecret.value();

  if (!clientId || !clientSecret) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Cashfree payout credentials are not configured",
    );
  }

  const response = await axios.post(`${payoutAuthURL.value()}/authorize`, {}, {
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
    const response = await axios.post(`${payoutAuthURL.value()}/verifyToken`, {}, {
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

    const clientId = payoutClientId.value();
    const clientSecret = payoutClientSecret.value();
    const response = await axios.post(`${payoutBaseURL.value()}/beneficiary`, req.body, {
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

    const response = await axios.post(`${payoutBaseURL.value()}/requestTransfer`, data, {
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

// -----------------------------
// 🔀 Easy Split: Add / Create Vendor HTTP Function (Sandbox)
// -----------------------------
exports.easySplitAddVendor = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "https://lockify.co.in");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).send({ error: "Method Not Allowed" });
  }

  try {
    const uid = await verifyFirebaseToken(req);
    logger.log("easySplitAddVendor called by UID:", uid);
    logger.log("Request body:", req.body);

    const clientId = easySplitClientId.value() || payoutClientId.value();
    const clientSecret = easySplitClientSecret.value() || payoutClientSecret.value();

    const response = await axios.post(`${easySplitBaseURL.value()}/easy-split/vendors`, req.body, {
      headers: {
        'x-client-id': clientId,
        'x-client-secret': clientSecret,
        'x-api-version': '2025-01-01',
        'Content-Type': 'application/json',
      },
    });

    logger.log("easySplitAddVendor response:", response.data);
    return res.status(200).send(response.data);
  } catch (err) {
    const errorMsg = err.response?.data?.message || err.message || "Unknown error";
    logger.error("easySplitAddVendor error:", errorMsg);
    return res.status(500).send({ error: errorMsg, details: err.response?.data });
  }
});
