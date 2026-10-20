VERDICT: CHANGES

- `functions/index.js:215,279`: the request handler returns the existing withdrawal for a repeated `requestId`, avoiding another provider call and reservation. However, `functions/test/withdrawal.test.js` has no request-replay regression test; its repeated-callback test covers settlement idempotency only. Add a test that submits the same ID twice and asserts one history entry, one wallet transaction, one `/requestTransfer` call, and one balance reservation. This covers the separate acceptance criterion that repeating a request must not duplicate withdrawals or transfers.
