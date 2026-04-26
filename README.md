# Hotel Price Tracking — Paid Test Submission

## What this implements

A single Next.js API route (`POST /api/hotels/scan`) that:

1. Accepts `cityId`, `cityName`, `checkIn`, `checkOut` as JSON body
2. Fetches live hotel prices from the Makcorps API
3. Persists every result to Supabase with a timestamp
4. Queries the last 30 days of history for each hotel
5. Runs deal detection: **20%+ below avg = DEAL**, **35%+ = GREAT_DEAL**
6. Returns enriched JSON sorted by deal strength

---

## Setup

### 1. Install dependencies

```bash
npm install @supabase/supabase-js
```

### 2. Environment variables

Copy `.env.local.example` → `.env.local` and fill in your keys.

### 3. Run the Supabase migration

Paste `supabase_migration.sql` into your Supabase SQL editor and run it.
This creates the `hotel_prices` table with proper indexes and RLS policies.

### 4. Start the dev server

```bash
npm run dev
```

---

## Sample request

```bash
curl -X POST http://localhost:3000/api/hotels/scan \
  -H "Content-Type: application/json" \
  -d '{
    "cityId": "2734",
    "cityName": "New York",
    "checkIn": "2025-07-01",
    "checkOut": "2025-07-02",
    "rooms": 1,
    "adults": 2
  }'
```

## Sample response

```json
{
  "scannedAt": "2025-06-15T02:00:00.000Z",
  "cityId": "2734",
  "cityName": "New York",
  "checkIn": "2025-07-01",
  "checkOut": "2025-07-02",
  "rooms": 1,
  "adults": 2,
  "totalHotels": 24,
  "deals": 5,
  "greatDeals": 2,
  "results": [
    {
      "hotelId": "H123",
      "hotelName": "The Midtown Grand",
      "price": 89,
      "currency": "USD",
      "checkIn": "2025-07-01",
      "checkOut": "2025-07-02",
      "bookingUrl": "https://booking.com/...",
      "deal": {
        "tier": "GREAT_DEAL",
        "savingsPercent": 0.41,
        "avgPrice30Day": 151.00,
        "currentPrice": 89,
        "label": "41% below avg — Great Deal!"
      },
      "savedAt": "2025-06-15T02:00:00.000Z"
    }
  ]
}
```

---

## Architecture notes

### Why upsert instead of insert?

The unique constraint `(hotel_id, check_in, scanned_at)` means re-running a scan for the same moment is idempotent — safe for retries and cron jobs.

### 30-day history query

For each hotel we look up all price records in the 30-day window ending at `checkIn`, then compute a simple mean. This becomes richer over time as more scans accumulate.

### Combination optimizer (full project)

The optimizer treats night allocation as a bounded knapsack problem:
- Each hotel has a `dealScore` (savings%) and a `nightCost` (price/night)
- We enumerate combinations within the user's budget using a greedy approach biased toward higher `dealScore`
- Tie-break by lowest `nightCost` to maximize nights
- Runtime is O(n²) for typical hotel counts (~10–50 per city) — fast enough for real-time UI

---

## Files

```
src/
  app/api/hotels/scan/route.ts   ← The paid test deliverable
  lib/
    supabase.ts                  ← Supabase client
    makcorps.ts                  ← Makcorps API client + types
    dealDetection.ts             ← Deal analysis logic
supabase_migration.sql           ← Run once to set up DB schema
.env.local.example               ← Required env vars
```
