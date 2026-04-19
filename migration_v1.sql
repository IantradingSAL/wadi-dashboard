-- ══════════════════════════════════════════════════════════════
-- WADI EL SITT — DATABASE MIGRATION v1
-- Multi-tenant structure with municipality_id
-- Run in Supabase SQL Editor
-- ══════════════════════════════════════════════════════════════

-- 1. MUNICIPALITIES TABLE
CREATE TABLE IF NOT EXISTS municipalities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  region TEXT,
  logo_base64 TEXT,
  primary_color TEXT DEFAULT '#1a6eb5',
  secondary_color TEXT DEFAULT '#1e5429',
  website TEXT,
  phone TEXT,
  email TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Wadi El Sitt
INSERT INTO municipalities (id, name, name_en, region, primary_color, secondary_color, website)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'بلدية وادي الست',
  'Wadi El Sitt Municipality',
  'قضاء الشوف — محافظة جبل لبنان',
  '#1a6eb5', '#1e5429',
  'https://municipality-wadi-el-sitt.org'
) ON CONFLICT (id) DO NOTHING;

ALTER TABLE municipalities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_municipalities" ON municipalities;
CREATE POLICY "allow_all_municipalities" ON municipalities FOR ALL USING (true) WITH CHECK (true);

-- 2. ADD municipality_id TO cases
ALTER TABLE cases
  ADD COLUMN IF NOT EXISTS municipality_id UUID DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE cases SET municipality_id = '00000000-0000-0000-0000-000000000001' WHERE municipality_id IS NULL;

-- Fix type constraint (add ifada)
ALTER TABLE cases DROP CONSTRAINT IF EXISTS cases_type_check;
ALTER TABLE cases ADD CONSTRAINT cases_type_check
  CHECK (type IN ('complaint','welfare','permit','inquiry','ifada'));

-- 3. IRR_OWNERS TABLE (Irrigation water rights)
CREATE TABLE IF NOT EXISTS irr_owners (
  id TEXT PRIMARY KEY,
  municipality_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  area TEXT,
  land_name TEXT,
  land_ref TEXT,
  land_size TEXT,
  crop TEXT,
  hours DECIMAL(5,2) NOT NULL DEFAULT 2,
  sort_order INTEGER NOT NULL DEFAULT 1,
  notes TEXT,
  created_at DATE DEFAULT CURRENT_DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE irr_owners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_irr_owners" ON irr_owners;
CREATE POLICY "allow_all_irr_owners" ON irr_owners FOR ALL USING (true) WITH CHECK (true);

-- 4. IRR_CONFIG TABLE
CREATE TABLE IF NOT EXISTS irr_config (
  municipality_id UUID PRIMARY KEY DEFAULT '00000000-0000-0000-0000-000000000001',
  day_start TEXT DEFAULT '06:00',
  night_start TEXT DEFAULT '18:00',
  total_hours INTEGER DEFAULT 160,
  cycle_start_date TEXT DEFAULT '2026-04-20',
  sender_name TEXT DEFAULT 'لجنة الري — بلدية وادي الست',
  sender_email TEXT DEFAULT 'noreply@municipality-wadi-el-sitt.org',
  notif_settings JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO irr_config (municipality_id)
VALUES ('00000000-0000-0000-0000-000000000001')
ON CONFLICT (municipality_id) DO NOTHING;

ALTER TABLE irr_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_irr_config" ON irr_config;
CREATE POLICY "allow_all_irr_config" ON irr_config FOR ALL USING (true) WITH CHECK (true);

-- 5. UPDATE SETTINGS TABLE
ALTER TABLE settings
  ADD COLUMN IF NOT EXISTS municipality_id UUID DEFAULT '00000000-0000-0000-0000-000000000001';
UPDATE settings SET municipality_id = '00000000-0000-0000-0000-000000000001' WHERE municipality_id IS NULL;

-- 6. SUPER ADMINS TABLE
CREATE TABLE IF NOT EXISTS super_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE super_admins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_super_admins" ON super_admins;
CREATE POLICY "allow_all_super_admins" ON super_admins FOR ALL USING (true) WITH CHECK (true);

-- Insert you as super admin
INSERT INTO super_admins (email, name)
VALUES ('imadaehn@gmail.com', 'Super Admin')
ON CONFLICT (email) DO NOTHING;
