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
| `purchases` | Purchase records (deprecated) | Buyer/creator reads |
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
  password: string;               // WARNING: Should not be stored!
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
- `password` field should be removed (security risk)
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

**Purpose**: Purchase records (DEPRECATED — use order-items)

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
- Legacy collection, being replaced by `order-items`
- Supports both UID-based and phone-based purchases

---

### 11. order-items/{orderItemId}

**Purpose**: Order line items (replaces purchases)

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

## Indexes Required

### Compound Indexes (firestore.indexes.json)

```json
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "order-items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "buyerId", "order": "ASCENDING" },
        { "fieldPath": "purchasedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "wallet_transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "lockedMessages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "createdBy", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Caching Strategy

### Service-Level Caches

**AuthService**:
- `_cachedContacts` — 5-minute TTL for local contacts
- Cleared on logout

**GroupService / ChannelService**:
- `_memberCache: Map<roomId, Member[]>` — In-memory member lists
- No TTL (invalidated manually)

**ContactService**:
- Contact name resolution cache
- Backed by local device contacts

---

## Security Model

### Authentication Layers
```
Flutter Client (untrusted)
  ↓
Firebase Auth (identity boundary)
  ↓
Firestore Rules (document-level access)
  ↓
Cloud Functions (privileged operations)
  ↓
Cashfree (payment provider)
```

### Server-Only Operations

1. **Purchase finalization** (Cloud Functions)
2. **Wallet balance updates** (Cloud Functions)
3. **Withdrawal processing** (Cloud Functions)
4. **Transaction ledger writes** (Cloud Functions)
5. **Payment verification** (Webhook handlers)

### Client-Allowed Operations

1. Chat message creation
2. Group/channel creation
3. Locked message metadata creation (public fields only)
4. Profile updates (own profile)
5. Withdrawal request creation (not processing)

---

## Query Optimization Patterns

### 1. Reverse Index Pattern
**Problem**: Can't query `array-contains` with `orderBy`

**Solution**:
```typescript
// Instead of:
groups.where('participantUids', 'array-contains', uid).orderBy('lastMessageTimestamp')

// Use:
users/{uid}/memberships → [groupId1, groupId2, ...]
→ Batch fetch groups by IDs
→ Sort in memory
```

### 2. Dual Query Merge
**Problem**: Support both UID and phone lookups

**Solution**:
```typescript
// Merge two streams:
Stream 1: where('participantUids', 'array-contains', uid)
Stream 2: where('participantPhones', 'array-contains', phone)
→ StreamController merges + deduplicates by roomID
```

### 3. Denormalized Name Cache
**Problem**: Resolving phone → name on every message

**Solution**:
```typescript
// Store in room document:
participantNames: { [phone: string]: string }
// Update when name changes
```

### 4. Paginated Messages
**Problem**: Loading entire chat history

**Solution**:
```typescript
messages
  .orderBy('timestamp', descending: true)
  .limit(50)
  .startAfter(lastVisible) // For pagination
```

---

## Data Migration Notes

### Phone Normalization
- **Old**: Raw phone strings (`+919876543210`, `9876543210`)
- **New**: Last 10 digits (`9876543210`)
- **Migration**: Both formats supported via dual queries

### UID Migration
- **Old**: Phone-only identification
- **New**: Firebase UID as primary
- **Fields**: Added `uid` alongside `phone` in most collections
- **Compatibility**: Rules check both `buyerId` and `buyerPhone`

### Purchase Schema Evolution
```
purchases/{buyerId}_{messageId}  [DEPRECATED]
  ↓
order-items/{orderItemId}        [CURRENT]
```

---

## Backup and Recovery

### Cloud Functions Idempotency
All financial operations use idempotency keys:
```typescript
const idempotencyKey = `${orderId}_${lockedMessageId}`;
// Check if already processed before creating records
```

### Webhook Retry Safety
```typescript
1. Verify signature
2. Check if purchase exists (idempotency)
3. If exists → return success
4. If not → create transaction (atomic)
```

### Firestore Transaction Usage
```typescript
// Atomic purchase finalization:
await firestore.runTransaction(async (transaction) => {
  // 1. Create purchase record
  // 2. Create wallet transactions
  // 3. Update wallet balance
  // All or nothing
});
```

---

## Performance Considerations

### Document Size Limits
- Max document size: **1 MB**
- Large arrays (`participantUids`) monitored for growth
- Media stored in Firebase Storage, not Firestore

### Read Optimization
- Use `limit()` on all unbounded queries
- Stream only active conversations
- Cache member lists to avoid repeated subcollection reads

### Write Optimization
- Batch writes for multi-document updates
- Use `FieldValue.increment()` for counters
- Avoid contention on hot documents (e.g., wallet balance)

### Index Overhead
- Each index adds write cost
- Monitor index usage via Firebase Console
- Remove unused indexes

---

## Development Guidelines

### 1. Adding New Collections
- Define schema in this document
- Write Firestore security rules
- Add indexes if compound queries needed
- Update service layer
- Test access rules

### 2. Modifying Existing Schema
- Check for backward compatibility
- Support dual-read for migrations
- Update all query patterns
- Version sensitive changes

### 3. Financial Operations
- Always use Cloud Functions
- Implement idempotency
- Write to ledger before updating balance
- Log all operations

### 4. Real-Time Listeners
- Close streams on dispose
- Handle null/empty states
- Debounce rapid updates
- Use pagination

---

## Monitoring and Debugging

### Key Metrics to Track
- Read/Write operations per collection
- Query latency
- Failed transactions
- Webhook retry count
- Wallet balance reconciliation

### Debug Queries
```typescript
// Find users with balance discrepancy:
wallets.where('balance', '>', 0)

// Check recent failures:
wallet_transactions.where('status', '==', 'failed')
  .orderBy('timestamp', 'desc')
  .limit(10)
```

---

## Known Issues and Technical Debt

### Security Issues
1. Audit existing user documents for legacy password fields and remove any found; credentials belong in Firebase Authentication.
2. ⚠️ **Any authenticated user can read user documents** under the current Firestore rules. Separate public profile data from private metadata or narrow read access.

### Schema Issues
1. Dual UID/phone support adds complexity
2. `purchases` collection deprecated but still in use
3. Member arrays grow unbounded (need pagination strategy)

### Performance Issues
1. No limit on group/channel member count
2. Message pagination not implemented everywhere
3. Contact syncing can be slow with large contact lists

---

## Future Improvements

### 1. Sharding Hot Documents
For high-traffic creators, shard wallet balance across multiple documents to avoid contention.

### 2. Analytics Collections
Add dedicated analytics collections for:
- Daily active users
- Purchase funnel metrics
- Creator earnings trends

### 3. Search Indexing
Integrate Algolia or Typesense for:
- User search
- Content discovery
- Group/channel search

### 4. Archival Strategy
Move old messages to cold storage after 6 months to reduce costs.

---

## Related Documentation

- [App Flow](appflow.md) — User journey documentation
- [Architecture](architecture.md) — System architecture overview
- [Firestore Rules](../firestore.rules) — Security rules implementation
- [Firestore Indexes](../firestore.indexes.json) — Compound index definitions

---

**Last Updated**: 2026-10-01  
**Schema Version**: 1.0  
**Firestore Rules Version**: 2
