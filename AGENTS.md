# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app. Reusable widgets live in `lib/components/`, screen-level UI in `lib/screens/`, data classes in `lib/models/`, and shared helpers in `lib/utils/`. App entry points are `lib/main.dart` and `lib/home_screen.dart`; Firebase client config is in `lib/firebase_options.dart`.

Platform runners are in `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`. Web-facing static pages and assets are in `public/`. Firebase Cloud Functions are isolated in `functions/` with their own `package.json`. Tests currently live in `test/`.

## Build, Test, and Development Commands
- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: launch the app on the selected device or emulator.
- `flutter analyze`: run static analysis using `analysis_options.yaml`.
- `dart format lib test`: apply standard Dart formatting before committing.
- `flutter test`: run widget and unit tests from `test/`.
- `flutter build apk` or `flutter build web`: produce Android or web builds.
- `cd functions && npm install`: install Cloud Functions dependencies.
- `cd functions && npm run serve`: start the Firebase Functions emulator.
- `cd functions && npm run deploy`: deploy functions to Firebase.

## Coding Style & Naming Conventions
Use standard Dart style: 2-space indentation, trailing commas where Flutter formatting expects them, and `dart format` as the source of truth. Follow the existing lowercase_with_underscores file naming used by files like `purchase_screen.dart` and `dotted_border_box.dart`. Keep widgets, models, and helpers small and feature-focused. Use `flutter analyze` to catch lint issues; the repo inherits `flutter_lints` and currently ignores `unused_local_variable`.

For `functions/index.js`, keep JavaScript simple and modular, and avoid mixing frontend concerns into backend handlers.

## Testing Guidelines
Add Flutter tests under `test/` and prefer names ending in `_test.dart`. Mirror the production area when practical, for example `test/screens/purchase_screen_test.dart`. Run `flutter test` before opening a PR. If you change Firebase Functions, validate them locally with `npm run serve` before deployment.

## Commit & Pull Request Guidelines
History is sparse, but existing messages are short and imperative. Continue with concise subjects like `Add locked message admin view` or `Fix purchase screen validation`. Keep commits scoped to one change.

PRs should include a brief summary, testing notes, linked issues, and screenshots or recordings for UI changes. Call out Firebase config, emulator steps, or deploy impact when touching `functions/`, `public/`, or platform-specific setup.
