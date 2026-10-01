# Lockify — Product & System Design

## 1. Design Direction

Lockify should feel like a messaging product with monetization embedded into the content flow, not like a payment portal with a chat feature attached.

Primary interaction model:

```text
Create
  ↓
Lock
  ↓
Share
  ↓
Open
  ↓
Pay
  ↓
Unlock
```

Messaging remains a parallel core experience.

## 2. Information Architecture

### Main areas

```text
Home
├── Chats
├── Groups
├── Channels
├── Locked Content
├── Purchases
└── Profile

Creator
├── Content
├── Sales
├── Earnings
├── Transactions
├── KYC / Onboarding
└── Withdrawals
```

Exact navigation can vary by Flutter implementation, but product domains should remain recognizable.

## 3. Locked Content Screen

The locked-content screen should expose:

- creator identity;
- title/preview;
- available metadata;
- price;
- purchase CTA;
- payment state;
- unlock state.

Do not expose the protected content before authorization.

### State variants

```text
AVAILABLE
PAYMENT_PENDING
PAYMENT_SUCCESS_PROCESSING
UNLOCKED
PAYMENT_FAILED
EXPIRED
UNAVAILABLE
```

## 4. Payment UX

The client should communicate state clearly:

```text
Preparing payment
      ↓
Checkout
      ↓
Verifying payment
      ↓
Unlocking content
      ↓
Content unlocked
```

Avoid showing "payment successful" as the final business state until the backend confirms the purchase.

## 5. Creator Experience

Creator creation flow:

```text
Create content
   ↓
Choose content
   ↓
Set locked price
   ↓
Review
   ↓
Publish
   ↓
Copy/share link
```

Creator earnings flow:

```text
Earnings
   ↓
Available balance
   ↓
Transactions
   ↓
Withdraw
   ↓
Payout status
```

KYC/onboarding should be surfaced when it becomes necessary for earning/withdrawal rather than unnecessarily blocking unrelated app usage.

## 6. Messaging Design

### 1-to-1

```text
Conversation Header
Message List
Message Composer
Attachments
```

### Group

Add:
- group identity;
- member list;
- membership roles;
- group settings.

### Channel

Add:
- channel identity;
- publisher/admin controls;
- member/subscriber access.

## 7. Message Rendering

Use a typed message model.

Example:

```text
Message
├── id
├── senderId
├── type
├── text
├── mediaReference
├── metadata
├── createdAt
└── status
```

`type` should determine rendering rather than relying on ad-hoc field combinations.

## 8. Media UX

Upload states:

```text
Selected
  ↓
Uploading
  ↓
Processing
  ↓
Available
  ↓
Delivered
```

Failures must be recoverable without losing the entire message composition.

## 9. Design System Principles

- consistent spacing;
- predictable hierarchy;
- clear primary CTA;
- strong payment state visibility;
- minimal steps to unlock;
- accessible touch targets;
- loading/error/empty states for every network-driven screen.

## 10. Security-Aware UX

Do not make the UI imply security guarantees that the backend has not established.

Examples:
- "Payment verifying" rather than immediately "Unlocked";
- "Pending" when server state is pending;
- disabled withdrawal CTA until eligibility is verified;
- clear explanation when KYC is required.

## 11. Error Design

Every critical flow needs:
- loading;
- success;
- recoverable failure;
- permanent failure;
- retry;
- support/reference identifier where appropriate.

Payment errors should not tell users to retry blindly if the payment may already have succeeded. First reconcile/check backend state.

## 12. Empty States

Useful empty states:
- no chats;
- no purchases;
- no locked content;
- no earnings;
- no transactions;
- no withdrawals.

Each should explain the next meaningful action.

## 13. Performance Design

- paginate long message lists;
- lazy-load media;
- avoid loading entire conversation histories;
- cache safe metadata;
- avoid unnecessary Firestore listeners;
- use optimistic UI only where rollback is safe.

## 14. Responsive/Web Share Experience

The shared locked-content route should be optimized for direct entry.

Minimum path:

```text
URL
 ↓
Content preview
 ↓
Price
 ↓
Checkout
 ↓
Verification
 ↓
Unlock
```

Do not force unnecessary navigation through the full app before the user can understand what they are purchasing.
