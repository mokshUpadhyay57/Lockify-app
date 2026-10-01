const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const axios = require("axios");
const crypto = require("crypto");
const logger = require("firebase-functions/logger");
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
  // Generate correlation ID for this request
  const correlationId = `req-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;

  // ✅ CORS headers
  res.set("Access-Control-Allow-Origin", "https://lockify.co.in");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("X-Correlation-ID", correlationId);

  // ✅ Handle preflight immediately
  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

    if (req.method !== "POST") {
      logger.warn("Invalid method", { correlationId, method: req.method });
      return res.status(405).json({ error: "Method not allowed" });
    }

  try {
    logger.info("createOrder request received", {
      correlationId,
      body: req.body,
      headers: req.headers
    });

    const { lockedMessageId, buyerPhone, buyerId, returnUrl } = req.body;

    logger.info("Order details", {
      correlationId,
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
      logger.warn("Invalid input", { correlationId, lockedMessageId, buyerPhone, returnUrl });
      return res.status(400).json({ error: "Invalid input" });
    }

    let parsedReturnUrl;
    try {
      parsedReturnUrl = new URL(returnUrl);
    } catch (_) {
      logger.warn("Invalid returnUrl format", { correlationId, returnUrl });
      return res.status(400).json({ error: "Invalid returnUrl" });
    }

    const allowedDomains = ["lockify.co.in","localhost"];
    if (!allowedDomains.includes(parsedReturnUrl.hostname)) {
      logger.warn("Unauthorized domain", { correlationId, domain: parsedReturnUrl.hostname });
      return res.status(400).json({ error: "Unauthorized domain" });
    }

    // Fetch message
    const msgSnap = await db.collection("lockedMessages").doc(lockedMessageId).get();
    logger.debug("Message snapshot fetched", { correlationId, exists: msgSnap.exists });
    if (!msgSnap.exists) {
      logger.warn("Message not found", { correlationId, lockedMessageId });
      return res.status(404).json({ error: "Message not found" });
    }

    const { unlockPrice, createdBy } = msgSnap.data();
    logger.info("Unlock price retrieved", { correlationId, unlockPrice });
    if (!unlockPrice || unlockPrice <= 0) {
      logger.warn("Invalid amount", { correlationId, unlockPrice });
      return res.status(400).json({ error: "Invalid amount" });
    }

    const orderId = generateOrderId(lockedMessageId, buyerPhone);
    const returnUri = new URL(parsedReturnUrl.toString());
    returnUri.searchParams.set("order_id", orderId);

    logger.info("Order ID generated", { correlationId, orderId });
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
        correlationId,
      });
      logger.info("Order document created", { correlationId, orderId });
    } catch (err) {
      logger.error("Order creation error", { correlationId, error: err.message, code: err.code });
      if (err.code === 6 || err.code === "already-exists") {
        logger.info("Order already exists, checking status", { correlationId, orderId });
        const snap = await orderRef.get();
        existingOrder = snap.data();

        // reuse session
        if (existingOrder.paymentSessionId) {
          logger.info("Reusing existing payment session", {
            correlationId,
            orderId,
            sessionId: existingOrder.paymentSessionId
          });
          return res.status(200).json({
            orderId,
            paymentSessionId: existingOrder.paymentSessionId,
          });
        }

        // INIT lock handling
        const createdAt = existingOrder.createdAt?.toMillis?.() || 0;
        if (Date.now() - createdAt < 15000) {
          logger.warn("Order still processing", { correlationId, orderId });
          return res.status(409).json({ error: "Order processing" });
        }
      } else {
        throw err;
      }
    }

    const BASE_URL = CF_BASE_URL.value();
    logger.debug("Cashfree API URL", { correlationId, baseUrl: BASE_URL });
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
          correlationId: correlationId,
        },
      },
      {
        headers: {
          "x-client-id": CF_APP_KEY.value(),
          "x-client-secret": CF_SECRET.value(),
          "x-api-version": "2025-01-01",
          "x-request-id": correlationId,
          "Content-Type": "application/json",
        },
        timeout: 5000,
      },
    );

    logger.info("Cashfree order created", {
      correlationId,
      orderId,
      sessionId: cfResponse.data.payment_session_id
    });

    // Save session immediately
    await orderRef.set({
      status: "CREATED",
      paymentSessionId: cfResponse.data.payment_session_id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    logger.info("Order finalized with payment session", {
      correlationId,
      orderId,
      sessionId: cfResponse.data.payment_session_id
    });

    return res.status(200).json({
      orderId,
      paymentSessionId: cfResponse.data.payment_session_id,
    });

  } catch (err) {
    logger.error("Cashfree API error", {
      correlationId,
      status: err?.response?.status,
      data: err?.response?.data,
      message: err.message,
      stack: err.stack,
    });
    return res.status(500).json({ error: "Internal error" });
  }
});
