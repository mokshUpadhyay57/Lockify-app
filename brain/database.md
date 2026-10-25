# Lockify — Database Schema Documentation

## Overview

Lockify uses **Firebase Firestore** as its primary database with a denormalized, real-time architecture optimized for chat applications and content monetization.

**Database Type**: NoSQL Document Store (Firestore)  
**Authentication**: Firebase Authentication (Email/Password, Google, Phone)  
**Storage**: Firebase Storage (media files)  
**Backend**: Cloud Functions (Node.js)

---

## Architecture Principles

1. **Client is untrusted** — Financial operations are server-only
2. **Denormalization for performance** — Duplicate data to avoid joins
3. **Real-time streams** — Use Firestore listeners for live updates
4. **Reverse indexes** — Maintain membership indexes for efficient queries
5. **Idempotent operations** — Webhooks and financial transactions are retryable
6. **Ledger-based finances** — All transactions are append-only records
7. **Phone normalization** — Last 10 digits used for matching (legacy + UID)

---

## Collections Overview

| Collection | Purpose | Access Pattern |
|------------|---------|----------------|
| `users` | User profiles and metadata | UID-based, authenticated reads |
| `chat_rooms` | Private 1-on-1 conversations | Participant-based queries |
| `groups` | Group conversations | Membership index + batch fetch |
| `channels` | Broadcast channels | Membership index + batch fetch |
| `lockedMessages` | Monetized content metadata (public) | Public reads, creator writes |
| `lockedMessageContent` | Protected content (private) | Purchase-gated reads |
| `purchases` | Purchase/entitlement records referenced by access rules | Buyer/creator reads |
| `order-items` | Order line items | Buyer/creator reads |
| `wallets` | User wallet balances | Owner reads only |
| `wallet_transactions` | Financial ledger | Owner reads, server writes |
| `withdrawals` | Withdrawal requests | Owner reads/creates |
| `polls` | Standalone polls | Authenticated access |
| `verifications` | KYC verification data | Server-managed |
| `adminUser` | Admin records | Admin-only access |

---

## Detailed Schema

### 1. users/{userId}

**Purpose**: Core user profile and identity

**Structure**:
```typescript
{
  uid: string;                    // Firebase Auth UID (primary key)
  email: string;                  // Email address
  username: string;               // Unique username
  name: string;                   // Display name
  phone: string;                  // Normalized phone (last 10 digits)
  photoUrl?: string;              // Profile picture URL
  bio?: string;                   // User bio
  isVerified: boolean;            // Profile verification status
  isBanned: boolean;              // Account status
  isOnline?: boolean;             // Real-time presence
  lastSeen?: Timestamp;           // Last activity timestamp
  lastLogin: Timestamp;           // Last login time
  createdAt?: Timestamp;          // Account creation
}
```

**Access Rules**:
- Read: Any authenticated user (used for contact lookup)
- Write: Owner only

**Subcollections**:
- `users/{userId}/memberships/{roomId}` — Group/channel membership index
- `users/{userId}/withdrawals/{withdrawalId}` — Withdrawal requests

**Indexes**:
- Query by `phone` (contact matching)
- Query by `username` (profile lookup)

**Notes**:
- Phone numbers are normalized to last 10 digits for matching
- Authentication credentials belong in Firebase Authentication, not the profile document.
- Public profile data should be moved to separate collection

---

### 2. users/{userId}/memberships/{roomId}

**Purpose**: Reverse index for user's group/channel memberships

**Structure**:
```typescript
{
  roomId: string;                 // Group or channel ID
  type: 'group' | 'channel';      // Room type
  joinedAt: Timestamp;            // Membership timestamp
}
```

**Access Pattern**:
```
1. Query user's memberships collection
2. Batch fetch room documents (30 at a time)
3. Merge and sort by lastMessageTimestamp
```

**Why This Design**:
- Firestore doesn't support `array-contains` with sorting
- Avoids scanning all groups/channels
- Enables efficient "my rooms" queries

---

### 3. chat_rooms/{roomId}

**Purpose**: Private 1-on-1 conversations

**Structure**:
```typescript
{
  type: 'private';
  participantUids: string[];      // [uid1, uid2]
  participantPhones: string[];    // [phone1, phone2] (normalized)
  participantNames?: { [phone: string]: string }; // Name cache
  lastMessage?: string;           // Preview text
  lastSenderPhone?: string;       // Last sender
  lastMessageTimestamp?: Timestamp;
  createdAt: Timestamp;
  deletedBy?: string[];           // UIDs who deleted this chat
}
```

**Access Rules**:
- Read/Write: Participants only (checked via arrays)

**Query Pattern**:
```typescript
// Dual query merged via StreamController:
// 1. By UID
where('participantUids', 'array-contains', currentUserUid)

// 2. By Phone (legacy)
where('participantPhones', 'array-contains', normalizedPhone)
```

**Subcollections**:
- `chat_rooms/{roomId}/messages/{messageId}`
- `chat_rooms/{roomId}/polls/{pollId}`

**Notes**:
- Uses both UID and phone for backward compatibility
- `deletedBy` array tracks soft deletes per user

---

### 4. chat_rooms/{roomId}/messages/{messageId}

**Purpose**: Messages within private chats

**Structure**:
```typescript
{
  senderId?: string;              // Sender UID
  senderPhone: string;            // Normalized phone
  senderName?: string;            // Cached name
  text?: string;                  // Message text
  type: 'text' | 'image' | 'video' | 'audio' | 'document' | 'poll';
  timestamp: Timestamp;
  
  // Media fields (when type != 'text')
  mediaUrl?: string;              // Firebase Storage URL
  thumbnailBase64?: string;       // Compressed preview
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  
  // Poll reference (when type == 'poll')
  pollId?: string;
  
  // Status
  isRead?: boolean;
  readBy?: string[];              // UIDs who read this
  deletedBy?: string[];           // Soft delete per user
}
```

**Access Rules**:
- Read/Write: Participants of parent room only

**Query Pattern**:
```typescript
.orderBy('timestamp', descending: true)
.limit(50)  // Paginated
```

---

### 5. groups/{groupId}

**Purpose**: Group conversations with multiple participants

**Structure**:
```typescript
{
  type: 'group';
  name: string;
  description: string;
  imageUrl?: string;
  url: string;                    // Shareable group link
  
  // Membership
  participantUids: string[];
  participantPhones: string[];    // Normalized
  adminUids: string[];
  createdBy: string;              // Creator UID
  
  // Configuration
  groupType: 'Public' | 'Private';
  memberVisibility: 'Everyone' | 'Admins Only';
  restrictContentSaving: boolean;
  
  // Subscription
  isPaid: boolean;
  subscriptionPrice?: string;
  paymentPeriod?: string;
  
  // Activity
  lastMessage?: string;
  lastSenderPhone?: string;
  lastMessageTimestamp?: Timestamp;
  createdAt: Timestamp;
}
```

**Access Rules**:
- Create: Any authenticated user
- Read: Participants only
- Update/Delete: Participants (admin checks in app)

**Query Patterns**:
```typescript
// Find user's groups (inefficient, use membership index instead)
where('participantUids', 'array-contains', uid)
where('participantPhones', 'array-contains', phone)

// Public groups
where('groupType', '==', 'Public')
```

**Subcollections**:
- `groups/{groupId}/messages/{messageId}`
- `groups/{groupId}/members/{memberId}` — Member metadata
- `groups/{groupId}/polls/{pollId}`

---

### 6. groups/{groupId}/members/{memberId}

**Purpose**: Extended member metadata within a group

**Structure**:
```typescript
{
  uid?: string;
  phone: string;                  // Normalized
  name: string;
  role: 'admin' | 'member';
  joinedAt: Timestamp;
}
```

**Access Rules**:
- Read/Write: Group participants only

**Notes**:
- Redundant with `participantUids` array but allows richer metadata
- Used for member list display

---

### 7. channels/{channelId}

**Purpose**: Broadcast channels (one-way communication)

**Structure**:
```typescript
{
  type: 'channel';
  name: string;
  description: string;
  imageUrl?: string;
  url: string;                    // Shareable channel link
  
  // Membership (subscribers)
  participantUids: string[];
  participantPhones: string[];
  adminUids: string[];            // Can post messages
  createdBy: string;
  
  // Configuration
  groupType: 'Public' | 'Private';
  memberVisibility: 'Everyone' | 'Admins Only';
  restrictContentSaving: boolean;
  
  // Subscription
  isPaid: boolean;
  subscriptionPrice?: string;
  paymentPeriod?: string;
  
  // Activity
  lastMessage?: string;
  lastSenderPhone?: string;
  lastMessageTimestamp?: Timestamp;
  createdAt: Timestamp;
}
```

**Access Rules**:
- Create: Any authenticated user
- Read: Participants only
- Post messages: Admins/owner only

**Subcollections**:
- `channels/{channelId}/messages/{messageId}`
- `channels/{channelId}/members/{memberId}`
- `channels/{channelId}/polls/{pollId}`

**Differences from Groups**:
- Only admins can post messages
- Subscribers are read-only participants

---

### 8. lockedMessages/{messageId}

**Purpose**: Public metadata for monetized content

**Structure** (PUBLIC FIELDS ONLY):
```typescript
{
  // Identity
  uniqueCode: string;             // Short shareable code
  createdBy: string;              // Creator UID
  
  // Public preview
  teaserText: string;
  unlockPrice: number;            // In currency units
  
  // Creator info (denormalized)
  creatorName: string;
  creatorUsername: string;
  creatorPhotoUrl?: string;
  
  // Preview media (NOT protected content)
  previewImageUrl?: string;
  previewVideoUrl?: string;
  previewDocumentUrl?: string;
  
  // Metadata
  purchasedCount: number;         // Number of purchases
  isPublic: boolean;
  expireMessage?: string;
  expiryTime?: Timestamp;
  createdAt: Timestamp;
  updatedAt?: Timestamp;
}
```

**Access Rules**:
- Read: Anyone (if only public fields), creator, or purchasers
- Create/Update: Creator only (public fields only)
- Delete: Creator only

**Security**:
- Protected content stored in separate collection
- Firestore rules validate only public fields are written

**Query Patterns**:
```typescript
// Creator's locked messages
where('createdBy', '==', creatorUid)
.orderBy('createdAt', descending: true)

// Lookup by unique code
where('uniqueCode', '==', code)
```

---

### 9. lockedMessageContent/{messageId}

**Purpose**: Protected content (purchase-gated)

**Structure**:
```typescript
{
  // Protected content
  contentText?: string;
  contentImageUrl?: string;
  contentVideoUrl?: string;
  contentDocumentUrl?: string;
  
  // Metadata
  updatedAt?: Timestamp;
}
```

**Access Rules**:
- Get: Creator OR purchasers only
- List: Denied (prevents enumeration)
- Create/Update: Creator only
- Delete: Creator only

**Verification**:
```typescript
// Purchase check
exists(/databases/$(database)/documents/purchases/$(uid_messageId))
```

---

### 10. purchases/{purchaseId}

**Purpose**: Purchase/entitlement records used by access checks alongside order line records.

**Document ID Format**: `{buyerId}_{lockedMessageId}`

**Structure**:
```typescript
{
  buyerId?: string;               // Buyer UID (new model)
  buyerPhone?: string;            // Legacy phone-only purchases
  lockedMessageId: string;
  purchasedAt: Timestamp;
  amount: number;
  status: 'completed';
}
```

**Access Rules**:
- Read: Owner (by buyerId or buyerPhone match)
- Write: Server only (via Cloud Functions)

**Notes**:
- Supports UID-based and legacy phone-based purchase ownership.

---

### 11. order-items/{orderItemId}

**Purpose**: Purchase line items associated with an order.

**Structure**:
```typescript
{
  // Order reference
  orderId: string;
  orderItemId: string;
  
  // Parties
  buyerId: string;                // Buyer UID
  creatorId: string;              // Creator UID
  
  // Item
  lockedMessageId: string;
  itemType: 'locked_message';
  
  // Pricing
  amount: number;
  currency: 'INR';
  
  // Status
  status: 'completed' | 'pending' | 'failed';
  purchasedAt: Timestamp;
  
  // Payment
  paymentMethod?: string;
  transactionId?: string;
}
```

**Access Rules**:
- Read: Buyer OR creator
- Write: Server only

**Query Patterns**:
```typescript
// Buyer's purchases
where('buyerId', '==', currentUid)
.orderBy('purchasedAt', descending: true)
.limit(20)

// Creator's sales
where('creatorId', '==', currentUid)
.orderBy('purchasedAt', descending: true)
```

---

### 12. wallets/{userId}

**Purpose**: User wallet balance (derived state)

**Structure**:
```typescript
{
  userId: string;
  balance: number;                // Available balance
  totalEarnings: number;          // Lifetime earnings
  totalWithdrawals: number;       // Lifetime withdrawals
  currency: 'INR';
  updatedAt: Timestamp;
}
```

**Access Rules**:
- Read: Owner only
- Write: Server only (Cloud Functions)

**Notes**:
- Balance is derived from `wallet_transactions` ledger
- Updated atomically with transactions

---

### 13. wallet_transactions/{transactionId}

**Purpose**: Financial ledger (append-only)

**Structure**:
```typescript
{
  transactionId: string;
  userId: string;                 // Transaction owner
  
  // Transaction details
  type: 'earning' | 'platform_fee' | 'withdrawal' | 'refund' | 'adjustment';
  amount: number;                 // Positive for credit, negative for debit
  currency: 'INR';
  
  // References
  orderId?: string;
  orderItemId?: string;
  lockedMessageId?: string;
  withdrawalId?: string;
  
  // Status
  status: 'completed' | 'pending' | 'failed';
  timestamp: Timestamp;
  
  // Metadata
  description?: string;
  metadata?: { [key: string]: any };
}
```

**Access Rules**:
- Read: Owner only
- Write: Server only

**Query Patterns**:
```typescript
// User's transaction history
where('userId', '==', uid)
.orderBy('timestamp', descending: true)

// Recent earnings
where('userId', '==', uid)
where('type', '==', 'earning')
.orderBy('timestamp', descending: true)
```

**Financial Flow**:
```
Purchase → Create transaction records:
  1. Creator earning (+80% to creator)
  2. Platform fee (+20% to platform)
  3. Update wallet.balance
```

---

### 14. withdrawals/{withdrawalId}

**Purpose**: Withdrawal requests

**Structure**:
```typescript
{
  withdrawalId: string;
  uid: string;                    // User UID
  
  // Amount
  amount: number;
  currency: 'INR';
  
  // Bank details
  accountNumber: string;
  ifscCode: string;
  accountHolderName: string;
  
  // Status
  status: 'pending' | 'processing' | 'completed' | 'failed';
  requestedAt: Timestamp;
  processedAt?: Timestamp;
  
  // Processing
  transferId?: string;            // Cashfree transfer ID
  failureReason?: string;
}
```

**Access Rules**:
- Read: Owner only
- Create: Owner only
- Update/Delete: Server only

**Subcollection Duplicate**:
- Also stored at `users/{userId}/withdrawals/{withdrawalId}`

**Query Patterns**:
```typescript
// User's withdrawal history
where('uid', '==', currentUid)
.orderBy('requestedAt', descending: true)

// Pending withdrawals (admin)
where('status', '==', 'pending')
.orderBy('requestedAt')
```

---

### 15. polls/{pollId}

**Purpose**: Standalone polls (can be linked in messages)

**Structure**:
```typescript
{
  pollId: string;
  question: string;
  options: string[];              // Array of option texts
  votes: {                        // Map of option index to voter UIDs
    [optionIndex: string]: string[];
  };
  createdBy: string;              // Creator UID
  createdAt: Timestamp;
  expiresAt?: Timestamp;
  
  // Settings
  allowMultipleVotes: boolean;
  isAnonymous: boolean;
}
```

**Access Rules**:
- Read/Create/Update: Authenticated users

**Notes**:
- Can be embedded in messages via `pollId` reference
- Also appears as subcollection in rooms for context-specific polls

---

### 16. verifications/{verificationId}

**Purpose**: Profile/creator verification requests

**Structure**:
```typescript
{
  userId: string;
  documentType: 'aadhar' | 'pan' | 'passport' | 'driving_license';
  documentUrl: string;            // Firebase Storage URL
  status: 'pending' | 'approved' | 'rejected';
  submittedAt: Timestamp;
  reviewedAt?: Timestamp;
  reviewedBy?: string;            // Admin UID
  rejectionReason?: string;
}
```

**Access Rules**:
- Write: Server/admin only
- Read: Owner and admin

---

## Data Relationships

### User → Conversations
```
users/{uid}
  ↓
users/{uid}/memberships/{roomId} [index]
  ↓
groups/{roomId} OR channels/{roomId}
```

### Chat Messages
```
chat_rooms/{roomId}
  ├── messages/{messageId}
  └── polls/{pollId}

groups/{groupId}
  ├── messages/{messageId}
  ├── members/{memberId}
  └── polls/{pollId}

channels/{channelId}
  ├── messages/{messageId}
  ├── members/{memberId}
  └── polls/{pollId}
```

### Locked Content → Purchases
```
lockedMessages/{messageId} [public metadata]
  ↓
lockedMessageContent/{messageId} [protected content]
  ↓
purchases/{buyerId}_{messageId} [access record]
  ↓
order-items/{orderItemId} [transaction record]
```

### Financial Flow
```
order-items/{orderItemId}
  ↓
wallet_transactions/{transactionId} [ledger entries]
  ↓
wallets/{userId} [balance summary]
  ↓
withdrawals/{withdrawalId} [payout requests]
```

---

## Relationships and Query Patterns

- **Room membership:** `users/{uid}/memberships/{roomId}` indexes a user’s group/channel memberships; room documents also retain participant fields for legacy and direct queries.
- **Messages:** chats, groups, and channels store messages under their parent document. Query recent messages by timestamp, paginate, and close listeners when screens dispose.
- **Locked content:** `lockedMessages` stores shareable metadata; `lockedMessageContent` stores protected fields. Purchase access checks currently reference `purchases`; `order-items` stores order-line records. Keep both paths in mind during migrations.
- **Financial records:** `wallet_transactions` is the event history; `wallets` is a derived balance summary. Withdrawals link to the creator account.
- **Identity:** UID is the primary identity; phone-based fields remain for legacy lookup. Follow existing phone normalization and dual-query behavior until migration is complete.
- Denormalized names and membership indexes reduce reads, but every duplicated field needs a consistent update path.

## Indexes

`firestore.indexes.json` is the source of truth for deployed index definitions. Check it when changing a query; do not maintain a second copy of the index JSON here.

## Security Boundaries

`firestore.rules` and `storage.rules` define actual access. This document describes data shape, not authorization. Keep payment verification, purchase finalization, wallet/ledger writes, and payout processing server-side. Never store authentication credentials in user documents; use Firebase Authentication.

## Operational Constraints

- Firestore documents are limited to 1 MiB; keep media binaries in Firebase Storage.
- Bound reads and listeners, paginate message history, and monitor hot financial documents.
- Financial updates must be atomic and retry-safe; see [Architecture](architecture.md) and [Engineering & Security Rules](rules.md).

## Known Data Constraints

- Current Firestore rules allow any authenticated user to read `users/{userId}` for existing lookup flows. Recheck those flows before narrowing access; prefer separating public profile fields from private account data.
- Firestore and Storage rules use `purchases` for paid-content access. Do not remove or rename it until rules, backend writes, and stored records have a verified migration.
- Membership is represented both by room participant fields and per-user membership documents. Keep both consistent through existing service paths.
- The schema includes legacy phone identifiers alongside UIDs. Preserve compatibility deliberately and remove it only through a tested migration.

## Schema Change Checklist

When changing a collection, update this reference, the relevant client/service and Cloud Function code, security rules, and indexes. Add tests for access and financial behavior where applicable. Verify the live schema against source before treating this document as current.

## Related Documentation

- [App Flow](appflow.md)
- [Architecture](architecture.md)
- [Engineering & Security Rules](rules.md)
- [Firestore Rules](../firestore.rules)
- [Storage Rules](../storage.rules)
- [Firestore Indexes](../firestore.indexes.json)