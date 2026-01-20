-- Create app_config table for remote configuration
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Turn on RLS
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Allow anyone (anon and authenticated) to READ config
-- We might restrict this to authenticated later if needed, but for now app needs it.
CREATE POLICY "Allow public read access"
ON app_config FOR SELECT
USING (true);

-- Only service_role (admins) can INSERT/UPDATE/DELETE. 
-- No policies needed for write as default is deny.

-- Insert default configuration
-- we store the number simply as a JSON number
INSERT INTO app_config (key, value)
VALUES ('insight_entry_limit', '20'::jsonb)
ON CONFLICT (key) DO NOTHING;
