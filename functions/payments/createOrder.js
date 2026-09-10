const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const axios = require("axios");
const crypto = require("crypto");
const { db, admin } = require("../config/firebase");

const CF_APP_KEY = defineString("CF_APP_KEY");
const CF_SECRET = defineString("CF_SECRET");
const CF_BASE_URL = defineString("CF_BASE_URL");

function generateOrderId(lockedMessageId, buyerPhone) {
  const uniqueSeed = `${lockedMessageId}_${buyerPhone}_${Date.now()}`;

  return "ORD_" + crypto
    .createHash("sha256")
    .update(uniqueSeed)
    .digest("hex")
    .slice(0, 12);
}

exports.createOrder = onRequest(async (req, res) => {

  // ✅ CORS headers
  res.set("Access-Control-Allow-Origin", "https://lockify.co.in");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // ✅ Handle preflight immediately
  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

  try {
    console.log("BODY:", req.body);
    console.log("HEADERS:", req.headers);

    const { lockedMessageId, buyerPhone, buyerId, returnUrl } = req.body;

    console.log("Received createOrder request:", {
      lockedMessageId,
      buyerPhone,
      buyerId,
      returnUrl,
    });

    // Input validation
    if (
      !lockedMessageId ||
      typeof lockedMessageId !== "string" ||
      !(buyerPhone) ||
      !returnUrl
    ) {
      return res.status(400).json({ error: "Invalid input" });
    }

    let parsedReturnUrl;
    try {
      parsedReturnUrl = new URL(returnUrl);
    } catch (_) {
      return res.status(400).json({ error: "Invalid returnUrl" });
    }

    const allowedDomains = ["lockify.co.in","localhost"];
    if (!allowedDomains.includes(parsedReturnUrl.hostname)) {
      return res.status(400).json({ error: "Unauthorized domain" });
    }

    // Fetch message
    const msgSnap = await db.collection("lockedMessages").doc(lockedMessageId).get();
    console.log("Message snapshot:", msgSnap.data());
    if (!msgSnap.exists) {
      return res.status(404).json({ error: "Message not found" });
    }

    const { unlockPrice, createdBy } = msgSnap.data();
    console.log("Unlock price from DB:", unlockPrice);
    if (!unlockPrice || unlockPrice <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const orderId = generateOrderId(lockedMessageId, buyerPhone);
    const returnUri = new URL(parsedReturnUrl.toString());
    returnUri.searchParams.set("order_id", orderId);

    console.log("Generated order: ", orderId);
    const orderRef = db.collection("orders").doc(orderId);

    let existingOrder = null;

    try {
      await orderRef.create({
        orderId,
        amount: unlockPrice,
        status: "PENDING",
        lockedMessageId,
        buyerPhone,
        buyerId: typeof buyerId === "string" && buyerId ? buyerId : null,
        creatorId: createdBy,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error("Order creation error:", err);
      if (err.code === 6 || err.code === "already-exists") {
        console.log("Order already exists, checking status...");
        const snap = await orderRef.get();
        existingOrder = snap.data();

        // reuse session
        if (existingOrder.paymentSessionId) {
          return res.status(200).json({
            orderId,
            paymentSessionId: existingOrder.paymentSessionId,
          });
        }

        // INIT lock handling
        const createdAt = existingOrder.createdAt?.toMillis?.() || 0;
        if (Date.now() - createdAt < 15000) {
          return res.status(409).json({ error: "Order processing" });
        }
      } else {
        throw err;
      }
    }

    const BASE_URL = CF_BASE_URL.value();
    console.log("Cashfree base URL:", BASE_URL);
    // Call Cashfree
    const cfResponse = await axios.post(
      `${BASE_URL}/orders`,
      {
        order_id: orderId,
        order_amount: unlockPrice,
        order_currency: "INR",
        customer_details: {
          customer_id: "CUST_" + buyerPhone,
          customer_phone: buyerPhone,
        },
        order_meta: {
          return_url: returnUri.toString(),
          notify_url: "https://paymentsuccesswebhook-eof7ol2ifa-uc.a.run.app",
        },
        order_tags: {
          lockedMessageId: lockedMessageId,
          buyerPhone: buyerPhone,
        },
      },
      {
        headers: {
          "x-client-id": CF_APP_KEY.value(),
          "x-client-secret": CF_SECRET.value(),
          "x-api-version": "2025-01-01",
          "Content-Type": "application/json",
        },
        timeout: 5000,
      },
    );

    console.log("Cashfree response:", cfResponse.data);

    // Save session immediately
    await orderRef.set({
      status: "CREATED",
      paymentSessionId: cfResponse.data.payment_session_id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log("Order created with session:", orderId, cfResponse.data.payment_session_id);

    return res.status(200).json({
      orderId,
      paymentSessionId: cfResponse.data.payment_session_id,
    });

  } catch (err) {
    console.error("CASHFREE ERROR:");
    console.error("status:", err?.response?.status);
    console.error("data:", err?.response?.data);
    console.error("message:", err.message); 
    return res.status(500).json({ error: "Internal error" });
  }
});

exports.createEasySplitOrder = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "https://lockify.co.in");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { lockedMessageId, buyerPhone, buyerId, returnUrl, orderSplits } = req.body;

    if (
      !lockedMessageId ||
      typeof lockedMessageId !== "string" ||
      !buyerPhone ||
      !returnUrl
    ) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const msgSnap = await db.collection("lockedMessages").doc(lockedMessageId).get();
    if (!msgSnap.exists) {
      return res.status(404).json({ error: "Message not found" });
    }

    const { unlockPrice, createdBy } = msgSnap.data();
    if (!unlockPrice || unlockPrice <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const orderId = generateOrderId(lockedMessageId, buyerPhone);
    const orderRef = db.collection("orders").doc(orderId);

    await orderRef.create({
      orderId,
      amount: unlockPrice,
      status: "PENDING",
      lockedMessageId,
      buyerPhone,
      buyerId: typeof buyerId === "string" && buyerId ? buyerId : null,
      creatorId: createdBy,
      isEasySplit: true,
      orderSplits: orderSplits || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const BASE_URL = CF_BASE_URL.value();
    const orderPayload = {
      order_id: orderId,
      order_amount: unlockPrice,
      order_currency: "INR",
      customer_details: {
        customer_id: "CUST_" + buyerPhone,
        customer_phone: buyerPhone,
      },
      order_meta: {
        return_url: returnUrl + `?order_id=${orderId}`,
        notify_url: "https://paymentsuccesswebhook-eof7ol2ifa-uc.a.run.app",
      },
      order_tags: {
        lockedMessageId: lockedMessageId,
        buyerPhone: buyerPhone,
      },
    };

    if (Array.isArray(orderSplits) && orderSplits.length > 0) {
      orderPayload.order_splits = orderSplits;
    }

    const cfResponse = await axios.post(
      `${BASE_URL}/orders`,
      orderPayload,
      {
        headers: {
          "x-client-id": CF_APP_KEY.value(),
          "x-client-secret": CF_SECRET.value(),
          "x-api-version": "2025-01-01",
          "Content-Type": "application/json",
        },
        timeout: 5000,
      },
    );

    await orderRef.set({
      status: "CREATED",
      paymentSessionId: cfResponse.data.payment_session_id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return res.status(200).json({
      orderId,
      paymentSessionId: cfResponse.data.payment_session_id,
    });
  } catch (err) {
    console.error("EASY SPLIT CREATE ORDER ERROR:", err?.response?.data || err.message);
    return res.status(500).json({ error: "Internal error" });
  }
});
