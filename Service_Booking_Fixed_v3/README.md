# Service Booking

Production-oriented Flutter Android service booking application with a Node.js/PostgreSQL backend.

## Included
- Customer guest browsing and authenticated booking flow.
- Phone OTP architecture + Google Sign-In integration point.
- Customer profile model.
- Service/location/date/slot booking flow.
- Pending and instant booking modes.
- Server-side 4-hour pending expiration worker.
- 3-hour cancellation/reschedule backend rule.
- PostgreSQL UUID keys, foreign keys, indexes and partial unique index to prevent double booking.
- Provider and admin dashboard UI foundations.
- Role-based backend authorization middleware.
- Notification architecture endpoint/worker hooks.
- Peach/orange + near-black commercial UI based on the supplied visual references.

## Backend
1. Create PostgreSQL database.
2. Run `backend/sql/schema.sql`.
3. Copy `backend/.env.example` to `backend/.env` and fill secrets.
4. `cd backend && npm install && npm run dev`.

## Flutter
1. Install Flutter stable.
2. `flutter pub get`
3. For emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api`
4. For a physical Android device use the LAN IP of the backend, for example `http://192.168.1.20:8080/api`.
5. Release APK: `flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN/api`

## Production credentials
Google OAuth, SMS provider credentials, database URL, JWT secret and push notification credentials are intentionally environment variables. Do not commit them.

## Important
This repository is source-ready. A release APK must be built in an environment with the Flutter SDK and Android toolchain installed, plus production backend credentials configured. The current execution environment does not contain the Flutter SDK, so a local `flutter build apk` cannot truthfully be claimed as executed here.

## Production workflow

See `DEVELOPMENT_WORKFLOW.md` for the complete booking lifecycle, role boundaries, backend authority rules and GitHub CI/CD process.

The GitHub workflow in `.github/workflows/flutter.yml` validates the backend, runs Flutter analysis/tests, builds a release APK, uploads it as an artifact, and creates a GitHub Release for version tags.
