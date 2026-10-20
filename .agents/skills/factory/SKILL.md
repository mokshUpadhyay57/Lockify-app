---
name: factory
description: Run the shared file-driven software factory for a feature, backlog item, human approval, or rework request.
---

# Factory for Codex

Use `$factory <feature>`, `$factory next`, `$factory approve <job-id>`, or `$factory rework <job-id> <note>`. Codex is the orchestrator for this run. The Claude Code skill at `.claude/skills/factory/SKILL.md` operates the same board and job files.

Only one Claude Code or Codex factory run may orchestrate at a time. The orchestrator is the only writer of `factory/board.json`; reread the board before each update and preserve every other job. Agents read handoff files rather than conversation history. Each agent writes only its assigned Markdown file, except the builder may also edit and commit product code.

## Run the workflow

1. Create a kebab-case job id using the next available three-digit number. Create `factory/jobs/<job-id>/spec.md` with the requested feature and this repo profile: Flutter/Dart 3.7, 2-space formatting, `dart format`, `flutter analyze`, and `flutter test`; Firebase Functions use Node 22 and `npm run serve`. Create an empty `build.md`, add a board row at stage `spec` with `runtime: "codex"`, and spawn the `spec-writer` custom agent from `.codex/agents/spec-writer.toml`. Its role details are in `.agents/skills/factory/agents/spec-writer.md`. If using `$factory next`, select the first unchecked backlog item and mark it checked after creating its job. If there is no unchecked item, report that the backlog is empty.

2. When `spec.md` is complete, classify implementation complexity from its acceptance criteria and select the builder model before spawning it. Use a fast, lower-cost model such as `gpt-6-luna` for documentation, mechanical changes, and small isolated fixes; use a stronger general reasoning model such as `gpt-5.6-terra` for cross-module work, ambiguous requirements, migrations, payment/auth/security-sensitive code, or complex debugging. Use the selected model's default reasoning effort unless the runtime exposes an explicit effort override. If a requested model is unavailable, use the session default and report the fallback. Spawn the `builder` custom agent from `.codex/agents/builder.toml` with the selected model override. Keep its returned thread handle under the logical name `builder-<job-id>`. The builder creates branch `factory/<job-id>`, implements the acceptance criteria, runs relevant validation, commits the changes, and writes the commit and results to `build.md`.
3. Create `round-<n>/` and classify the feature from its spec and changed files. Always run `security` and `code` reviews. Run `ux` only when the feature changes user-facing behavior or flows; run `ui-design` only when it changes an interface, including screens, widgets, layout, or visual states. Mark non-applicable reviewer slots `SKIP`; mark applicable slots `pending`. Spawn applicable custom agents from `.codex/agents/<role>.toml`; each gets its role file, the job folder, and only its own review output path. Codex subagents inherit the current session's model unless configured otherwise.

4. Track each spawned thread. **Wait for every applicable review file to exist before reading results or resuming the builder.** Each file starts with exactly `VERDICT: PASS` or `VERDICT: CHANGES`. Verify all applicable files exist, then record verdicts; skipped roles have no review file. If any reviewer requests changes, send only those findings to the same `builder-<job-id>` thread. The builder addresses findings marked `CHANGES` only and preserves areas marked `PASS`. In the next review round, rerun only reviewer roles marked `CHANGES` in the preceding round; mark prior `PASS` and `SKIP` roles `SKIP`. Add another reviewer only if the rework introduces changes in a new review area. Do not resume the builder mid-round. Keep the selected model for the job unless the runtime supports changing it. If a stronger model is needed and the runtime cannot change the existing thread's model, wait until the current builder has stopped, then hand off the same branch and job files to one replacement builder sequentially; never allow two builders to write the branch at once. Allow up to five review rounds per work cycle. If runtime concurrency is limited, start remaining applicable reviewers as slots free up.
5. When all applicable reviewers pass, set the stage to `approval` and spawn the `approver` custom agent from `.codex/agents/approver.toml`. If changes remain after round five, also ask the approver for an escalation decision. Its `decision.md` starts with exactly `APPROVE` or `ESCALATE`. On `APPROVE`, the orchestrator merges the branch into `main`. On `ESCALATE`, set stage `needs-human` and wait for `$factory approve <job-id>` before merging. The approve command is explicit human authorization to merge.

If this Codex session has subagents disabled, stop before starting the job and report that delegation must be enabled. Do not claim agents were spawned or silently run the review stages yourself.

## Commands and shared state

- `$factory <feature>` starts a new job.
- `$factory next` starts the first unchecked item in `factory/backlog.md`.
- `$factory approve <job-id>` merges a `needs-human` job into `main` and updates its board row.
- `$factory rework <job-id> <note>` appends the human's note to `build.md`, moves the job to `build`, and continues the same builder with the note and relevant review folder. This explicit rework starts a fresh five-round allowance; keep round numbers increasing.

Keep `factory/board.json` valid JSON. Each job row records `id`, `feature`, `branch`, `runtime`, `stage`, current `round`, and `rounds`. Set `runtime` to `codex`. Each round has a `round` number and a `reviews` map for `security`, `ux`, `ui-design`, and `code`, whose values are `pending`, `PASS`, `CHANGES`, or `SKIP`. Stages are `feature`, `spec`, `build`, `review`, `approval`, `needs-human`, and `merged`.

The handoff files are `spec.md`, `build.md`, `round-<n>/review-security.md`, `review-ux.md`, `review-ui.md`, `review-code.md`, and `decision.md`. Update the board after every stage change and review verdict. Do not modify product code during factory setup or orchestration unless it is part of the requested feature.
