const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const axios = require("axios");
const { finalizePaidOrder } = require("./finalizeOrder");

const CF_APP_KEY = defineString("CF_APP_KEY");
const CF_SECRET = defineString("CF_SECRET");
const CF_BASE_URL = defineString("CF_BASE_URL");

const DEFAULT_ALLOWED_ORIGIN = "https://lockify.co.in";

function isPaidStatus(status) {
  const normalized = String(status || "").toUpperCase();
  return normalized === "PAID" || normalized === "SUCCESS";
}

exports.verifyPayment = onRequest(async (req, res) => {
  const allowOrigin = DEFAULT_ALLOWED_ORIGIN;

  res.set("Access-Control-Allow-Origin", allowOrigin);
  res.set("Vary", "Origin");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Allow-Credentials", "true");
  res.set("Access-Control-Max-Age", "3600");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const orderId = req.body?.orderId || req.body?.order_id;
    if (!orderId) {
      return res.status(400).json({ error: "Missing orderId" });
    }

    const cashfreeResponse = await axios.get(
      `${CF_BASE_URL.value().replace(/\/$/, "")}/orders/${orderId}`,
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
    console.log("Cashfree response:", cashfreeResponse.data); // Debug log
    const order = cashfreeResponse.data || {};
    const paid = isPaidStatus(order.order_status);

    if (paid) {
      // Finalize order if paid
      await finalizePaidOrder({
        orderId: order.order_id || orderId,
        lockedMessageId: order.order_tags?.lockedMessageId,
        buyerPhone: order.customer_details?.customer_phone,
        amount: Number(order.order_amount || 0),
        cfPaymentId: order.cf_payment_id,
        source: "cashfree_verify_api",
      });
      // Order verified
      return res.status(200).send({
        orderStatus: order.order_status,
        paid: paid,
      });
    }

    return res.status(200).send({
      orderStatus: order.order_status || "UNKNOWN",
      paid: false,
    });
  } catch (error) {
    console.error("verifyPayment error:", error?.response?.data || error);
    return res.status(500).json({
      error: "Failed to verify payment",
      details: error?.response?.data || error?.message || "Unknown error",
    });
  }
});
