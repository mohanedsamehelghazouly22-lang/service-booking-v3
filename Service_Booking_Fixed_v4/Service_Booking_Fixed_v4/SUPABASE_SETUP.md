# Supabase setup

This version uses Supabase directly from Flutter. There is no Node API URL in the Flutter app.

## GitHub Actions secrets

Create these repository secrets:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The publishable key is safe to ship in a client application when your database is protected by correct RLS policies. Never put a Supabase service-role key in Flutter.

## Required database RPCs

Run `supabase/rpc.sql` in the Supabase SQL editor. `create_booking` is intentionally server-side so slot allocation can be atomic.

## Google OAuth

Enable Google under Supabase Authentication > Providers and configure the Android redirect/deep-link settings for the package. The app uses `io.supabase.servicebooking://login-callback/`.

## Phone OTP

Enable Phone authentication and configure your SMS provider in Supabase Auth.
