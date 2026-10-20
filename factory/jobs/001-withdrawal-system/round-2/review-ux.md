VERDICT: CHANGES

- `lib/screens/settings/earning/earning_home_screen.dart:538-555`: While `_isSubmittingWithdrawal` is true, the button is disabled but still displays “WITHDRAW” with the same icon and no progress feedback. A slow callable can look like an ignored tap. Show a spinner and a submitting label until the request resolves; retain the existing error or submitted dialog afterward.

Round-1 findings are addressed: pending payouts now receive submitted/awaiting copy, and beneficiary lookup distinguishes loading, confirmed absence, and retryable errors.
