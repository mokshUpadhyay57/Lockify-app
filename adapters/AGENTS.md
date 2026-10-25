# Agent Guide

This is the shared project agent guide stored in adapters/; it applies to all repository work, including adapter changes. For canonical GSD process, follow [brain/project_rules.md](../brain/project_rules.md).

## Project and workflow

- Lockify is a Flutter/Dart messaging and creator app using Firebase Auth, Firestore, Storage, and Cloud Functions. App code is in `lib/`, backend functions in `functions/`, rules/indexes at the root, and platform shells in `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`.
- Before changing anything, inspect relevant code, docs, and Git changes. Search first and trace the UI → service → Firebase flow. Reuse existing widgets, services, models, and utilities; keep edits focused and preserve unrelated/user changes.
- Follow nearby naming and style; Dart uses 2 spaces and `dart format`. Avoid unnecessary files, duplicated logic, generated-file or dependency churn, and platform-specific edits that the task does not need.
- Start at low reasoning effort for routine work; raise it to match complexity and risk. Effort settings are recommendations, never a reason to skip inspection or verification.

## Safety and architecture

- Keep credentials, tokens, personal data, and payment details out of source, logs, and commits. Use established Firebase secret/configuration mechanisms; never weaken Firestore or Storage access checks to make a feature work.
- Backend functions are authoritative for payments, wallet accounting, and paid-content entitlements. Preserve server-side validation, transaction safety, and idempotency. Keep Firebase access in existing service/function patterns.
- When a change requires it, update rules, indexes, function exports, and client call sites together. For payment work, inspect the complete create → verify/webhook → finalize flow.
- Do not commit, deploy, publish, or change external services unless explicitly requested.

## Verification

- Run focused checks appropriate to the change. Flutter: `dart format <edited files>`, `flutter analyze`, and affected `flutter test` cases. Functions: `node --check <edited files>` and, when useful, `npm --prefix functions run serve`. Rules/config/docs: use the relevant validator or syntax check.
- For UI/data changes, inspect affected screens/widgets, models, services, and backend/rules as applicable. Validate Firestore/Storage rule changes with emulators. Never claim a check passed unless it ran; report checks skipped or blocked and why.
- Repository validators: `scripts/validate-all.sh` (Bash) and `scripts/validate-all.ps1` (PowerShell). Use the matching shell; do not assume Bash syntax works in PowerShell or run broad/costly checks without need.

## GSD and project references

- `.agent/workflows/`, `.agents/`, `.gsd/`, `adapters/`, and `brain/project_rules.md` support the project’s GSD methodology. Follow applicable workflow/skill guidance and avoid duplicating its detailed process here.
- Check `skills/` for Lockify-specific Flutter, Firestore, and payment practices; consult `README.md` for setup and architecture.

## Required project context

- Before starting work, read `brain/memory.md`, `brain/architecture.md`, and `brain/roadmap.md`, then check this guide and any more specific `AGENTS.md` that applies.
- After work, refresh the existing `Last updated` line and concise durable notes in `brain/memory.md`. Review architecture, roadmap, app flow, database, and other relevant references; update only those made stale by the change. Roadmap tracks product scope, sequence, status, and completion, not documentation chores.
- Factory builders follow the same checks and record project docs reviewed or updated in the job's `build.md`.
- Do not append repetitive task logs or duplicate the same facts across docs.
