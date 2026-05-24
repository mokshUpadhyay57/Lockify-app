---
name: lockify-flutter-feature
description: Build, modify, debug, or review Lockify Flutter app features. Use for changes in lib/components, lib/screens, lib/models, lib/services, and lib/utils, especially UI flows, reusable widgets, Firebase-backed services, navigation, snackbars, locked messages, chats, groups, channels, wallet, settings, login, and profile screens.
---

# Lockify Flutter Feature

## Overview

Use this skill to make small, maintainable Flutter changes in Lockify while preserving existing app structure, visual language, and Firebase data flow.

## Workflow

1. Classify the request as a screen change, reusable widget change, service/data change, model change, or bug fix.
2. Search existing code before editing: `lib/components/`, `lib/components/widgets/`, `lib/screens/`, `lib/models/`, `lib/services/`, and `lib/utils/`.
3. Reuse or extend existing widgets and services before adding anything new.
4. Keep edits scoped to the smallest affected screen, widget, or service.
5. Run `dart format` on edited Dart files, then run `flutter analyze`. Run `flutter test` for behavior that affects tests or shared logic.

## Project Patterns

- Prefer shared UI from `lib/components/widgets/`: `LockifyScaffold`, `MyButton`, `MyTextField`, `ChatInput`, `MessageBubble`, `EmptyState`, list tiles, headers, and cards.
- Prefer shared utilities from `lib/utils/`: `AppColors`, `AppNavigation`, `AppSnackBar`, `AppLogger`, contacts, text styles, and date helpers.
- Keep Firebase interaction in `lib/services/` when the logic is reused or non-trivial.
- Match existing singleton service style when extending services: static instance, factory constructor, and private named constructor.
- Use `AuthService` for current user and phone normalization when available instead of duplicating auth or phone logic.
- Use `AppLogger` for diagnostic logging instead of raw `print` in app code.
- Use `AppSnackBar` for user-facing success/error feedback when the caller has a `BuildContext`.

## UI Rules

- Use `AppColors` instead of hard-coded repeated colors when the color already exists.
- Use 2-space Dart indentation and run `dart format`.
- Keep widgets small, but do not create a new widget file unless the user explicitly asked or reuse benefit is clear.
- Use `context.mounted` before showing snackbars or navigating after `await`.
- Avoid landing-page style UI. Build the actual app workflow.
- Preserve existing screen organization under `lib/screens/products/`, `lib/screens/settings/`, `lib/screens/login/`, and `lib/screens/register/`.

## Firebase Data Flow

- Read collection names and document shapes from nearby services/screens before changing Firestore usage.
- Prefer filtered queries with `where`, `orderBy`, and `limit` where possible.
- Avoid new unbounded snapshots for static data. Use one-time `get()` unless live updates are needed.
- Keep payment and entitlement truth on the backend; do not unlock paid content from client-only state.
- For locked messages, purchases, wallet, chat, group, and channel flows, inspect the matching service and screen pair before editing.

## Validation

- Minimum: `dart format <edited dart files>` and `flutter analyze`.
- Use `flutter test` when touching models, services, shared widgets, or existing tested behavior.
- Report if validation could not run and why.
