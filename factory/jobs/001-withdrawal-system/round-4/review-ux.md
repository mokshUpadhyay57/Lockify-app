VERDICT: CHANGES

- `lib/screens/settings/earning/withdrawal_history_screen.dart:98-99`: When the withdrawal stream fails, the screen displays `Error: ${snapshot.error}`, exposing a raw Firestore exception without a recovery action. Replace this with clear user-facing guidance and a retry control so the user can recover and check payout status after a transient connection failure.

Round-3 progress feedback is resolved: the bank setup form now shows a spinner and “Submitting...” while the request is in flight.
