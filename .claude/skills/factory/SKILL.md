---
name: factory
description: Run the repository's file-driven software factory for a feature, backlog item, human approval, or rework request.
---

# Software factory

This skill is the orchestrator. The current Claude Code session owns the loop and is the only writer of `factory/board.json`. Agents read job files and write only their assigned file; the builder also edits and commits product code on the job branch. Only one Claude Code or Codex factory run may orchestrate at a time. Reread the board before each update and preserve every other job.

## Commands

- `/factory <feature>` — start a job and run it through review and decision.
- `/factory next` — start the first unchecked item in `factory/backlog.md`.
- `/factory approve <job-id>` — merge a `needs-human` job into `main` after the user's explicit command.
- `/factory rework <job-id> <note>` — send the job back to its existing builder with the supplied feedback.

## Run a job

1. Before starting or delegating a job, read `brain/memory.md`, `brain/architecture.md`, `brain/roadmap.md`, `adapters/AGENTS.md`, and any more specific `AGENTS.md` that applies. Read other `brain/` references when relevant. Make a kebab-case job id from the next available three-digit number and a short feature name. Create `factory/jobs/<job-id>/spec.md` with the user's feature request and this repo profile: Flutter/Dart 3.7, 2-space formatting, `dart format`, validation with `flutter analyze` and `flutter test`; Firebase Functions use Node 22 and `npm run serve`. The spec-writer turns this brief into a concise implementation spec with acceptance criteria. Create an empty `build.md` and set the board stage to `spec`, recording `runtime: "claude-code"`. Pass the required project reference paths to agents and require them to read those references before their stage.
2. Spawn `spec-writer` to complete `spec.md`. Then classify implementation complexity from the acceptance criteria and select the builder model before spawning it: use `sonnet` for documentation, mechanical changes, and small isolated fixes; use `opus` for cross-module work, ambiguous requirements, migrations, payment/auth/security-sensitive code, or complex debugging. Update the board stage to `build` and spawn `builder` with the selected model override and persistent name `builder-<job-id>`. The builder reads the required references before work, implements the spec, reviews project docs for staleness, updates `memory.md` and any relevant docs, runs relevant validation, commits the changes, and records the commit, validation, and doc review (including reviewed docs left unchanged and why) in `build.md`. If the runtime cannot apply the model override, use its default and report the fallback.
3. Start a review round by creating `round-<n>/` and classifying the feature from its spec and changed files. Always run `security` and `code`. Run `ux` only for user-facing behavior or flows; run `ui-design` only for interface changes, including screens, widgets, layout, or visual states. Set non-applicable board verdicts to `SKIP` and applicable ones to `pending`; spawn only applicable reviewers with the job folder and their own output path.
4. **Wait for every applicable review file to exist before reading verdicts or resuming the builder.** Each review file starts with exactly `VERDICT: PASS` or `VERDICT: CHANGES`; skipped roles have no review file. Record the complete round and verdicts on the board. If a reviewer requests changes, send only those findings to the same `builder-<job-id>` using `SendMessage`, pointing it to that round folder. The builder addresses findings marked `CHANGES` only and preserves areas marked `PASS`. In the next round, rerun only reviewer roles marked `CHANGES` in the preceding round; mark prior `PASS` and `SKIP` roles `SKIP`. Add a reviewer only if the rework introduces changes in a new review area. Never start the next round until all applicable files in the current round exist. Keep the selected model for the job unless the runtime supports changing it. If a stronger model is needed and the runtime cannot change the existing thread's model, wait until the current builder has stopped, then hand off the same branch and job files to one replacement builder sequentially; never allow two builders to write the branch at once. Allow up to five review rounds per work cycle.
5. When all applicable reviewers pass, spawn `approver`. If unresolved changes remain after round five, also send the complete record to `approver` for an escalation decision. Its `decision.md` starts with exactly `APPROVE` or `ESCALATE`. On `APPROVE`, the orchestrator merges the job branch into `main`; on `ESCALATE`, set stage `needs-human` and wait. Do not merge an escalated job until `/factory approve <job-id>` is explicitly run. That command merges the branch and updates the board.

## Board and files

Keep `factory/board.json` valid JSON and update it after each stage or verdict change. It is the dashboard's source of truth. Record each job's `id`, `feature`, `branch`, `runtime`, `stage`, current `round`, and a `rounds` array. Set `runtime` to `claude-code`. Each round has `round` and a `reviews` object with `security`, `ux`, `ui-design`, and `code` set to `pending`, `PASS`, `CHANGES`, or `SKIP`. Stages are `feature`, `spec`, `build`, `review`, `approval`, `needs-human`, and `merged`.

Job files are the handoff: `spec.md`, `build.md`, `round-<n>/review-security.md`, `review-ux.md`, `review-ui.md`, `review-code.md`, and `decision.md`. Agents must not use conversation history as feature requirements. The orchestrator may create and update job files and the board; each agent writes only its assigned output file.

For `/factory next`, take the first unchecked backlog item and mark it checked once its job is created. For `/factory rework`, append the human's note to `build.md`, move the job to `build`, and message its existing builder with that file and the relevant review folder. This explicit human rework starts a fresh five-round review allowance; keep round numbers increasing.

Keep the loop small and visible. Do not modify this repo's product code when setting up or operating the factory unless it is part of the requested feature.

Before closing any job, confirm the builder completed the documentation review. `memory.md` is refreshed after each completed job; update architecture, roadmap, app flow, database, rules, design, PRD, or environment docs only when the change affects their documented facts. Roadmap records product implementation progress, not factory or documentation chores. Never append repetitive task logs or duplicate facts between docs.
