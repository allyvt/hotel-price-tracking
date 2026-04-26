-- ============================================================
-- Hotel Price Tracking Schema
-- Run in Supabase SQL editor to set up the required tables
-- ============================================================

-- Main price history table
CREATE TABLE IF NOT EXISTS hotel_prices (
  id             BIGSERIAL PRIMARY KEY,
  hotel_id       TEXT        NOT NULL,
  hotel_name     TEXT        NOT NULL,
  city_id        TEXT        NOT NULL,
  city_name      TEXT        NOT NULL,
  check_in       DATE        NOT NULL,
  check_out      DATE        NOT NULL,
  price          NUMERIC     NOT NULL CHECK (price > 0),
  currency       TEXT        NOT NULL DEFAULT 'USD',
  booking_url    TEXT,
  scanned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Unique constraint: one scan record per hotel per check_in per scan moment
  CONSTRAINT hotel_prices_unique UNIQUE (hotel_id, check_in, scanned_at)
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_hotel_prices_hotel_id    ON hotel_prices (hotel_id);
CREATE INDEX IF NOT EXISTS idx_hotel_prices_city_id     ON hotel_prices (city_id);
CREATE INDEX IF NOT EXISTS idx_hotel_prices_check_in    ON hotel_prices (check_in);
CREATE INDEX IF NOT EXISTS idx_hotel_prices_scanned_at  ON hotel_prices (scanned_at);

-- Composite index for 30-day history lookups
CREATE INDEX IF NOT EXISTS idx_hotel_prices_history
  ON hotel_prices (hotel_id, check_in, scanned_at);

-- Enable Row Level Security (RLS)
ALTER TABLE hotel_prices ENABLE ROW LEVEL SECURITY;

-- Policy: allow server-side service role full access
CREATE POLICY "service_role_all" ON hotel_prices
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy: allow anonymous reads (for public deal display)
CREATE POLICY "anon_read" ON hotel_prices
  FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- Optional: Supabase cron job (pg_cron) for nightly scans
-- Uncomment and configure after enabling the pg_cron extension
-- in Supabase Dashboard > Extensions
-- ============================================================

-- SELECT cron.schedule(
--   'nightly-hotel-scan',        -- job name
--   '0 2 * * *',                 -- 2am UTC daily
--   $$
--     SELECT net.http_post(
--       url := 'https://YOUR_PROJECT.vercel.app/api/hotels/scan',
--       headers := '{"Content-Type": "application/json", "x-cron-secret": "YOUR_SECRET"}',
--       body := '{"cityId": "2734", "cityName": "New York", "checkIn": "2025-07-01", "checkOut": "2025-07-02"}'
--     );
--   $$
-- );
