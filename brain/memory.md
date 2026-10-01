# Lockify — Project Memory

## 1. Purpose

This file is the compact project memory for future implementation work.

It records stable decisions, current architecture, terminology, and constraints. It is not a substitute for source code or live configuration.

## 2. Product Identity

**Name:** Lockify

**Type:** Hybrid messaging + creator monetization platform.

**Core differentiator:** creators can distribute locked content through shareable links and monetize access.

## 3. Current Stack

### Frontend

- Flutter

### Backend

- Firebase Authentication
- Firestore
- Cloud Functions
- Firebase Storage
- Firebase Hosting

### Payments

- Cashfree

## 4. Core Domains

```text
Identity
Messaging
Locked Content
Payments
Purchases
Creator Earnings
KYC / Onboarding
Withdrawals
Media
Dashboards
```

## 5. Core Payment Architecture

```text
Buyer opens locked link
        ↓
Backend creates order
        ↓
Cashfree payment
        ↓
Cashfree webhook
        ↓
Server verification
        ↓
Idempotent finalization
        ↓
Purchase record
        ↓
Ledger / creator earning
        ↓
Unlock
```

## 6. Critical Invariants

These must remain true:

1. Client cannot declare a payment successful.
2. Client cannot directly credit creator earnings.
3. Client cannot directly unlock paid content.
4. Duplicate webhook delivery must not duplicate financial effects.
5. Every successful purchase must be traceable.
6. Protected media/content must not be publicly readable merely from its URL.
7. Financial history should be represented as transaction events.
8. Firestore and Storage rules are part of the security architecture.

## 7. Messaging

Supported:
- 1-to-1;
- groups;
- channels.

Supported content:
- text;
- media;
- documents;
- audio;
- video.

Firestore real-time streams are used for reactive messaging.

## 8. Creator Monetization

Creator onboarding/KYC is required for payout-related functionality according to the final Cashfree/product flow.

Creator earnings should have:
- earning events;
- transaction history;
- balance summary;
- withdrawal state.

## 9. Firebase Security State

Development-only allow-all rules must not be treated as production security.

The following pattern is known to be temporary/development-only and must be replaced:

```text
allow read, write: if request.time < timestamp.date(...);
```

Production authorization must be based on identity, ownership, membership, and business state.

## 10. Current Product Maturity

From project discussions:
- backend is substantially advanced;
- messaging includes 1-to-1, group, and channel concepts;
- multiple media types are supported;
- locked-content/payment flow is being completed;
- creator KYC/withdrawal behavior is an active design area;
- production security rules still require hardening/review.

Do not treat "feature implemented" and "production-ready" as equivalent.

## 11. Decision Log

### Decision: Firebase-first architecture

Keep Firebase as the primary backend while usage is early.

Reason:
- low operational complexity;
- integrated auth/database/storage/functions;
- real-time messaging;
- fast iteration.

### Decision: Server-side payment finalization

Payment success must be established by trusted backend verification/webhook processing.

### Decision: Idempotent financial processing

Payment retries are normal. The implementation must assume duplicate events.

### Decision: Ledger-oriented earnings

Do not make a mutable wallet balance the only financial source of truth.

### Decision: Separate messaging and monetization domains

They share identity and infrastructure but should not be coupled into one business transaction.

## 12. Open Questions

These must be resolved explicitly:

- Exact Cashfree split/payout model.
- Whether creator and platform are represented as separate Cashfree vendors/accounts in the selected integration.
- Guest purchase versus mandatory login.
- Refund and chargeback behavior.
- Creator fee/platform commission.
- Settlement timing.
- Withdrawal minimums and limits.
- KYC data retention.
- Content expiration/deletion.
- Moderation/reporting.
- Admin role model.
- Exact Firestore schema and security rules.

## 13. Change Discipline

When changing Lockify architecture:

1. Update this memory file if a stable architectural decision changes.
2. Update `brain/architecture.md` for system-level changes.
3. Update `brain/rules.md` for security/authorization changes.
4. Update `brain/roadmap.md` when implementation sequencing changes.
5. Update `brain/design.md` for user-flow/UI state changes.
6. Update `brain/prd.md` when product requirements change.

Do not silently introduce a new architecture through implementation code alone.
