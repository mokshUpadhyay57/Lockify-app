# Lockify — Environment Configuration

## Overview

This document describes the environment setup, secrets management, and deployment configuration for Lockify.

---

## Firebase Project

**Project ID:** `zipind-57`

**Environment:** Single production project (no dev/staging separation currently)

**Warning:** Consider creating separate Firebase projects for development, staging, and production to isolate data and prevent accidental changes to production.

---

## Authentication Configuration

### Enabled Providers

1. **Email/Password** — Primary authentication method
2. **Google Sign-In** — OAuth provider for social login
3. **Phone Authentication** — For phone number-based login/verification

### Configuration Files

- **Android:** `android/app/google-services.json`
- **iOS:** `ios/Runner/GoogleService-Info.plist`
- **Flutter:** `lib/firebase_options.dart`

### Auth Service Features

- User registration with email, username, name, and phone
- Email/password sign-in
- Google OAuth sign-in
- Password reset
- Phone number normalization (last 10 digits)
- Contact-based name resolution

---

## Cloud Functions

### Runtime

- **Node.js version:** 22
- **Region:** Default (check Firebase console for deployed region)
- **Memory:** 256 MiB (via `setGlobalOptions`)
- **Timeout:** 10 seconds
- **Concurrency:** 10
- **Max Instances:** 1

### Deployed Functions

| Function | Type | Purpose |
|----------|------|---------|
| `createOrder` | onRequest (HTTP) | Server-side Cashfree order creation |
| `paymentSuccessWebhook` | onRequest (HTTP) | Cashfree payment webhook handler |
| `verifyPayment` | onRequest (HTTP) | Payment status verification |
| `addBeneficiary` | onRequest (HTTP) | Add payout beneficiary to Cashfree |
| `requestTransfer` | onCall (Callable) | Request payout transfer |

### IAM & Permissions

**Current Status:** Default Cloud Functions service account is used. 

**Recommended:** Audit and restrict service account permissions following principle of least privilege:
- Firestore read/write for specific collections only
- Storage access for media uploads only
- Pub/Sub for async processing (if added)
- No direct access to user credentials or sensitive APIs

---

## Function Configuration Parameters

### Current Implementation

The current Cloud Functions code declares the Cashfree values below with `defineString()`. These are configuration parameters, not Firebase Secret Manager secrets. Do not use `firebase functions:secrets:set` or `firebase functions:secrets:access` for these parameters.

For local development or emulation, provide the parameters through a Firebase Functions environment file such as `functions/.env` or `functions/.env.<project-id>`. The repository `.gitignore` excludes `.env` files. For deployment, provide any missing parameter values when prompted by the Firebase CLI.

Because Cashfree credentials are sensitive, `defineString()` does not provide Secret Manager handling. Moving credentials to Secret Manager requires changing the function code to use secret parameters; that change is not documented as complete here.

### Required Parameters

#### Cashfree Payment API

```dotenv
# Set in functions/.env or functions/.env.<project-id> for local development.
CF_APP_KEY=<Cashfree application/client ID>
CF_SECRET=<Cashfree secret key>
CF_BASE_URL=<Cashfree API base URL>
```

**Values:**
- `CF_APP_KEY` — Cashfree application/client ID
- `CF_SECRET` — Cashfree secret key
- `CF_BASE_URL` — Cashfree API base URL (sandbox or production)
  - Sandbox: `https://sandbox.cashfree.com/pg`
  - Production: `https://api.cashfree.com/pg`

#### Cashfree Payout API

```dotenv
# Set in functions/.env or functions/.env.<project-id> for local development.
CF_PAYOUT_CLIENT_ID=<Cashfree payout client ID>
CF_PAYOUT_CLIENT_SECRET=<Cashfree payout client secret>
CF_PAYOUT_AUTH_URL=<Cashfree payout authorization endpoint>
CF_PAYOUT_BASE_URL=<Cashfree payout API base URL>
```

**Values:**
- `CF_PAYOUT_CLIENT_ID` — Cashfree payout client ID
- `CF_PAYOUT_CLIENT_SECRET` — Cashfree payout secret
- `CF_PAYOUT_AUTH_URL` — Payout authorization endpoint
  - Default: `https://payout-gamma.cashfree.com/payout/v1`
- `CF_PAYOUT_BASE_URL` — Payout API base URL
  - Sandbox: `https://sandbox.cashfree.com/payout`

### Security Notes

- Cashfree parameters are consumed by Cloud Functions and are not used in client-side code (`lib/` directory).
- Keep local `.env` files out of version control; `.gitignore` excludes them.
- The current `defineString()` declarations do not use Secret Manager. Use `defineSecret()` in the code before treating these values as Secret Manager secrets.
- No credential rotation policy is documented.

---

## Firestore Collections

### Canonical Collection Names

| Collection | Purpose |
|------------|---------|
| `users` | User profiles and metadata |
| `lockedMessages` | Locked content created by creators |
| `orders` | Payment orders (Cashfree) |
| `purchases` | Completed purchase records |
| `order-items` | Line items for orders |
| `wallets` | Creator wallet balances |
| `wallet_transactions` | Financial transaction ledger |
| `withdrawals` | Creator withdrawal requests |
| `rooms` | 1-to-1 chat rooms |
| `groups` | Group chats |
| `channels` | Broadcast channels |
| `verifications` | KYC verification documents |
| `adminUser` | Admin user records |

### Subcollections

- `rooms/{roomId}/messages` — Chat messages
- `groups/{groupId}/members` — Group members
- `groups/{groupId}/messages` — Group messages
- `channels/{channelId}/subscribers` — Channel subscribers
- `channels/{channelId}/messages` — Channel messages
- `users/{userId}/withdrawals` — User-specific withdrawal history

---

## Security Rules

### Firestore Rules

**File:** `firestore.rules`

**Status:** ✅ Production-grade rules deployed

**Key Security Policies:**
- Client writes **blocked** for: `purchases`, `wallets`, `wallet_transactions`
- Read access restricted by ownership (`isOwner()`, `isPurchaseOwner()`)
- Default deny-all fallback: `match /{document=**} { allow read, write: if false; }`

### Storage Rules

**File:** `storage.rules`

**Status:** ✅ Production-grade rules created (needs deployment)

**Key Security Policies:**
- Locked message media accessible only to creator or purchaser
- User profile images accessible to authenticated users only
- Chat/group/channel media restricted to participants/members
- KYC documents accessible only to owner
- Default deny-all fallback

**Deploy Storage Rules:**
```bash
firebase deploy --only storage
```

---

## Firebase Hosting

**Public Directory:** `LockifyFrontend/dist`

### URL Rewrite Rules

1. **Locked message links:** `/[A-Za-z0-9]{6}` → `/lockedMessages.html`
2. **All other routes:** `/**` → `/index.html`

---

## Deployment

### Deploy All

```bash
firebase deploy
```

### Deploy Specific Services

```bash
# Firestore rules only
firebase deploy --only firestore:rules

# Storage rules only
firebase deploy --only storage

# Cloud Functions only
firebase deploy --only functions

# Hosting only
firebase deploy --only hosting
```

### Emulators (Development)

```bash
cd functions
npm run serve  # Starts functions emulator
```

**Note:** Emulator configuration exists but testing strategy not fully established.

---

## Client Configuration

### Flutter Firebase Options

**File:** `lib/firebase_options.dart`

**Platforms:**
- Android (`google-services.json`)
- iOS (`GoogleService-Info.plist`)

**Storage Bucket:** `zipind-57.firebasestorage.app`

---

## External Integrations

### Cashfree

**Webhook URL:** `https://paymentsuccesswebhook-eof7ol2ifa-uc.a.run.app`

**Webhook Signature Verification:** ✅ HMAC-SHA256 with timing-safe comparison

**API Version:** `2025-01-01` (Payment API), `2024-01-01` (Payout API)

### Netlify Function (Legacy)

**Beneficiary Endpoint:** `https://lockifybackend.netlify.app/.netlify/functions/addbeneficiary`

**Note:** This appears to be a legacy endpoint. Consider migrating to Firebase Functions fully.

---

## Monitoring & Logging

### Current Status

- ✅ Structured logging added to payment functions (`firebase-functions/logger`)
- ✅ Correlation IDs added to requests for tracing
- ❌ No centralized monitoring dashboard
- ❌ No alerting configured
- ❌ No performance profiling

### Recommended Next Steps

1. Enable Firebase Performance Monitoring
2. Set up Cloud Logging alerts for errors
3. Configure uptime monitoring for critical endpoints
4. Add custom metrics for payment success/failure rates

---

## Environment Separation (Recommended)

**Current:** Single project (`zipind-57`) for all environments

**Recommended Structure:**

```
lockify-dev (Development)
├── Test data, frequent deployments
├── Sandbox Cashfree credentials

lockify-staging (Staging)
├── Pre-production testing
├── Sandbox Cashfree credentials

lockify-prod (Production)
├── Real user data
├── Production Cashfree credentials
├── Strict deployment controls
```

**Migration Steps:**
1. Create new Firebase projects for dev and staging
2. Update `.firebaserc` with project aliases
3. Deploy rules and functions to each environment
4. Use environment-specific secret values

---

## Checklist for New Developers

- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login to Firebase: `firebase login`
- [ ] Clone repository
- [ ] Install Flutter dependencies: `flutter pub get`
- [ ] Install function dependencies: `cd functions && npm install`
- [ ] Request access to Firebase project `zipind-57`
- [ ] Request Cashfree API credentials (dev/sandbox)
- [ ] Set local secrets (if running emulators)
- [ ] Run emulators: `cd functions && npm run serve`
- [ ] Run Flutter app: `flutter run`

---

## Last Updated

2026-10-01

**Maintained by:** Development Team
