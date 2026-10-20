VERDICT: CHANGES

- `lib/screens/settings/earning/earning_home_screen.dart:134-140`: The confirmation dialog is titled “Withdrawal Successful” while the body says only that the request was submitted. Because payout processing continues asynchronously and can fail, the title overstates the current state. Rename it to “Withdrawal request submitted” (or equivalent) so it matches the pending flow.
- `lib/screens/settings/earning/earning_home_screen.dart:479-490`: This amount reads `availableBalance`, but its label is “Balance”; the neighboring value is “Pending” and the dedicated earnings/history summaries call the same figure “Available.” Label it “Available” so users can tell which funds can be withdrawn and the screens use consistent terms.
