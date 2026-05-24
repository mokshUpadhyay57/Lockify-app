---
name: lockify-payment-functions
description: Maintain, debug, or extend Lockify Firebase Functions payment flows. Use for changes in functions/, especially Cashfree create order, payment success webhook, verify payment fallback, finalize order, unlock content, wallet credits, order-items, purchases, payout beneficiary, and Firestore payment entitlement logic.
---

# Lockify Payment Functions

## Overview

Use this skill to work on Lockify backend payment code without weakening server-side trust, idempotency, or wallet/accounting behavior.

## Payment Flow

1. Client requests `createOrder`.
2. Backend creates an `orders/{orderId}` document with a pending/created state.
3. Cashfree returns a payment session.
4. Cashfree webhook and/or verify fallback confirms payment.
5. `finalizePaidOrder` writes entitlements and wallet records transactionally.
6. Client reads backend-created entitlement to unlock content.

Never make the Flutter client the source of truth for payment success or content unlock.

## Key Files

- `functions/index.js`: exports functions and payout helpers.
- `functions/config/firebase.js`: shared Admin SDK and Firestore setup.
- `functions/payments/createOrder.js`: HTTP order/session creation and Cashfree order API call.
- `functions/payments/success.js`: Cashfree success webhook.
- `functions/payments/verifyPayment.js`: verification fallback.
- `functions/payments/finalizeOrder.js`: transaction that writes paid order, order item, purchase, wallet, wallet transaction, and purchased count.

## Data Contracts

- `orders`: payment order status, amount, locked message, buyer phone/id, creator, Cashfree payment data.
- `order-items`: entitlement lookup keyed by buyer phone and locked message.
- `purchases`: purchase history keyed by buyer id/phone and locked message.
- `wallets`: creator balances and earning totals.
- `wallet_transactions`: earning records keyed by order.
- `lockedMessages`: content metadata and `purchasedCount`.

Confirm exact field names from the current file before editing; do not rely on memory.

## Implementation Rules

- Keep payment finalization idempotent. Replayed webhooks or verify calls must not double-credit wallets or double-increment `purchasedCount`.
- Prefer Firestore transactions for cross-document accounting and entitlement writes.
- Use deterministic document IDs for idempotency where the project already does: order item, purchase, and wallet transaction IDs.
- Validate method, required body fields, amount, message existence, return URL/domain, and Cashfree responses before writing final state.
- Use Firebase Functions params (`defineString`) for secrets and URLs; never hard-code credentials.
- Keep CORS narrow for browser-facing HTTP functions.
- Log enough context to debug payment failures, but do not log credentials or full secrets.
- Preserve Node 22 CommonJS style used by `functions/package.json`.
- If adding a new function export, wire it through `functions/index.js` and keep frontend call sites consistent.

## Common Risk Checks

- Does a retry create duplicate order items, purchases, wallet credits, or purchase count increments?
- Can a user change amount, message ID, buyer ID, or return URL to access another user's content?
- Does the function fail closed when Cashfree or Firestore returns unexpected data?
- Does the buyer identity resolve consistently from UID and normalized phone?
- Are wallet balance changes tied to a unique source/order ID?

## Validation

- Run `node --check` on every edited `.js` file.
- Run `npm --prefix functions run serve` when behavior needs emulator verification and the environment supports Firebase emulators.
- Report any emulator or network/auth blocker clearly.
