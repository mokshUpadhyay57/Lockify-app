# Claude Adapter

> **Everything in this file is optional.**
> For canonical rules, see [project_rules.md](../brain/project_rules.md).

This adapter provides optional enhancements for Claude models in Antigravity.

---

## Extended Thinking Mode

When available, activate extended thinking for:

| Task Type | Recommended |
|-----------|-------------|
| Architecture planning | ✅ High effort |
| Complex debugging | ✅ High effort |
| Security analysis | ✅ High effort |
| Simple edits | ❌ Not needed |
| Quick iterations | ❌ Overhead too high |

### Effort Levels

If the model supports effort/budget levels:

| Level | Use Case | Token Usage Notes |
|-------|----------|-------------------|
| `low` | Simple edits, formatting, comments, minor typo fixes | Minimal token usage |
| `medium` | Standard implementation, bug fixes, feature additions (default) | Efficient token usage for most tasks |
| `high` | Complex logic, refactoring, debugging, architectural changes | Moderate increase in tokens for deeper reasoning |
| `xhigh` | Complex architecture, deep security analysis, challenging debugging | Significant increase in tokens for complex reasoning |
| `max` | Highest stakes decisions, novel architecture, critical security work | **Highest token usage** - use extremely sparingly only when absolutely necessary |

**Default:** `low` if not specified. Increase effort only when the task's complexity or risk calls for it.

**Important Token Efficiency Notes:**
- Start with `low` effort for routine tasks and raise it when deeper reasoning is needed
- Only increase to `high`, `xhigh`, or `max` when you genuinely need deeper reasoning
- For security-related work, consider if `high` effort with careful prompting might suffice before jumping to `xhigh` or `max`
- Remember that `xhigh` and `max` efforts significantly increase token consumption and cost
- Use `xhigh` for: complex security analysis, challenging architectural decisions
- Use `max` primarily for: novel security analysis requiring deep reasoning, architectural decisions with long-term impact, or when previous attempts at lower effort levels failed to produce correct results after careful consideration

---

## Artifacts Mode

When artifacts are supported:

- Use for code generation that needs preview
- Use for documentation with formatting
- Avoid for small inline edits

---

## Context Optimization

Claude-specific context tips:

1. **System prompt loading**: Core rules in system prompt, task details in user message
2. **XML structure**: Claude parses XML well — use task XML format from `../brain/gsd_style.md`.
3. **Conversation history**: Minimal history preferred; use STATE.md for continuity

---

## File Conventions

Not required, but if organizing Claude-specific files:

```
.claude/
├── CLAUDE.md      # This adapter (if using)
└── settings.json  # IDE-specific settings
```

---

## Anti-Patterns

❌ **Using max effort for everything** — Slow and expensive
❌ **Skipping verification** — Thinking mode doesn't guarantee correctness
❌ **Depending on artifacts** — Not all Claude interfaces support them
❌ **Modifying security rules without testing** — Always validate Firestore and Storage rules changes with emulators
❌ **Hardcoding secrets** — Never place API keys or secrets in client-side code; use Firebase Functions config

---

## Lockify-Specific Guidance

When working on the Lockify project, consider these project-specific recommendations:

### Security Work
- Use `max` effort for Firestore.rules and storage.rules modifications
- Always test rules changes with Firebase emulators before deploying
- Verify that client writes are properly blocked for sensitive collections (purchases, wallets, transactions)

### Testing Work
- Use `high` effort when writing unit tests for Cloud Functions
- Follow the arrange-act-assert pattern in test files
- Test both success and failure paths, including edge cases
- Run tests locally with `npm test` before pushing changes

### Environment & Configuration
- Refer to ENVIRONMENT.md for setup instructions and secrets management
- Never commit .env files or hardcode credentials
- Use Firebase Functions `defineString()` for all configuration values

### Payment Flow Work
- Use `max` effort for payment-related Cloud Functions (createOrder, success webhook, verifyPayment)
- Always verify webhook signatures with timing-safe comparison
- Test idempotency and error handling scenarios thoroughly

*See brain/project_rules.md for canonical requirements.*
