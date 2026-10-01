const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const crypto = require("crypto");
const logger = require("firebase-functions/logger");

const { finalizePaidOrder } = require("./finalizeOrder");

const CF_SECRET = defineString("CF_SECRET");

// -----------------------------
// Helpers
// -----------------------------
function isSuccessStatus(status) {
  const normalized = String(status || "").toUpperCase();
  return normalized === "SUCCESS" || normalized === "PAID";
}

function verifyWebhookSignature(rawBody, timestamp, signature) {
  if (!rawBody || !timestamp || !signature) return false;

  const secret = CF_SECRET.value();
  if (!secret) {
    logger.error("CF_SECRET missing for webhook verification");
    return false;
  }

  const signedPayload = timestamp + rawBody;

  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(signedPayload)
    .digest("base64");

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expectedSignature),
      Buffer.from(signature),
    );
  } catch (err) {
    logger.error("Signature comparison failed", { error: err.message });
    return false;
  }
}

// -----------------------------
// Webhook Handler
// -----------------------------
exports.paymentSuccessWebhook = onRequest(async (req, res) => {
  const correlationId = `webhook-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;

  logger.info("Cashfree webhook received", { correlationId, method: req.method });

  if (req.method !== "POST") {
    logger.warn("Invalid method for webhook", { correlationId, method: req.method });
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    // ✅ IMPORTANT: raw body must be string
    const rawBody = req.rawBody?.toString("utf8");

    const timestamp = req.headers["x-webhook-timestamp"];
    const signature = req.headers["x-webhook-signature"];

    // ✅ STRICT validation (no bypass)
    if (!timestamp || !signature) {
      logger.warn("Missing webhook signature headers", { correlationId });
      return res.status(400).json({ error: "Missing signature headers" });
    }

    if (!verifyWebhookSignature(rawBody, timestamp, signature)) {
      logger.error("Invalid webhook signature", { correlationId });
      return res.status(401).json({ error: "Invalid signature" });
    }

    // -----------------------------
    // Parse payload
    // -----------------------------
    const payload = req.body;

    logger.info("Webhook event type", { correlationId, eventType: payload?.type });

    const eventData = payload?.data;
    if (!eventData) {
      logger.warn("Invalid payload: missing data", { correlationId });
      return res.status(400).json({ error: "Invalid payload: missing data" });
    }

    const payment = eventData?.payment || {};
    const order = eventData?.order;
    if (!order) {
      logger.warn("Invalid payload: missing order", { correlationId });
      return res.status(400).json({ error: "Invalid payload: missing order" });
    }

    const orderStatus = payment?.payment_status;
    logger.info("Payment status", { correlationId, orderStatus, isSuccess: isSuccessStatus(orderStatus) });

    // ✅ Only process success
    if (!isSuccessStatus(orderStatus)) {
      logger.info("Non-success status ignored", { correlationId, orderStatus });
      return res.status(200).json({
        ignored: true,
        reason: `status=${orderStatus || "UNKNOWN"}`,
      });
    }

    // -----------------------------
    // Extract fields
    // -----------------------------
    const orderId = order?.order_id;
    const lockedMessageId = order?.order_tags?.lockedMessageId;

    const customerDetails = eventData?.customer_details || order?.customer_details || {};

    const buyerPhone = customerDetails?.customer_phone;

    const amount = Number(order?.order_amount || 0);
    const cfPaymentId = payment?.cf_payment_id || null;

    // -----------------------------
    // Validate required fields
    // -----------------------------
    if (!orderId) {
      logger.error("Missing required fields in webhook", {
        correlationId,
        orderId,
        lockedMessageId,
        buyerPhone,
      });

      return res.status(400).json({
        error: "Missing required orderId",
        orderId,
        lockedMessageId,
        buyerPhone,
      });
    }

    if (!buyerPhone) {
      console.warn(`buyerPhone missing in webhook payload for order=${orderId}; falling back to stored order data.`);
    }

    console.log(`Processing SUCCESS payment: order=${orderId}, msg=${lockedMessageId || "fallback_from_order"}`,);

    // Idempotency: finalizePaidOrder runs in a transaction. Duplicate webhooks for the
    // same paid order skip writes once the order is PAID and the order-item doc exists
    // (see functions/payments/finalizeOrder.js — replay short-circuit + single increment
    // of purchasedCount only when the order-item doc is new).
    const result = await finalizePaidOrder({
      orderId,
      lockedMessageId,
      buyerPhone,
      amount,
      cfPaymentId,
      source: "cashfree_webhook", // need to check
    });

    // -----------------------------
    // Response
    // -----------------------------
    return res.status(200).json({
      received: true,
      orderId,
      orderItemId: result?.orderItemId || null,
      walletTransactionId: result?.walletTransactionId || null,
      purchaseId: result?.orderItemId || null,
      alreadyProcessed: result?.alreadyProcessed || false,
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
});
