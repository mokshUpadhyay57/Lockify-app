# Lockify — Engineering & Security Rules

## 1. Core Rule

**Never trust the client for authorization, payment state, ownership, or financial state.**

## 2. Firestore Rules

### Must allow

A user may read/write only documents for which the application explicitly grants access.

Typical checks:
- authenticated user;
- `request.auth.uid`;
- document ownership;
- conversation membership;
- creator ownership;
- allowed state transition.

### Must deny

Users must not directly modify:
- verified payment state;
- purchase completion;
- creator wallet balance;
- ledger transactions;
- platform fees;
- withdrawal approval;
- KYC verification status;
- Cashfree/provider identifiers where server-owned.

## 3. Storage Rules

Storage authorization must be resource-specific.

Do not use development rules such as:

```text
allow read, write: if request.time < timestamp.date(...);
```

Such a rule is effectively a time-limited public authorization mechanism and is not production-grade.

Production rules should answer:

1. Who owns this object?
2. Who can read it?
3. Who can write it?
4. What resource does the path belong to?
5. Is the caller authenticated?
6. Is the caller a member/creator/authorized buyer?

## 4. Cloud Function Rules

Cloud Functions are the trusted boundary for:
- Cashfree API secrets;
- payment verification;
- purchase finalization;
- wallet/ledger mutations;
- privileged creator payout operations;
- sensitive server-to-server integrations.

Never ship provider secrets in Flutter.

## 5. Payment Rules

1. Payment initiation is not payment success.
2. Client redirect/success screen is not proof of payment.
3. Cashfree webhook must be verified.
4. Provider status must be validated server-side.
5. Finalization must be idempotent.
6. One successful order must not create multiple purchases.
7. One successful order must not create multiple earnings entries.

## 6. Ledger Rules

Every financial mutation should be represented by an immutable event where practical.

Examples:

```text
PURCHASE_EARNING
PLATFORM_FEE
REFUND
WITHDRAWAL
ADJUSTMENT
```

Do not edit historical financial records to "fix" a balance.

Prefer a compensating transaction.

## 7. Identity Rules

Use Firebase UID as the canonical user identity.

Do not trust:
- userId sent by the client;
- creatorId sent by the client;
- ownership flags sent by the client.

Derive identity from authenticated context.

## 8. Messaging Rules

### 1-to-1

Only conversation participants may access messages.

### Group

Only current members may access group messages according to product policy.

### Channel

Define explicit roles:
- owner/admin;
- member/subscriber;
- restricted/removed.

Do not rely on hidden UI controls for authorization.

## 9. Content Rules

A locked content URL identifies content; it does not itself grant access.

Protected content must be unlocked through a verified purchase/authorization state.

Public metadata may be separated from protected content.

## 10. API/Input Validation

Validate:
- IDs;
- prices;
- currency;
- ownership;
- message type;
- media metadata;
- pagination parameters;
- state transitions.

Never accept a client-supplied price as authoritative during payment finalization.

## 11. Idempotency Rules

Any operation triggered by:
- webhook;
- retry;
- network timeout;
- client retry;
- scheduled retry

must be safe to execute more than once.

Use a stable idempotency key.

## 12. Observability Rules

Log enough information to trace a payment without logging secrets.

Recommended correlation fields:
- internal operation ID;
- order ID;
- provider payment ID;
- user ID;
- creator ID;
- function execution ID;
- result/state.

Never log:
- payment secrets;
- authentication tokens;
- unnecessary KYC data;
- full sensitive financial information.

## 13. Data Access Rules

Follow least privilege.

A creator should not automatically be able to read:
- another creator's users;
- platform internal data;
- other creators' earnings;
- private KYC information.

A buyer should not automatically be able to read:
- creator financial data;
- internal payment verification details.

## 14. Development Rules

- No production secrets in source control.
- No allow-all Firestore/Storage rules in production.
- Test rules before deployment.
- Keep emulator tests for critical authorization/payment-adjacent data behavior.
- Prefer small, explicit schema changes.
- Avoid unnecessary dependencies.

## 15. Code Rules

Prefer:
- small services;
- explicit state transitions;
- typed models;
- pure validation logic;
- transactional writes;
- clear naming.

Avoid:
- giant Cloud Functions;
- duplicated business logic in Flutter and Functions;
- hidden side effects;
- mutable global financial state;
- deeply nested Firestore reads when a query can express the access pattern.

## 16. Change Rule

For every production change, answer:

```text
What data changes?
Who can read it?
Who can write it?
What happens on retry?
What happens on partial failure?
What happens if the client is malicious?
```
