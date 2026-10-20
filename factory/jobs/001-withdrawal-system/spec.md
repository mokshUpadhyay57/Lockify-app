# Withdrawal system

## Feature request
Add a withdrawal system to Lockify.

## Repository profile
- Flutter/Dart 3.7
- 2-space formatting; run `dart format`
- Validate with `flutter analyze` and `flutter test`
- Firebase Functions use Node 22 and `npm run serve`

## Scope
Complete the existing creator earnings withdrawal flow using the wallet, bank-detail, withdrawal-history, and Firebase Functions code already in the repository. A verified creator with a configured payout beneficiary can request a payout from available wallet funds, follow its status in withdrawal history, and see wallet balances reflect the request and its final outcome. Keep payout credentials and balance-changing decisions on the server. Preserve the existing ₹100 minimum and the current limit of three requests in 24 hours, including its seven-day cooldown after the limit is reached.

## Acceptance criteria
- Unauthenticated, unverified, below-minimum, over-balance, missing-beneficiary, rate-limited, or otherwise invalid withdrawal requests are rejected with a user-visible explanation and do not change wallet balances or create a successful request.
- An eligible request is authorized against the signed-in user's identity and configured beneficiary on the server; a client cannot choose another user's wallet or beneficiary or supply trusted payout credentials.
- Each accepted request creates one user-visible withdrawal-history entry with amount, request time, and status, and reserves the requested amount from `availableBalance` into `pendingBalance` without allowing concurrent requests to overdraw the wallet.
- Payout processing uses the existing Firebase Functions/Cashfree integration. Success and failure outcomes update the request status and wallet balances consistently; a failed payout returns the reserved amount to available funds.
- The earnings and withdrawal-history screens show the updated available/pending amounts and the request's current status, including after the app is reopened.
- Repeating the same request or payout callback does not create duplicate withdrawals, transfers, or wallet transactions.
