-- Apply on databases where DATABASE_SYNCHRONIZE is disabled.
ALTER TABLE barbershops
  ADD COLUMN IF NOT EXISTS phone varchar(11),
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS "openingHours" jsonb NOT NULL DEFAULT '[]'::jsonb;
