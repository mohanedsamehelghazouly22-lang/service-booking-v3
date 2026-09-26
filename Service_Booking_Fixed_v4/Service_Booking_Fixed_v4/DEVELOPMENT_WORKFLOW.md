# Service Booking — Production Development Workflow

## Architecture

Flutter Android client → REST API → Node.js service → PostgreSQL.

The client never decides booking ownership, availability, role permissions, expiration, or cancellation eligibility. Those rules are authoritative on the backend.

## Booking workflow

1. Guest opens the app.
2. Guest browses services, locations, dates and available slots.
3. Guest selects a slot.
4. If not authenticated, Login/OTP or Google Sign-In is shown.
5. The selected service/location/date/slot is preserved locally in the booking draft.
6. Client sends the booking request to the backend.
7. Backend validates user, service, location, provider assignment, slot, booking mode and appointment time.
8. Backend starts a database transaction and locks the slot/booking resource.
9. Instant mode creates `Confirmed` atomically.
10. Pending mode creates `Pending` with a four-hour confirmation deadline.
11. Transaction commits; only then does the API return success.
12. Notifications are generated from server-side booking events.
13. A server-side worker expires unconfirmed pending bookings after four hours and releases the slot.

## Cancellation/rescheduling workflow

- Customer may cancel or reschedule only when more than three hours remain before the appointment.
- The backend calculates the rule using server time.
- The client only reflects the backend decision.
- Provider cancellation requires an explicit confirmation and creates an audit entry.

## Role workflow

### Customer
- Browse public catalog.
- Authenticate only when booking.
- Manage own profile and bookings.
- View only own booking data.

### Provider
- View only assigned locations/services.
- View authorized bookings.
- Confirm pending bookings.
- Cancel bookings with mandatory warning and audit logging.

### Super User/Admin
- Manage services, images, locations, providers, assignments, slots, booking configuration, users and roles.
- All privileged mutations are authorized on the backend.

## UI flow

Splash → Login/Guest → Home → Services → Service Details → Location → Date → Time Slot → Login if required → Booking Confirmation → My Bookings.

Provider: Login → Provider Dashboard → Date → Booking Table → Confirm/Cancel.

Admin: Login → Admin Dashboard → Services / Locations / Providers / Assignments / Slots / Bookings / Users / Configuration.

## GitHub CI/CD

- Pull requests run backend syntax validation, Flutter analyze and Flutter tests.
- Pushes to `main` run the same checks and build a release APK.
- Tags such as `v1.0.0` also create a GitHub Release containing the APK.
- Configure the repository secret `API_BASE_URL` with the production API base URL before a release build.

Flutter 3.47 is pinned for reproducible CI. Flutter's official documentation lists 3.47 as the current stable release as of August 2026.

## Required production secrets

- `API_BASE_URL`
- Google OAuth Android configuration
- Phone/OTP provider credentials on the backend only
- Database connection credentials on the backend only
- Push notification provider credentials on the backend only

Never commit any of these secrets to GitHub.
