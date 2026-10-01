# Agent Guide

## Project
- Lockify is a Flutter/Dart messaging and creator app backed by Firebase (Auth, Firestore, Storage, Cloud Functions). Main app code is in `lib/`; backend functions in `functions/`; rules and indexes at the root. Platform shells live in `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`.
- Before acting, inspect the relevant code, docs, and current Git changes. Search first; trace the existing UI → service → Firebase flow. Reuse existing widgets, services, models, and utilities. Keep changes small and scoped; don’t overwrite unrelated or user changes.
- Don’t create files or duplicate logic unless required by the task. Follow nearby naming, structure, and style; Dart uses 2 spaces and `dart format`.

## Safety and architecture
- Keep credentials, tokens, personal data, and payment details out of source, logs, and commits. Use existing Firebase configuration/secret mechanisms; never weaken Firestore or Storage access checks to make a feature work.
- Treat the backend as the authority for payments, wallet accounting, and paid-content entitlements. Preserve transaction safety, idempotency, and server-side validation.
- Keep Firebase access in the existing services/functions patterns. Update rules, indexes, function exports, and client call sites together when a change requires it.
- Change platform-specific files only when the task needs them. Avoid generated files, dependency churn, deployments, and destructive or external actions unless requested.

## Work and verification
- For UI/data changes, inspect the affected screen/widget, model, service, and backend/rules as applicable. For payments, inspect the full create → verify/webhook → finalize flow.
- Run focused validation appropriate to the change: Dart `dart format <edited files>` and `flutter analyze`; use `flutter test` for affected behavior. For Functions, run `node --check <edited files>` and, when useful, `npm --prefix functions run serve`. For rules/config/docs, use the relevant existing validator or syntax check.
- The repo’s GSD validators are `scripts/validate-all.sh` (Bash) and `scripts/validate-all.ps1` (PowerShell). Use the matching shell; don’t assume Bash syntax works in PowerShell. Don’t run broad or costly validation without need.
- Don’t claim a check passed unless it was run; report checks skipped or blocked and why. Don’t commit, deploy, publish, or alter external services unless explicitly asked.

## Project guidance
- `brain/project_rules.md` is the canonical GSD methodology; `.agent/workflows/`, `.agents/`, `.gsd/`, and `adapters/` support planning and agent workflows. Follow their applicable instructions when using that system. Avoid duplicating its detailed process here.
- Check `skills/` for Lockify-specific Flutter, Firestore, and payment practices when relevant. `README.md` describes setup and architecture.
