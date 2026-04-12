import axios from "axios";

const DEFAULT_CREATE_ORDER_URL = "https://createorder-eof7ol2ifa-uc.a.run.app";
const DEFAULT_VERIFY_PAYMENT_URL = "https://verifypayment-eof7ol2ifa-uc.a.run.app";


const rawMode = String(import.meta.env.VITE_CASHFREE_MODE || "sandbox").toLowerCase();
export const CASHFREE_MODE = rawMode === "production" ? "production" : "sandbox";

// ---------- Create order & get payment session ----------
const createOrderAndReturnPaymentSession = async (returnUrl, lockedMessageId, buyerPhone) => {
    try {
        const res = await axios.post(
            DEFAULT_CREATE_ORDER_URL,
            { returnUrl, lockedMessageId, buyerPhone },
        );
        const paymentSessionId = res.data?.paymentSessionId ?? res.data?.payment_session_id;
        const orderId = res.data?.orderId ?? res.data?.order_id;

        if (paymentSessionId && orderId) {
            return {
                payment_session_id: paymentSessionId,
                order_id: orderId,
            };
        }

        throw new Error("Invalid payment session response from server.");
    } catch (err) {
        console.error("Create session error:", err);
        throw err;
    }
};


// ---------- Verify payment ----------
const verifyPayment = async (order_id) => {
    try {
        const response = await axios.post(
            DEFAULT_VERIFY_PAYMENT_URL,
            { order_id },
        );
        const payload = response.data || {};
        console.log("Raw payment verification response:", payload);
        const orderStatus = payload.orderStatus ?? payload.order_status ?? "UNKNOWN";
        const paid = payload.paid === true || String(orderStatus).toUpperCase() === "PAID";

        const normalized = {
            ...payload,
            orderStatus,
            paid,
        };
        console.log("Payment verification response:", normalized);
        return normalized;
    } catch (err) {
        console.error("Payment verification failed:", err);
        return false;
    }
};




export { createOrderAndReturnPaymentSession, verifyPayment };
