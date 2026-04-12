const { db, admin } = require("../config/firebase");

const COLLECTIONS = {
  users: "users",
  orders: "orders",
  lockedMessages: "lockedMessages",
  orderItems: "order-items",
  wallets: "wallets",
  walletTransactions: "wallet_transactions",
};

function normalizePhone(phone) {
  const digits = String(phone || "").replace(/\D/g, "");
  if (!digits) return "";
  return digits.length > 10 ? digits.slice(-10) : digits;
}

function buildResult({
  orderId,
  orderItemId,
  walletTransactionId,
  alreadyProcessed,
  buyerPhone,
  buyerId,
  lockedMessageId,
}) {
  return {
    orderId,
    orderItemId,
    walletTransactionId,
    alreadyProcessed,
    buyerPhone,
    buyerId: buyerId || null,
    lockedMessageId,
  };
}

async function findBuyerUidByPhone(normalizedPhone) {
  if (!normalizedPhone) return null;

  const snap = await db
    .collection(COLLECTIONS.users)
    .where("phone", "==", normalizedPhone)
    .limit(1)
    .get();

  if (snap.empty) return null;

  const userDoc = snap.docs[0];
  return userDoc.data()?.uid || userDoc.id || null;
}

function getOrderItemId(buyerPhone, lockedMessageId) {
  return `${buyerPhone}_${lockedMessageId}`;
}

function getWalletTxId(orderId) {
  return `order_${orderId}_creator_credit`;
}

async function resolveFinalizationContext(transaction, {
  orderId,
  lockedMessageId,
  buyerPhone,
  amount,
}) {
  const orderRef = db.collection(COLLECTIONS.orders).doc(orderId);
  const orderSnap = await transaction.get(orderRef);
  const orderData = orderSnap.exists ? orderSnap.data() || {} : {};

  if (!orderSnap.exists) {
    console.warn(
      `Order ${orderId} not found in Firestore; finalizing using webhook/verify payload fallback.`,
    );
  }

  const resolvedLockedMessageId = lockedMessageId || orderData.lockedMessageId;
  if (!resolvedLockedMessageId) {
    throw new Error(
      `lockedMessageId missing for order ${orderId} (and no fallback data available)`,
    );
  }

  const messageRef = db.collection(COLLECTIONS.lockedMessages).doc(resolvedLockedMessageId);
  const messageSnap = await transaction.get(messageRef);
  if (!messageSnap.exists) {
    throw new Error(`Locked message ${resolvedLockedMessageId} not found`);
  }

  const creatorId = messageSnap.data()?.createdBy || orderData.creatorId;
  if (!creatorId) {
    throw new Error(
      `createdBy missing on locked message ${resolvedLockedMessageId}`,
    );
  }

  const resolvedBuyerPhone =
    normalizePhone(buyerPhone) || normalizePhone(orderData.buyerPhone);
  if (!resolvedBuyerPhone) {
    throw new Error(`Unable to resolve buyer phone for order ${orderId}`);
  }

  const resolvedBuyerId = orderData.buyerId || await findBuyerUidByPhone(resolvedBuyerPhone);
  const numericAmount = Number(amount || orderData.amount || 0);
  if (numericAmount <= 0) {
    throw new Error(`Invalid paid amount for order ${orderId}: ${numericAmount}`);
  }

  const orderItemId = getOrderItemId(resolvedBuyerPhone, resolvedLockedMessageId);
  const orderItemRef = db.collection(COLLECTIONS.orderItems).doc(orderItemId);
  const orderItemSnap = await transaction.get(orderItemRef);

  const walletRef = db.collection(COLLECTIONS.wallets).doc(creatorId);
  const walletSnap = await transaction.get(walletRef);

  const walletTransactionId = getWalletTxId(orderId);
  const walletTxRef = db.collection(COLLECTIONS.walletTransactions).doc(walletTransactionId);
  const walletTxSnap = await transaction.get(walletTxRef);

  return {
    orderId,
    orderRef,
    orderData,
    orderWasPaid: String(orderData.status || "").toUpperCase() === "PAID",
    resolvedLockedMessageId,
    messageRef,
    creatorId,
    resolvedBuyerPhone,
    resolvedBuyerId,
    numericAmount,
    orderItemId,
    orderItemRef,
    isNewOrderItem: !orderItemSnap.exists,
    walletRef,
    walletSnap,
    walletTransactionId,
    walletTxRef,
    walletTxExists: walletTxSnap.exists,
  };
}

function isReplayAlreadyProcessed(context) {
  return !context.isNewOrderItem && context.orderWasPaid && context.walletTxExists;
}

function writeOrderAndEntitlement(transaction, context, { source, cfPaymentId }) {
  const now = admin.firestore.FieldValue.serverTimestamp();

  transaction.set(
    context.orderRef,
    {
      status: "PAID",
      amount: context.numericAmount,
      lockedMessageId: context.resolvedLockedMessageId,
      buyerPhone: context.resolvedBuyerPhone,
      buyerId: context.resolvedBuyerId || null,
      creatorId: context.creatorId,
      cfPaymentId: cfPaymentId || null,
      paidAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  transaction.set(
    context.orderItemRef,
    {
      lockedMessageId: context.resolvedLockedMessageId,
      buyerPhone: context.resolvedBuyerPhone,
      buyerId: context.resolvedBuyerId || null,
      orderId: context.orderId,
      pricePaid: context.numericAmount,
      creatorId: context.creatorId,
      purchasedAt: now,
      source: source || "payment",
    },
    { merge: true },
  );
}

function writeWalletEntries(transaction, context, { source, cfPaymentId }) {
  const now = admin.firestore.FieldValue.serverTimestamp();

  if (!context.walletTxExists) {
    transaction.set(
      context.walletRef,
      {
        userId: context.creatorId,
        availableBalance: admin.firestore.FieldValue.increment(context.numericAmount),
        pendingBalance: admin.firestore.FieldValue.increment(0),
        totalEarned: admin.firestore.FieldValue.increment(context.numericAmount),
        updatedAt: now,
        lastCreditAt: now,
        lastOrderId: context.orderId,
        walletVersion: 1,
      },
      { merge: true },
    );
  } else if (!context.walletSnap.exists) {
    transaction.set(
      context.walletRef,
      {
        userId: context.creatorId,
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
        updatedAt: now,
        walletVersion: 1,
      },
      { merge: true },
    );
  }

  transaction.set(
    context.walletTxRef,
    {
      transactionId: context.walletTransactionId,
      userId: context.creatorId,
      type: "CREDIT",
      category: "ORDER_EARNING",
      amount: context.numericAmount,
      currency: "INR",
      status: "SUCCESS",
      sourceType: "ORDER",
      sourceId: context.orderId,
      orderItemId: context.orderItemId,
      lockedMessageId: context.resolvedLockedMessageId,
      creatorId: context.creatorId,
      buyerId: context.resolvedBuyerId || null,
      buyerPhone: context.resolvedBuyerPhone,
      cfPaymentId: cfPaymentId || null,
      provider: "cashfree",
      createdAt: now,
      updatedAt: now,
      metadata: {
        source: source || "payment",
      },
    },
    { merge: true },
  );
}

function writeMessagePurchaseCount(transaction, context) {
  if (!context.isNewOrderItem) return;

  transaction.set(
    context.messageRef,
    {
      purchasedCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function finalizePaidOrder({
  orderId,
  lockedMessageId,
  buyerPhone,
  amount,
  cfPaymentId,
  source,
}) {
  if (!orderId) {
    throw new Error("orderId is required");
  }

  return db.runTransaction(async (transaction) => {
    const context = await resolveFinalizationContext(transaction, {
      orderId,
      lockedMessageId,
      buyerPhone,
      amount,
    });

    if (isReplayAlreadyProcessed(context)) {
      return buildResult({
        orderId: context.orderId,
        orderItemId: context.orderItemId,
        walletTransactionId: context.walletTransactionId,
        alreadyProcessed: true,
        buyerPhone: context.resolvedBuyerPhone,
        buyerId: context.resolvedBuyerId,
        lockedMessageId: context.resolvedLockedMessageId,
      });
    }

    writeOrderAndEntitlement(transaction, context, { source, cfPaymentId });
    writeWalletEntries(transaction, context, { source, cfPaymentId });
    writeMessagePurchaseCount(transaction, context);

    return buildResult({
      orderId: context.orderId,
      orderItemId: context.orderItemId,
      walletTransactionId: context.walletTransactionId,
      alreadyProcessed: false,
      buyerPhone: context.resolvedBuyerPhone,
      buyerId: context.resolvedBuyerId,
      lockedMessageId: context.resolvedLockedMessageId,
    });
  });
}

module.exports = {
  finalizePaidOrder,
  normalizePhone,
};

