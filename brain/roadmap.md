# Lockify — Implementation Phases

## Phase 0 — Baseline and Hardening

Goal: establish a safe baseline before adding more features.

### Work

- [ ] Confirm Firebase project/environment separation.
- [x] Review Authentication configuration.
- [x] Replace development Firestore rules with production rules.
- [x] Replace development Storage rules with production rules.
- [x] Review Cloud Function permissions.
- [x] Confirm Cashfree secrets are server-side.
- [ ] Establish emulator/testing strategy.
- [x] Add structured logging/correlation IDs.
- [x] Define canonical Firestore collection names.
- [x] Document environment configuration.

### Exit criteria

A malicious client cannot directly change purchase, wallet, payout, or verification state.

---

## Phase 1 — Core Locked Content

Goal: complete the fundamental Lockify value proposition.

### Work

- [x] Creator creates locked content.
- [x] Locked content has stable public identifier.
- [x] Public preview is separated from protected content.
- [x] Shareable URL works.
- [ ] Buyer can open the content.
- [x] Backend validates content state.
- [x] Price/currency are server-authoritative.
- [ ] Expired/deleted/invalid content is handled.

### Exit criteria

A creator can create a locked message and a buyer can reach a valid purchase flow.

---

## Phase 2 — Cashfree Payment

Goal: make the purchase path production-safe.

### Work

- [x] Server-side order creation.
- [x] Cashfree checkout integration.
- [x] Webhook endpoint.
- [x] Webhook verification.
- [x] Payment status verification.
- [ ] Idempotency key.
- [x] Purchase record.
- [ ] Failed/cancelled payment states.
- [ ] Retry handling.
- [x] Payment reconciliation fields.

### Exit criteria

Repeated webhook delivery cannot duplicate a purchase.

---

## Phase 3 — Earnings and Creator Wallet

Goal: correctly account for creator earnings.

### Work

- [x] Financial ledger model.
- [x] Creator earning event.
- [ ] Platform fee event.
- [x] Atomic balance summary update.
- [x] Earnings dashboard.
- [x] Transaction history.
- [ ] Refund/reversal model.

### Exit criteria

Every completed purchase produces a traceable financial record.

---

## Phase 4 — Creator KYC and Payouts

Goal: allow eligible creators to receive money.

### Work

- [x] Creator onboarding UI.
- [x] Required identity/bank/tax information.
- [ ] Server-side onboarding state.
- [x] KYC verification state.
- [ ] Payout eligibility checks.
- [x] Withdrawal request.
- [x] Cashfree payout/split integration as applicable.
- [x] Withdrawal status tracking.
- [ ] Failed payout handling.

### Exit criteria

Creator payout state cannot be forged by the client.

---

## Phase 5 — Messaging

Goal: complete the communication layer.

### Work

- [x] 1-to-1 chat.
- [x] Groups.
- [x] Channels.
- [x] Text messages.
- [x] Media messages.
- [x] Documents.
- [ ] Audio.
- [x] Video.
- [x] Membership/role authorization.
- [ ] Pagination.
- [x] Real-time listeners.
- [x] Media upload/download authorization.

### Exit criteria

Users can communicate in all supported conversation types without cross-user data leakage.

---

## Phase 6 — Dashboards and Product UX

Goal: make the system operationally usable.

### Creator

- [x] Content dashboard.
- [x] Sales.
- [x] Earnings.
- [x] Transactions.
- [x] Withdrawal status.
- [x] KYC state.

### Buyer

- [x] Purchases.
- [x] Unlocked content.
- [ ] Payment status.

### Platform

- [ ] Payment reconciliation.
- [ ] Failed webhook visibility.
- [ ] Withdrawal visibility.
- [ ] User/content moderation controls.

---

## Phase 7 — Production Readiness

### Security

- [x] Firestore rules audited.
- [ ] Storage rules audited.
- [ ] Cloud Function permissions audited.
- [x] Secrets reviewed.
- [ ] Abuse/rate limits considered.
- [ ] Sensitive data exposure reviewed.

### Reliability

- [ ] Function retry behavior tested.
- [ ] Duplicate webhook tests.
- [ ] Payment interruption tests.
- [ ] Partial failure tests.
- [ ] Recovery/reconciliation procedure.

### Cost

- [ ] Firestore read/write profiling.
- [ ] Storage usage profiling.
- [ ] Function invocation profiling.
- [ ] Listener optimization.
- [ ] Media size limits.

### Launch criteria

- [ ] Critical payment path tested end-to-end.
- [ ] No known critical authorization issue.
- [ ] Monitoring available.
- [ ] Backup/recovery approach documented.
- [ ] Production rules deployed.

---

## Phase 8 — Scale and Optimization

Only after real usage exposes bottlenecks.

Possible work:
- denormalized read models;
- queue-based asynchronous processing;
- advanced analytics;
- caching;
- search;
- stronger abuse prevention;
- external data warehouse;
- service extraction if Firebase becomes the bottleneck.

Do not pre-build these without measured need.
