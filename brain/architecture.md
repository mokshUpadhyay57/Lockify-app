# Lockify — Architecture

## 1. Architecture Summary

Lockify uses a Flutter client with Firebase as the primary backend platform.

```text
Flutter App / Web Entry
        |
        +--------------------+
        |                    |
 Firebase Auth          Firestore
        |                    |
        |             Messaging / Metadata
        |             Purchases / Ledger
        |             Creator State
        |
        +------ Cloud Functions ------+
                    |
             Payment Boundary
                    |
                 Cashfree
                    |
              Webhooks / APIs
                    |
             Firestore Finalization
                    |
          Unlock + Financial Ledger
```

Firebase services in the current architecture:
- Authentication;
- Firestore;
- Cloud Functions;
- Storage;
- Hosting.

## 2. Architectural Principles

1. **The client is untrusted.**
2. **Payments are finalized only on the server.**
3. **Webhooks are retryable and therefore handlers must be idempotent.**
4. **Financial events are ledger-like records, not only balance mutations.**
5. **Firestore rules enforce access; UI checks are not security.**
6. **Storage authorization must match application authorization.**
7. **Messaging and payment systems remain logically separated.**
8. **Prefer atomic Firestore operations for state transitions.**

## 3. Components

### Flutter

Responsibilities:
- authentication UI;
- chat UI;
- locked-content UI;
- payment initiation;
- dashboards;
- creator onboarding;
- displaying server-derived state.

Flutter must not:
- decide whether a payment succeeded;
- directly credit creator earnings;
- directly unlock paid content;
- directly mutate privileged financial records.

### Firebase Authentication

Identity boundary for authenticated users.

User ID is the primary identity reference used throughout application data.

### Firestore

Primary operational database.

Suitable domains:
- users;
- conversations;
- messages;
- locked messages;
- purchases;
- creator earnings;
- ledger transactions;
- withdrawals;
- KYC/onboarding state;
- configuration.

### Cloud Functions

Trusted server-side boundary.

Responsibilities:
- create/validate payment orders;
- receive payment webhooks;
- verify payment state;
- perform idempotent purchase finalization;
- update financial state;
- enforce privileged operations;
- integrate with Cashfree.

### Firebase Storage

Stores user/creator media and files.

Access must be governed by Storage rules and/or signed/server-mediated access patterns as required.

### Firebase Hosting

Hosts the web/frontend entry points where applicable, including share/unlock pages or deployed frontend assets.

### Cashfree

External payment provider.

The integration boundary is:

```text
Lockify backend -> Cashfree order/payment
Cashfree -> Lockify webhook
Lockify backend -> verify
Lockify backend -> finalize
```

## 4. Firestore Data Model

A logical model:

```text
users/{userId}

users/{userId}/...
    creator profile / settings / onboarding state as needed

conversations/{conversationId}
conversations/{conversationId}/members/{userId}
conversations/{conversationId}/messages/{messageId}

lockedMessages/{lockedMessageId}

lockedMessages/{lockedMessageId}/...
    metadata / protected references / purchase-related data as required

purchases/{purchaseId}

ledgerTransactions/{transactionId}

creatorAccounts/{creatorId}
withdrawals/{withdrawalId}
```

The exact collection layout should follow actual query patterns rather than theoretical normalization.

## 5. Payment State Machine

```text
CREATED
   |
   v
ORDER_CREATED
   |
   v
PAYMENT_PENDING
   |
   +------> FAILED
   |
   +------> CANCELLED
   |
   v
PAYMENT_VERIFIED
   |
   v
FINALIZING
   |
   v
COMPLETED
```

A retry must be able to safely encounter an already completed state.

## 6. Idempotent Finalization

The finalization key should be based on a provider/order/transaction identifier that uniquely identifies the payment event.

Conceptually:

```text
if purchase/finalization already exists:
    return existing result

transaction:
    verify eligible payment
    create purchase if absent
    create financial ledger event if absent
    update summary balance
    mark unlock state
```

The system must not use:

```text
if client says paid -> unlock
```

It must use:

```text
provider state -> server verification -> atomic finalization
```

## 7. Financial Model

Prefer:

```text
ledgerTransactions
        |
        +--> creator earning
        +--> platform fee
        +--> refund/reversal
        +--> withdrawal
        +--> adjustment
```

A balance field can be maintained as a derived/optimized summary, but the ledger should preserve the financial event history.

## 8. Messaging Architecture

Firestore real-time listeners are used for:
- conversation updates;
- message streams;
- membership changes where needed.

Avoid broad listeners.

Prefer:

```text
conversation -> paginated messages
```

rather than loading a user's entire message history.

For groups/channels:
- membership is explicit;
- authorization derives from membership;
- message access is scoped to the conversation.

## 9. Media

Media metadata belongs in Firestore where queryable.

Binary objects belong in Firebase Storage.

Example:

```text
Firestore:
messageId
type = IMAGE
storagePath
senderId
createdAt
size
mimeType

Storage:
actual binary object
```

Do not put large binary content directly into Firestore.

## 10. Security Architecture

Security layers:

```text
Flutter
  |
  v
Firebase Auth identity
  |
  +--> Firestore Rules
  |
  +--> Storage Rules
  |
  +--> Cloud Functions
          |
          +--> Cashfree
          +--> privileged Firestore writes
```

Privileged financial fields should be server-owned.

Rules should prevent users from changing:
- purchase status;
- payment verification state;
- creator earnings;
- withdrawal approval;
- platform fees;
- KYC verification state.

## 11. Failure Handling

### Webhook duplicated

Expected behavior:
- detect existing finalization;
- return success/no-op;
- no second credit.

### Webhook delayed

Purchase remains pending until verified event arrives.

### Client closes after payment

Webhook/finalization must still complete independently.

### Function retries

All financial writes must remain idempotent.

### Cashfree reports failure

No unlock and no creator earning.

### Partial internal failure

Use transaction/batch boundaries so a financial state transition cannot silently produce only half of its required effects.

## 12. Scaling Strategy

At early scale:
- keep Firebase architecture;
- optimize query patterns;
- minimize unnecessary listeners;
- paginate messages;
- avoid duplicate reads;
- store media in Storage;
- use Cloud Functions only for privileged/backend work.

Scale pressure should first be measured through:
- Firestore reads/writes;
- function invocations;
- Storage bandwidth;
- document contention;
- webhook volume.

Do not infer a fixed MAU limit directly from a Firebase quota. User capacity depends on per-user activity patterns.

## 13. Architectural Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Client-controlled financial state | Critical | Backend-only writes + rules |
| Duplicate webhook | Critical | Idempotency key |
| Broad Firestore listeners | High | Scoped queries/pagination |
| Allow-all Storage rules | Critical | Path/user/resource authorization |
| Balance without ledger | High | Transaction records |
| Sensitive KYC in client-readable docs | Critical | Server-owned/private data |
| Large media in Firestore | High | Storage |
| Payment and chat tightly coupled | Medium | Separate domains |

## 14. Current Repository Implementation Map

This section maps the design above to the inspected Flutter and Firebase source. Source code is authoritative when it differs from this snapshot.

| Area | Main locations | Responsibility |
|---|---|---|
| Startup and app shell | `lib/main.dart`, `lib/home_screen.dart` | Initialize Firebase, route through the auth gate, and show the Chats, My Content, My Purchases, and Settings tabs. |
| Authentication | `lib/services/auth/`, `lib/screens/login/`, `lib/screens/register/` | Email, Google, and phone authentication; auth-state routing; profile and presence helpers. |
| Private chats | `lib/screens/products/chats/`, `lib/services/chats/` | Conversation lists and details, messages, polls, and contact-based identity resolution. |
| Groups and channels | `lib/screens/products/groups/`, `lib/screens/products/channels/`, `lib/services/group/`, `lib/services/channel/` | Creation, membership, moderation, details, and conversation screens. |
| Messaging and media | `lib/services/messaging_service.dart`, `lib/services/media_service.dart`, `lib/models/` | Message writes and streams, conversation metadata, media preparation/uploads, and message models. |
| Locked content and purchases | `lib/screens/products/locked_messages/`, `lib/screens/products/purchase/`, `lib/services/purchase_service.dart` | Paid content, purchase views, and protected media access. |
| Account and creator tools | `lib/screens/settings/`, `lib/services/wallet_service.dart`, `lib/services/admin/` | Profile, settings, earnings, wallet, verification, and creator management. |
| Shared UI and utilities | `lib/components/`, `lib/utils/` | Reusable widgets, colors, contacts, logging, navigation, and formatting helpers. |
| Backend and Firebase policy | `functions/`, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` | Payment/payout handlers, deployment configuration, access policies, and indexes. |

### Observed runtime boundaries

- `lib/main.dart` initializes Flutter and Firebase, configures Android debug App Check, and enables Firestore persistence. `AuthGate` listens to Firebase Auth and routes to login or `LockifyHomePage`.
- Screens commonly use `StreamBuilder` for live Firebase data and `FutureBuilder` for one-time reads. Feature services contain reusable operations, while some screens still access Firebase directly.
- `MessagingService` batches message writes with conversation metadata updates. Group and channel services also manage membership and reverse indexes.
- `MediaService` prepares and uploads media. Firestore and Storage rules define access to messages and locked content.
- `functions/index.js` exports payment and payout HTTP handlers. The client-to-function call site was not located during the source review; trace that integration before changing the payment journey.

### Repository snapshot follow-ups

- On 2026-10-24, `functions/index.js` imported `./payments/getUnlockedContent`, but `functions/payments/getUnlockedContent.js` was absent. Confirm whether it has been restored before running or deploying Functions.
- Android uses the debug App Check provider in `lib/main.dart`; verify production provider configuration before release builds.
- A Google Play Services broker log alone did not establish an app-level authentication failure. Diagnose with the actual Flutter/Firebase exception and device or emulator state.
