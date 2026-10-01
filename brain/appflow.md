# Lockify — App Flow Documentation

## 1. Application Entry Points

### 1.1 Main Entry
```
main.dart
    ↓
AuthGate (auth_gate.dart)
    ├── Not authenticated → LoginScreen
    └── Authenticated → LockifyHomePage
```

### 1.2 Authentication Flow
```
LoginScreen
    ├── Email/Password Sign In → Home
    ├── Google Sign In → Home
    └── Register (→ RegisterScreen)
        ├── Email/Password Sign Up
        ├── Email Verification
        └── Home

LoginWithNumber (Phone Auth)
    ├── Enter Phone Number
    ├── OTP Verification (OTPScreen)
    └── Home

Password Reset Flow
    └── PasswordResetScreen
```

---

## 2. Main Navigation (LockifyHomePage)

Bottom Navigation with 4 tabs:

| Tab Index | Label | Screen | Purpose |
|-----------|-------|--------|---------|
| 0 | Chats | ChatScreen | All messaging (private, groups, channels) |
| 1 | My Content | LockedMessageListScreen | Creator's locked messages |
| 2 | My Purchases | PurchasePage | Buyer's purchase history |
| 3 | Settings | SettingHomePage | Profile, wallet, earnings, settings |

---

## 3. Messaging Flows

### 3.1 Private Chat Flow
```
ChatScreen
    ├── Tab: Private Chats (default)
    ├── Tab: Groups
    ├── Tab: Channels
    └── FAB: Create new chat/group/channel

Private Chat Detail:
    ChatScreen → select contact → ChatDetailScreen
        ├── View messages (real-time stream)
        ├── Send text message
        ├── Send media (image, video, document, audio)
        └── Create/view polls
```

### 3.2 Group Flow
```
ChatScreen → Groups Tab
    ├── View all groups (reverse index via users/{uid}/memberships)
    └── Create Group → CreateGroupScreen
        ├── Set name, description, image
        ├── Configure: type, visibility, restrictions
        ├── Set subscription (paid/free)
        └── Select participants

Group Detail:
    GroupChatScreen
        ├── Messages stream
        ├── Group Info → GroupInfoScreen
        │   ├── Member list
        │   ├── Add members
        │   ├── Promote/demote admins
        │   ├── Leave group
        │   └── Delete group (owner only)
        └── Group Settings → GroupSettingScreen
```

### 3.3 Channel Flow
```
ChatScreen → Channels Tab
    ├── View all channels (reverse index)
    └── Create Channel → CreateChannelScreen
        ├── Set name, description, image
        ├── Configure: type, visibility, restrictions
        ├── Set subscription (paid/free)
        └── Select subscribers

Channel Detail:
    ChannelChatScreen
        ├── Messages stream (owner/admins can send)
        ├── Channel Info → ChannelInfoScreen
        │   ├── Subscriber list
        │   ├── Add subscribers
        │   ├── Manage admins
        │   ├── Leave channel
        │   └── Delete channel (owner only)
        └── Channel Settings → ChannelSettingScreen
```

---

## 4. Locked Content Flow

### 4.1 Creator Flow
```
LockedMessageListScreen
    ├── View all locked messages (creator's own)
    ├── Create New → CreateLockedMessageScreen
    │   ├── Set title/teaser
    │   ├── Upload preview media (image/video/document)
    │   ├── Set price
    │   ├── Set expiry (optional)
    │   └── Save locked content
    └── Edit → EditLockedMessageScreen

Locked Message Detail (Creator View):
    LockedMessageScreen
        ├── View public preview
        ├── View purchase count
        ├── Edit content
        ├── Copy share link
        └── Delete
```

### 4.2 Buyer Flow
```
Shared Link (locked-message/{uniqueCode})
    ↓
LockedMessageViewerScreen
    ├── View public preview
    │   ├── Teaser text
    │   ├── Creator info
    │   ├── Price
    │   └── Preview media (not protected content)
    ├── Purchase CTA
    └── [If purchased] → View full content

Purchase Flow:
    LockedMessageViewerScreen → PurchaseScreen
        ├── Order creation (backend)
        ├── Cashfree checkout
        ├── Payment verification (webhook)
        └── Content unlock
```

---

## 5. Settings & Profile Flow

```
SettingHomePage
    ├── Profile → ProfileScreen
    │   ├── View/edit profile
    │   ├── Profile photo
    │   └── ProfileIntro
    │
    ├── Lists → ListHomeScreen
    │   ├── Groups → GroupScreen → GroupSummaryScreen
    │   ├── Channels → ChannelScreen → ChannelSummaryScreen
    │   └── Locked Messages → LockedMessages → LockedMessagesSummaryScreen
    │
    ├── Wallet → WalletHomeScreen
    │   ├── Balance dashboard
    │   └── Transaction history
    │
    ├── Earnings → EarningHomeScreen
    │   ├── Earnings overview
    │   ├── ExpenditureScreen
    │   ├── AddBankDetailScreen
    │   └── WithdrawalHistoryScreen
    │
    ├── Super Thanks → SuperThanksScreen
    │   └── ReceivedGiftScreen
    │
    ├── Verification → ProfileVerificationScreen
    │   └── UploadScreen
    │
    ├── Settings → SettingsScreen
    │   ├── Account Privacy
    │   ├── Upload Invoice
    │   ├── FAQ → FAQScreen
    │   ├── WhatsApp Help → WhatsAppHelpScreen
    │   └── Sign Out → Signout
    │
    └── Dashboard → DashboardScreen (Analytics)
```

---

## 6. Purchase Flow (Detailed)

### 6.1 Order Creation
```
User clicks "Buy" on LockedMessageViewerScreen
    ↓
Frontend calls Cloud Function (createOrder)
    ↓
Backend:
    1. Validate locked message exists
    2. Check user hasn't already purchased
    3. Create Cashfree order
    4. Return order details to client
    ↓
Client receives order token
```

### 6.2 Payment Processing
```
Client redirects to Cashfree Checkout
    ↓
User completes payment
    ↓
Cashfree sends webhook to Cloud Function
    ↓
Backend verification:
    1. Verify webhook signature
    2. Verify payment status with Cashfree
    3. Idempotent check (has this order been processed?)
    4. Create purchase record
    5. Create ledger entries (creator earning + platform fee)
    6. Update creator wallet balance
    7. Mark content as unlocked for buyer
    ↓
Client polls or receives update
    ↓
Content unlocked
```

### 6.3 Purchase Record
```
purchases/{purchaseId} → created by backend
order-items/{orderItemId} → readable by buyer and creator
```

---

## 7. Wallet & Earnings Flow

### 7.1 Wallet View
```
WalletHomeScreen
    ├── Stream: wallets/{uid}
    │   └── Balance, total earnings, total withdrawals
    └── Stream: wallet_transactions
        └── Filtered by userId, ordered by timestamp
```

### 7.2 Earnings Dashboard
```
EarningHomeScreen
    ├── Available balance
    ├── Total earnings
    ├── Recent transactions
    └── Withdraw CTA → WithdrawalFlow

Withdrawal Flow:
    1. Check KYC status
    2. Check minimum balance
    3. Create withdrawal request
    4. Backend processes via Cashfree payout
    5. Update withdrawal status
```

---

## 8. Real-Time Listeners

### 8.1 Chat Rooms
```
ChatService.getPrivateChats()
    ├── Query by participantUids (UID match)
    └── Query by participantPhones (phone match)
        └── Merged via StreamController
```

### 8.2 Groups & Channels
```
Reverse Index Pattern:
    users/{uid}/memberships/{roomId}
        └── { type: 'group' | 'channel', joinedAt }

Query Flow:
    1. Read user's membership index
    2. Batch fetch room documents (chunked by 30)
    3. Merge and sort by lastMessageTimestamp
```

### 8.3 Messages
```
All conversation types use subcollection:
    {collection}/{roomId}/messages/{messageId}

Stream:
    .orderBy('timestamp', descending: true)
```

---

## 9. Media Handling

### 9.1 Upload Flow
```
1. User selects media
2. Compress if needed (thumbnails for images)
3. Upload to Firebase Storage
4. Get download URL
5. Create message with media reference
6. Batch: update room + create message
```

### 9.2 Download/View Flow
```
Storage rules enforce:
    - Only participants can access
    - Signed URLs or direct access via rules
```

---

## 10. State Management Patterns

### 10.1 Singleton Services
```dart
ChatService._internal() → factory constructor
AuthService._internal()
GroupService._internal()
ChannelService._internal()
WalletService._internal()
MessagingService._internal()
```

### 10.2 Caching Strategies
```
AuthService:
    - _cachedContacts (5-minute TTL)

GroupService/ChannelService:
    - _memberCache (Map<roomId, List<Member>>)

ContactService:
    - Contact caching for name resolution
```

### 10.3 Presence System
```
App lifecycle aware:
    - onResume → isOnline: true
    - onPause/Inactive/Detached → isOnline: false
    - Updates users/{uid}.isOnline and lastSeen
```

---

## 11. Navigation Summary

```
┌─────────────────────────────────────────────────────────────┐
│                        LockifyHomePage                       │
├─────────────┬─────────────┬─────────────┬───────────────────┤
│   Chats     │ My Content  │ Purchases   │     Settings      │
│  (Tab 0)    │   (Tab 1)   │   (Tab 2)   │      (Tab 3)      │
├─────────────┼─────────────┼─────────────┼───────────────────┤
│ ChatScreen  │ LockedMsg   │ PurchasePage│  SettingHomePage  │
│             │ ListScreen  │             │                   │
│ • Private   │             │ • Order     │ • Profile         │
│ • Groups    │ • Create    │   History   │ • Lists           │
│ • Channels  │ • Edit      │ • Unlock    │ • Wallet          │
│             │ • View      │   Status    │ • Earnings        │
└─────────────┴─────────────┴─────────────┴───────────────────┘
```

---

## 12. Key User Journeys

### Journey 1: Creator Creates Locked Content
```
Home → My Content (Tab 1) → FAB/Create → CreateLockedMessageScreen
    → Fill details → Upload preview → Set price → Save
    → Copy share link → Share externally
```

### Journey 2: Buyer Purchases Content
```
Receive link → Open in app/browser → LockedMessageViewerScreen
    → View preview → Click Buy → Cashfree checkout
    → Complete payment → Automatic verification → Content unlocked
    → View in My Purchases (Tab 2)
```

### Journey 3: Creator Checks Earnings
```
Home → Settings (Tab 3) → Earnings → EarningHomeScreen
    → View balance → View transactions → Request withdrawal
```

### Journey 4: User Starts Group Chat
```
Home → Chats (Tab 0) → Groups tab → FAB/Create → CreateGroupScreen
    → Configure group → Select participants → Create
    → GroupChatScreen → Send messages
```
