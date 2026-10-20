VERDICT: CHANGES

- `lib/screens/settings/earning/add_bank_detail_screen.dart:211-212`: While the beneficiary request is in flight, the Submit button becomes disabled but retains its normal label and shows no progress indicator. Since this is a network call, users can interpret the unchanged button as an ignored tap. Show a submitting state until the call completes, as the withdrawal button now does.

Round-2 UX findings are resolved: withdrawal submission shows progress, wallet summaries wait for data and surface loading errors, the amount scales down for narrow layouts, and the history count is labeled `Pending requests`.
