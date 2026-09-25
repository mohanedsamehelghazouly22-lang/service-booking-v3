CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone varchar(32) UNIQUE,
  email varchar(320) UNIQUE,
  full_name varchar(160) NOT NULL DEFAULT '',
  date_of_birth date,
  gender varchar(32),
  governorate varchar(120),
  city varchar(120),
  role varchar(24) NOT NULL DEFAULT 'customer' CHECK (role IN ('customer','provider','admin')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE otp_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone varchar(32) NOT NULL,
  code_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  attempts integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX otp_phone_idx ON otp_codes(phone, created_at DESC);

CREATE TABLE services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(160) NOT NULL,
  description text NOT NULL DEFAULT '',
  image_url text NOT NULL DEFAULT '',
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar(160) NOT NULL,
  governorate varchar(120) NOT NULL,
  city varchar(120) NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE service_locations (
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  location_id uuid NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  PRIMARY KEY(service_id, location_id)
);

CREATE TABLE provider_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location_id uuid NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  booking_mode varchar(16) NOT NULL CHECK (booking_mode IN ('pending','instant')),
  UNIQUE(provider_id, location_id, service_id)
);
CREATE INDEX provider_assignment_provider_idx ON provider_assignments(provider_id);

CREATE TABLE slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  location_id uuid NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  capacity integer NOT NULL DEFAULT 1 CHECK (capacity > 0),
  enabled boolean NOT NULL DEFAULT true,
  UNIQUE(service_id, location_id, starts_at)
);
CREATE INDEX slots_lookup_idx ON slots(service_id, location_id, starts_at);

CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES users(id),
  service_id uuid NOT NULL REFERENCES services(id),
  location_id uuid NOT NULL REFERENCES locations(id),
  slot_id uuid NOT NULL REFERENCES slots(id),
  provider_id uuid REFERENCES users(id),
  status varchar(16) NOT NULL CHECK (status IN ('pending','confirmed','expired','cancelled','completed')),
  booking_mode varchar(16) NOT NULL CHECK (booking_mode IN ('pending','instant')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  expires_at timestamptz
);
CREATE UNIQUE INDEX bookings_active_slot_unique ON bookings(slot_id) WHERE status IN ('pending','confirmed');
CREATE INDEX bookings_customer_idx ON bookings(customer_id, created_at DESC);
CREATE INDEX bookings_provider_idx ON bookings(provider_id, status, created_at DESC);
CREATE INDEX bookings_expiry_idx ON bookings(status, expires_at) WHERE status = 'pending';

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES users(id),
  action varchar(120) NOT NULL,
  booking_id uuid REFERENCES bookings(id),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type varchar(80) NOT NULL,
  title varchar(180) NOT NULL,
  body text NOT NULL,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON notifications(user_id, created_at DESC);
