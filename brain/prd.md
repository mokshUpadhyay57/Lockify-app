# Lockify — Product Requirements Document

## 1. Product

Lockify is a hybrid messaging and creator-monetization platform.

Creators can:
- communicate with users through 1-to-1 chats, groups, and channels;
- publish text, media, documents, audio, and video;
- create locked content;
- share a link to locked content;
- receive creator earnings from successful purchases.

Users can:
- open a shared locked-content link;
- preview the content that is intentionally exposed before purchase;
- complete payment through Cashfree;
- receive access after verified payment finalization;
- use normal messaging features.

The product is implemented with Flutter on the client and Firebase services on the backend. Cashfree is the payment provider and Cloud Functions provide the server-side payment/order/webhook boundary.

## 2. Product Goals

### Primary goals

1. Make creator-to-user paid content simple:
   `share link -> open -> order -> pay -> verify -> unlock`.
2. Keep payment finalization idempotent.
3. Prevent client-side manipulation of purchase, wallet, or unlock state.
4. Support real-time messaging without coupling messaging correctness to payment correctness.
5. Give creators visibility into content, purchases, earnings, and withdrawals.
6. Keep the initial architecture small enough to operate economically at early scale.

### Secondary goals

- Support guest entry to locked-content links where the product flow permits it.
- Support creator onboarding/KYC for payout requirements.
- Support future creator monetization features without redesigning the payment ledger.

## 3. Non-Goals

The initial product does not attempt to be:
- a full social network;
- a general-purpose payment wallet;
- a banking product;
- a marketplace with complex multi-party settlement beyond the required creator/platform split;
- a fully decentralized storage system.

## 4. Users and Roles

### Guest

A person who opens a shared locked-content URL without necessarily having an authenticated account.

Capabilities are intentionally limited.

### Authenticated user

Can use messaging and purchase content according to product permissions.

### Creator

An authenticated user who creates content and can receive eligible earnings.

### Platform/admin

Responsible for operational controls, payment reconciliation, moderation, KYC/withdrawal review, and platform configuration.

## 5. Core User Journeys

### 5.1 Locked-content purchase

1. Creator creates locked content.
2. Lockify stores the content metadata and protected content reference.
3. Creator shares the public/locked-content link.
4. User opens the link.
5. Backend validates the locked-content identifier and purchase state.
6. Backend creates a Cashfree order.
7. User completes payment.
8. Cashfree sends a webhook.
9. Backend verifies the payment/order state.
10. Backend finalizes the purchase exactly once.
11. Purchase record is written.
12. Creator/platform transaction records are written.
13. Creator wallet/earnings state is updated using a transaction-safe operation.
14. User receives unlock access.
15. Repeated webhook delivery does not duplicate the purchase or wallet credit.

### 5.2 Messaging

Supported conversation types:
- 1-to-1;
- groups;
- channels.

Supported message/content types include:
- text;
- images/media;
- documents;
- audio;
- video.

Messages are stored in Firestore and consumed through reactive streams.

### 5.3 Creator earnings

1. Creator completes the required onboarding/KYC flow.
2. Eligible purchases generate creator earnings.
3. Earnings are represented by transaction records rather than relying only on a mutable balance.
4. Available balance can be calculated from the ledger or maintained as a transactionally updated summary.
5. Withdrawal is allowed only when the creator satisfies payout requirements.
6. Cashfree payout/split behavior is handled server-side.

## 6. Functional Requirements

### Authentication

- Firebase Authentication is the identity boundary.
- Authenticated operations must validate the Firebase identity.
- Guest operations must not gain authenticated privileges.

### Locked messages

Each locked message/content item must have:
- stable identifier;
- creator identifier;
- public/shareable identifier;
- price;
- content metadata;
- protected content reference;
- status;
- timestamps;
- purchase/unlock relationship.

The protected content must not become publicly readable merely because the share URL is known.

### Payments

- Payment/order creation must happen through trusted backend code.
- Client-provided payment state must never be treated as final.
- Cashfree webhook handling must be server-side.
- Payment finalization must be idempotent.
- Duplicate webhooks/retries must be safe.
- A successful payment must not produce multiple creator credits.
- A failed/cancelled payment must not unlock paid content.

### Wallet and earnings

- Financial state must be auditable.
- A mutable balance alone is insufficient as the source of truth.
- Every earning/adjustment/withdrawal should have a transaction/ledger record.
- Balance updates must be atomic with the corresponding financial event.

### Messaging

- Users may create/read conversations only according to membership/authorization.
- Message writes must be authorized.
- Media access must follow conversation/content authorization.
- Real-time listeners should be scoped to the minimum required collection/query.

### KYC and payouts

- Creator payout onboarding is a separate concern from customer payment.
- Creator identity/bank/tax information must be protected.
- Sensitive KYC information must not be exposed to other users.
- Payout state changes must be server-authorized.

## 7. Non-Functional Requirements

### Security

- Client is untrusted.
- Firestore/Storage rules enforce authorization.
- Sensitive financial operations are backend-only.
- No development-only allow-all rules in production.

### Consistency

Payment finalization, purchase creation, and wallet/ledger updates must be designed for retries and duplicate events.

### Scalability

Use:
- targeted Firestore queries;
- pagination;
- subcollections where they match access patterns;
- transactions/batches for atomic state transitions;
- controlled media sizes;
- server-side processing for privileged operations.

### Cost

Early-stage architecture should remain within Firebase free/low-cost usage where practical, but quotas must be treated as quotas rather than guaranteed user counts.

## 8. Success Metrics

Initial product metrics:
- successful locked-content purchases;
- payment-to-unlock success rate;
- duplicate webhook/finalization rate;
- failed payment rate;
- creator onboarding completion;
- active creators;
- active buyers;
- message delivery/read activity;
- creator withdrawal success rate.

Operational metrics:
- Cloud Function failures;
- webhook retries;
- Firestore read/write volume;
- Storage usage/download volume;
- payment reconciliation mismatches.

## 9. Acceptance Criteria

A locked-content purchase is considered complete only when:
- Cashfree reports a verifiable successful payment;
- the backend accepts the event;
- exactly one purchase exists for the transaction/order;
- exactly one corresponding financial event is recorded;
- the buyer can access the purchased content;
- retries produce no duplicate financial effect.

## 10. Product Constraints and Open Decisions

These items need explicit product decisions before production launch:
- exact guest-purchase/authentication behavior;
- refund policy;
- chargeback handling;
- creator/platform fee calculation;
- payout timing/settlement rules;
- KYC provider/verification policy;
- moderation/reporting policy;
- retention/deletion policy for messages and media;
- exact admin capabilities.
