VERDICT: PASS

- Both screens use the actual U+20B9 rupee glyph for displayed wallet and withdrawal amounts (verified from UTF-8 source), including the ₹100 minimum message. The prior round-4 glyph finding is resolved.
- Withdrawal Overview adapts between three, two, and one columns at width thresholds of 560 and 300 logical pixels; amount text scales down and summary labels can wrap to two lines. Earnings balance amount also uses a scale-down fit. These layouts should remain contained on narrow phones.
- Balance labels now match across screens: `Available` and `Pending`; withdrawal history distinguishes `Pending requests` as a count. No conflicting “On hold” label remains.
- Earnings and history both render a loading indicator before wallet data arrives and a concise error state if the wallet stream fails. History errors also provide a Retry action for the withdrawal list. The states are visually legible and avoid raw exception text.
