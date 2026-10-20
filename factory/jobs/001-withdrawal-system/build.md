
## Summary

Moved withdrawal authorization and wallet accounting to Firebase Functions. Verified users can configure a server-side Cashfree beneficiary and request a payout from their available balance. Requests are deduplicated by request ID, atomically reserve funds, enforce the three-in-24-hours limit and seven-day cooldown, and settle idempotently through payout responses or a signed webhook. Firestore rules prevent clients from writing beneficiary, withdrawal, wallet, or verification state. Updated the earnings, bank setup, and expenditure flows to show configured status, submit requests, report failures, and count only completed withdrawals as debits.

## Changed files

- `firestore.rules`
- `functions/index.js`
- `lib/screens/settings/earning/add_bank_detail_screen.dart`
- `lib/screens/settings/earning/earning_home_screen.dart`
- `lib/screens/settings/earning/expenditure_scren.dart`

## Commit

- Branch: `factory/001-withdrawal-system`
- Commit: `dcf40fb` — `feat: add secure creator withdrawal flow`

## Validation

- `node --check functions/index.js` — passed.
- `dart format` — formatted the edited earnings and bank setup screens. The Dart tool then reported it could not update its telemetry file under the user profile; the workspace formatting completed.
- Focused `flutter analyze` on the changed Dart screens — exit 1 with 8 existing `withOpacity` deprecation infos; no errors or warnings in the changed flow.
- Full `flutter analyze` — exit 1 with 123 project-wide info/warning findings, including existing unused fields/parameters and deprecations; no errors in the changed files.
- `flutter test` — exit 1 in the existing `Counter increments smoke test`: `AuthGate` accesses `FirebaseAuth.instance` before Firebase is initialized, so the expected counter widget is not rendered.
- `git diff --cached --check` — passed before commit.

## Round 1 rework

Addressed the review findings by removing Cashfree authorization response and token logging; refunding reserved funds and failing the withdrawal for known pre-transfer errors while leaving after-send ambiguous outcomes pending; describing non-completed payouts as submitted and awaiting processing; and separating beneficiary loading/error states from confirmed absence. Beneficiary setup now reports when an account was already configured.

### Rework validation

- `node --check functions/index.js` — passed.
- `git diff --check` — passed.
- Focused `flutter analyze` on `add_bank_detail_screen.dart` and `earning_home_screen.dart` — exit 1 with six `withOpacity` deprecation infos; no errors or warnings in these files.
- Full `flutter analyze` — stalled without output under high CPU and was interrupted. The earlier run recorded above found 123 project-wide info/warning findings and no errors in the changed files.
- `flutter test` — exit 1 in the existing `Counter increments smoke test`: `AuthGate` accesses `FirebaseAuth.instance` before Firebase initialization, so the expected counter widget is not rendered.
- No focused Functions test was added: this repository has no Functions test files/script or installed `firebase-functions-test` harness, and no callable emulator is configured. The pre-transfer rollback path was reviewed in the request handler; the existing Flutter smoke test does not cover it.

### Rework commit

- Implementation commit: `22be8f82f01c3989b1b58cb67b6850cc6941c14f` — `fix: address withdrawal review findings`.
- Rework files: `functions/index.js`, `lib/screens/settings/earning/add_bank_detail_screen.dart`, and `lib/screens/settings/earning/earning_home_screen.dart`.

## Human rework note

Continue through up to round 5 under the updated factory policy; UX applies because this is user-facing, and UI design applies because it changes screens.

## Round 2 rework

Added visible submission progress, scaled the available amount to fit narrow screens, and made both earnings and history wallet summaries show loading and error states before rendering settled balances. The history count is now labeled `Pending requests`. Added focused Functions coverage for authorization rollback, concurrent reservation, and repeated payout settlement callbacks.

### Changed files

- `functions/package.json`
- `functions/test/withdrawal.test.js`
- `lib/screens/settings/earning/earning_home_screen.dart`
- `lib/screens/settings/earning/withdrawal_history_screen.dart`

### Validation

- `npm test --prefix functions` — passed, 3 tests: pre-transfer token verification failure restores the wallet and marks history/transaction failed; concurrent requests cannot over-reserve; repeated failed callbacks refund once and a later success callback cannot change the settled result.
- Focused `flutter analyze` on the two edited screens — reported nine existing `withOpacity` deprecation infos and no errors or warnings. The Flutter process remained open after printing the completed analysis and was interrupted; analyzer exit status was not available.
- `dart format` — reported `Formatted 2 files (1 changed)`. The Dart process remained open after formatting completed and was interrupted; exit status was not available.
- Functions regression tests use `firebase-functions-test` with a serial in-memory Firestore fake because this repository has no configured Firestore emulator. The suite exercises the production callable and webhook handlers and checks resulting wallet, withdrawal, and transaction state; it does not test Firestore SDK transaction retry internals.

### Commit

- `28e7dad` — `fix: improve withdrawal status and wallet handling`.

## Round 3 rework

Cashfree transfers now use server-generated 128-bit IDs. A `withdrawal_transfers` document created atomically with the reservation maps each transfer ID to its UID and per-user request ID; the signed webhook resolves that exact mapping. Wallet transaction document IDs are also namespaced by UID so equal client request IDs from separate users do not collide. Added request replay and cross-user callback regression tests. The bank setup button shows an in-flight spinner and label, and the history overview scales long amounts and wraps summary cards responsively.

### Changed files

- `firestore.rules`
- `functions/index.js`
- `functions/test/withdrawal.test.js`
- `lib/screens/settings/earning/add_bank_detail_screen.dart`
- `lib/screens/settings/earning/withdrawal_history_screen.dart`

### Validation

- `npm test --prefix functions` — passed, 5 tests, including same-user request replay (single history record, wallet transaction, reservation, and provider transfer) and cross-user reuse of a request ID with correct callback routing.
- `node --check functions/index.js` and `node --check functions/test/withdrawal.test.js` — passed.
- Focused `flutter analyze` on the edited bank setup and history screens — reported five existing `withOpacity` deprecation infos and no errors or warnings. The process remained open after reporting completion and was interrupted; exit status was not available.
- `dart format` — reported `Formatted 2 files (0 changed)`. The process remained open after reporting completion and was interrupted; exit status was not available.
- `git diff --check` — passed.

### Commit

- `e1741a8844eb1250c408097943a82438f1af9502` — `fix: isolate payout transfers across withdrawal requests`.

## Round 4 rework

Replaced raw withdrawal-stream exception text with concise retry guidance, added a Retry action that recreates the withdrawal stream, and aligned the pending wallet balance label with the earnings screen. Verified the four formatted amounts already use the actual U+20B9 rupee symbol; terminal rendering had displayed mojibake, so no currency source edit was necessary.

### Changed files

- `lib/screens/settings/earning/withdrawal_history_screen.dart`
- `factory/jobs/001-withdrawal-system/build.md`

### Validation

- `npm test --prefix functions` — passed, 5 focused Functions regression tests covering rollback, concurrent reservations, request replay, cross-user callback mapping, and idempotent settlement.
- `dart analyze lib/screens/settings/earning/withdrawal_history_screen.dart` — exit 0; reported four existing `withOpacity` deprecation infos and no errors or warnings.
- `dart format lib/screens/settings/earning/withdrawal_history_screen.dart` — reported `Formatted 1 file (0 changed)`; the process remained open after the result and was interrupted.
- `flutter analyze lib/screens/settings/earning/withdrawal_history_screen.dart` — produced no output and remained silent; interrupted after 90 seconds. The focused `dart analyze` result above completed successfully.
- `git diff --check` — passed.

### Commit

- Implementation commit: `483c7ec` — `fix: clarify withdrawal history errors`.
