import { useEffect, useState, useCallback, useRef } from "react";
import { load } from "@cashfreepayments/cashfree-js";

import {
  CASHFREE_MODE,
  createOrderAndReturnPaymentSession,
  verifyPayment,
} from "../paymentOptions/src/payments";

const VERIFIED_ORDERS_STORAGE_KEY = "lockify_verified_orders";
const BUYER_PHONE_STORAGE_KEY = "lockify_buyer_phone";

function readVerifiedOrders() {
  try {
    const raw = sessionStorage.getItem(VERIFIED_ORDERS_STORAGE_KEY);
    if (!raw) return new Set();
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.filter((value) => typeof value === "string" && value));
  } catch {
    return new Set();
  }
}

function persistVerifiedOrders(verifiedOrdersSet) {
  try {
    sessionStorage.setItem(
      VERIFIED_ORDERS_STORAGE_KEY,
      JSON.stringify(Array.from(verifiedOrdersSet)),
    );
  } catch {
    // Ignore storage errors (private mode / blocked storage).
  }
}

function removeOrderIdFromQuery() {
  try {
    const url = new URL(window.location.href);
    if (!url.searchParams.has("order_id")) return;
    url.searchParams.delete("order_id");
    const next = `${url.pathname}${url.search}${url.hash}`;
    window.history.replaceState({}, "", next);
  } catch {
    // Ignore URL mutation errors.
  }
}

export function useCashfreePayment() {
  const [cashfree, setCashfree] = useState(null);
  const [hasAccess, setHasAccess] = useState(false);
  const [isVerifyingReturn, setIsVerifyingReturn] = useState(false);

  const [paymentSessionId, setPaymentSessionId] = useState(null);
  const [orderId, setOrderId] = useState(null);
  const [sessionContext, setSessionContext] = useState(null);
  const [isCreatingSession, setIsCreatingSession] = useState(false);

  const [showPopup, setShowPopup] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [method, setMethod] = useState(null);
  const verifiedOrdersRef = useRef(readVerifiedOrders());
  const verifyInFlightRef = useRef(new Map());
  const createSessionInFlightRef = useRef(new Map());

  // Initialize SDK once
  useEffect(() => {
    load({ mode: CASHFREE_MODE })
      .then(setCashfree)
      .catch((err) => {
        console.error("Cashfree init failed:", err);
        setCashfree(null);
      });
  }, []);

  const verify = useCallback(
    async (id = orderId) => {
      if (!id) return null;

      if (verifiedOrdersRef.current.has(id)) {
        return {
          paid: true,
          orderStatus: "PAID",
          orderId: id,
          cached: true,
        };
      }

      const inFlight = verifyInFlightRef.current.get(id);
      if (inFlight) {
        return inFlight;
      }

      const requestPromise = (async () => {
        const res = await verifyPayment(id);
        const isPaid =
          res?.paid === true ||
          String(res?.orderStatus || res?.order_status || "").toUpperCase() === "PAID";

        if (isPaid) {
          verifiedOrdersRef.current.add(id);
          persistVerifiedOrders(verifiedOrdersRef.current);
        }

        return res;
      })();

      verifyInFlightRef.current.set(id, requestPromise);
      try {
        return await requestPromise;
      } finally {
        verifyInFlightRef.current.delete(id);
      }
    },
    [orderId],
  );

  // Verify payment on redirect return
  useEffect(() => {
    let cancelled = false;
    const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    const params = new URLSearchParams(window.location.search);
    const returnedOrderId = params.get("order_id");
    if (!returnedOrderId) return;

    setIsVerifyingReturn(true);
    setOrderId(returnedOrderId);

    const verifyWithRetry = async () => {
      const maxAttempts = 5;
      const delayMs = 700;

      for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
        if (cancelled) return;
        const response = await verify(returnedOrderId);
        const isPaid =
          response?.paid === true ||
          String(response?.orderStatus || "").toUpperCase() === "PAID";

        if (isPaid) {
          setHasAccess(true);
          removeOrderIdFromQuery();
          setIsVerifyingReturn(false);
          return;
        }

        if (attempt < maxAttempts) {
          await wait(delayMs);
        }
      }

      setIsVerifyingReturn(false);
    };

    verifyWithRetry().catch((error) => {
      console.error("Redirect payment verification failed:", error);
      setIsVerifyingReturn(false);
    });

    return () => {
      cancelled = true;
      setIsVerifyingReturn(false);
    };
  }, [verify]);

  const ensurePaymentSession = useCallback(
    async (lockedMessageId, buyerPhone) => {
      if (!lockedMessageId || !buyerPhone) {
        throw new Error("Missing lockedMessageId or buyerPhone for payment.");
      }

      const normalizedPhone = String(buyerPhone).replace(/\D/g, "").slice(-10);
      const requestKey = `${lockedMessageId}_${normalizedPhone}`;
      const sameContext =
        sessionContext?.lockedMessageId === lockedMessageId &&
        sessionContext?.buyerPhone === normalizedPhone;

      if (sameContext && paymentSessionId && orderId) {
        return { paymentSessionId, orderId };
      }

      const inFlight = createSessionInFlightRef.current.get(requestKey);
      if (inFlight) {
        return inFlight;
      }

      const returnUrl = window.location.origin + window.location.pathname;
      const requestPromise = (async () => {
        setIsCreatingSession(true);
        sessionStorage.setItem(BUYER_PHONE_STORAGE_KEY, normalizedPhone);

        const { payment_session_id, order_id } =
          await createOrderAndReturnPaymentSession(
            returnUrl,
            lockedMessageId,
            normalizedPhone,
          );

        setPaymentSessionId(payment_session_id);
        setOrderId(order_id);
        setSessionContext({
          lockedMessageId,
          buyerPhone: normalizedPhone,
        });

        return {
          paymentSessionId: payment_session_id,
          orderId: order_id,
        };
      })();

      createSessionInFlightRef.current.set(requestKey, requestPromise);

      try {
        return await requestPromise;
      } finally {
        createSessionInFlightRef.current.delete(requestKey);
        if (createSessionInFlightRef.current.size === 0) {
          setIsCreatingSession(false);
        }
      }
    },
    [orderId, paymentSessionId, sessionContext],
  );

  // Open payment modal and select method; defer API call until pay action.
  const startPayment = (methodName, lockedMessageId, buyerPhone) => {
    if (!lockedMessageId || !buyerPhone) {
      console.error("Missing lockedMessageId or buyerPhone for payment.");
      return;
    }

    const normalizedPhone = String(buyerPhone).replace(/\D/g, "").slice(-10);
    const sameContext =
      sessionContext?.lockedMessageId === lockedMessageId &&
      sessionContext?.buyerPhone === normalizedPhone;

    if (!sameContext) {
      setPaymentSessionId(null);
      setOrderId(null);
      setSessionContext({
        lockedMessageId,
        buyerPhone: normalizedPhone,
      });
    }

    console.log(`[${new Date().toLocaleTimeString()}] 🎯 Selected: ${methodName}`);
    setMethod(methodName);
    setShowPopup(false);
    setShowModal(true);
  };

  return {
    cashfree,

    hasAccess,
    setHasAccess,
    isVerifyingReturn,

    method,
    showPopup,
    setShowPopup,

    showModal,
    setShowModal,

    paymentSessionId,
    orderId,
    isCreatingSession,

    startPayment,
    ensurePaymentSession,
    verifyPayment: verify,
  };
}
