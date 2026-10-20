VERDICT: CHANGES

- `lib/screens/settings/earning/withdrawal_history_screen.dart:79-82`: If the wallet-balance stream errors, the entire history screen is replaced by “Unable to load wallet balances.” with no retry action. This can hide request statuses during a transient wallet read failure even when the history itself is available. Add a retry control for the wallet stream (or keep history visible while showing a recoverable balance error).
