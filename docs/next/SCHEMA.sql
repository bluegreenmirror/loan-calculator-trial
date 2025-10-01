-- SCHEMA.sql
-- Postgres DDL for loan marketplace (ASCII only).

CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('auto','rv','motorcycle','jet_ski')),
  vehicle_price NUMERIC(12,2) NOT NULL CHECK (vehicle_price >= 0),
  affiliate TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  ip INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at);
CREATE INDEX IF NOT EXISTS idx_leads_vehicle_type ON leads(vehicle_type);

CREATE TABLE IF NOT EXISTS quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  vehicle_price NUMERIC(12,2) NOT NULL CHECK (vehicle_price >= 0),
  down_payment NUMERIC(12,2) DEFAULT 0,
  trade_in_value NUMERIC(12,2) DEFAULT 0,
  fees NUMERIC(12,2) DEFAULT 0,
  apr NUMERIC(6,3) NOT NULL CHECK (apr >= 0),
  term_months INTEGER NOT NULL CHECK (term_months BETWEEN 6 AND 120),
  tax_rate NUMERIC(5,4) DEFAULT 0,
  monthly_payment NUMERIC(12,2) NOT NULL,
  total_interest NUMERIC(12,2) NOT NULL,
  total_cost NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes(created_at);

CREATE TABLE IF NOT EXISTS tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  affiliate TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  click_id TEXT,
  lead_id UUID REFERENCES leads(id) ON DELETE SET NULL,
  ip INET,
  referrer TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tracks_affiliate_created ON tracks(affiliate, created_at);
