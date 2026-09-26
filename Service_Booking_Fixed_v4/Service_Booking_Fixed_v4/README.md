# Service Booking — Flutter Android + Supabase

This version is structured as a **repository-root Flutter project**. Upload the contents of this folder directly to the root of the GitHub repository.

## Fixed in V4

- Removed the incorrect nested `Service_Booking_GitHub_Ready/service_booking_project` working-directory assumption.
- `pubspec.yaml` is at repository root.
- Supabase Flutter dependency is declared in the same `pubspec.yaml` used by CI.
- Removed `intl` dependency and replaced the three date formatting calls with local formatting helpers.
- Removed direct `google_sign_in` dependency; Google authentication uses Supabase OAuth.
- Fixed the Flutter theme `fontFamily` error by applying the font family through `TextTheme.apply`.
- Added a tracked `assets/images/.gitkeep` so the declared asset directory always exists.
- CI explicitly verifies the root Flutter project before `flutter pub get` and `flutter analyze`.
- Release workflow creates the Android project only when it is absent, then builds APK/AAB.
- Supabase secrets are injected only at build time with `--dart-define` and are not committed.

## Required GitHub repository secrets

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

## Important

The workflow can run `flutter analyze`, tests, and release builds on GitHub Actions. This environment does not include the Flutter SDK/Android SDK, so a local `flutter analyze`/APK build could not be executed here.
