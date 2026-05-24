---
name: lockify-firestore-performance
description: Review, debug, or optimize Lockify Firestore read/write cost and realtime behavior. Use for performance work involving Firestore queries, snapshots, indexes, repeated reads, Firebase Functions Firestore access, screen rebuilds that refetch data, chat/group/channel listeners, locked message access checks, wallet streams, purchase history, and Firebase cost reduction.
---

# Lockify Firestore Performance

## Overview

Use this skill to reduce Firestore reads, duplicate listeners, unnecessary writes, and function work while keeping Lockify behavior correct.

## Cost Model

- Reads are usually the first cost to reduce.
- A screen load should use the minimum reads needed for that screen.
- Use listeners only for live data; use one-time reads for static detail data.
- Prefer one backend finalization write path for payment state instead of multiple competing updates.

## Review Workflow

1. Identify the user action or screen lifecycle that triggers reads/writes.
2. Find all Firestore calls in the affected screen, widget, service, and function.
3. Count repeated reads caused by rebuilds, nested builders, duplicated futures, and multiple listeners.
4. Check whether each query has a filter, sort, limit, and matching index need.
5. Replace duplicate reads with cached futures/state or service-level single source of truth when it is safe.
6. Preserve realtime listeners where the user expects live chat, wallet, or message updates.

## Query Rules

- Avoid full collection reads in app code and functions.
- Use `.where(...)` and `.limit(...)` when fetching a specific user, order, entitlement, message, or summary.
- Use `.orderBy(...)` only with the index/query shape required by the UI.
- Prefer deterministic document IDs for repeated lookups when the project already has one.
- Avoid fetching user/profile data inside every message row if a cached map or preloaded participant metadata is enough.
- In Flutter, avoid creating new futures in `build` when the same data can be cached in `initState` or state after key changes.
- In functions, avoid calling third-party APIs after enough local state proves the request should fail.

## Existing Hotspots To Inspect

- `lib/services/chats/chat_service.dart`: private chat listeners merge UID and phone queries.
- `lib/services/group/group_service.dart` and `lib/services/channel/channel_service.dart`: group/channel streams and message queries.
- `lib/services/purchase_service.dart`: purchase history and locked message lookup.
- `lib/services/wallet_service.dart`: wallet document and wallet transaction streams.
- `lib/screens/products/locked_messages/`: locked message list, viewer, editor, and detail screen reads.
- `functions/payments/finalizeOrder.js`: transaction read/write count and idempotency.

## Optimization Patterns

- Cache one-time owner/profile lookups on a state field keyed by UID instead of recreating futures on every stream update.
- Move repeated Firestore logic from screens to services when several screens need the same query.
- Add limits to list queries that render only recent items.
- Use `Stream.empty()` or `Stream.value([])` for unauthenticated paths to avoid invalid queries.
- Use backend transaction idempotency for payment writes so webhook retries are cheap and safe.
- When an index is required, update `firestore.indexes.json` only for the exact query shape.

## Red Flags

- `.collection(...).get()` without filters for user-facing screens.
- Futures created directly in `build` without a stable cache.
- Nested `StreamBuilder` or `FutureBuilder` blocks that refetch per document.
- Multiple access checks for the same locked message during one purchase/view flow.
- Continuous listeners for settings, invoices, static profiles, or one-time purchase verification.
- Payment code that writes the same accounting state in more than one path.

## Validation

- For Dart edits, run `dart format`, `flutter analyze`, and relevant tests.
- For Functions edits, run `node --check` on edited files and emulator serve when practical.
- State what changed in expected read/write behavior, not just that code was modified.
