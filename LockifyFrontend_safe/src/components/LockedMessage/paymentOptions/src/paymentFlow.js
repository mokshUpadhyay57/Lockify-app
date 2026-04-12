import { CASHFREE_MODE } from "./payments";

export async function resolvePaymentSessionId({
  paymentSessionId,
  ensurePaymentSession,
  lockedMessageId,
  buyerPhone,
}) {
  const sessionData = await ensurePaymentSession(lockedMessageId, buyerPhone);
  return paymentSessionId || sessionData?.paymentSessionId || null;
}

export async function startCashfreeRedirectPayment({
  cashfree,
  paymentMethod,
  paymentSessionId,
  ensurePaymentSession,
  lockedMessageId,
  buyerPhone,
  extraOptions = {},
}) {
  if (!cashfree) {
    throw new Error("Cashfree SDK not ready");
  }
  if (!paymentMethod) {
    throw new Error("Payment method is not ready");
  }

  const resolvedSessionId = await resolvePaymentSessionId({
    paymentSessionId,
    ensurePaymentSession,
    lockedMessageId,
    buyerPhone,
  });

  if (!resolvedSessionId) {
    const sessionError = new Error("Could not create payment session.");
    sessionError.code = "SESSION_UNAVAILABLE";
    throw sessionError;
  }

  const result = await cashfree.pay({
    mode: CASHFREE_MODE,
    paymentMethod,
    paymentSessionId: resolvedSessionId,
    redirectTarget: "_self",
    ...extraOptions,
  });

  return {
    result,
    paymentSessionId: resolvedSessionId,
  };
}

