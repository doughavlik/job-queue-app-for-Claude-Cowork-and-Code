-- ================================================================
-- Job Queue Manager (36074) — Supabase setup
-- Run this in the Supabase SQL editor
-- All objects are prefixed with 36074_ to avoid conflicts with
-- other apps (e.g. Job Scout) in the same project.
-- ================================================================

-- 1. Create the jobs table
CREATE TABLE IF NOT EXISTS "36074_jobs" (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  queue      text        NOT NULL CHECK (queue IN ('cowork', 'code')),
  body       text        NOT NULL,
  status     text        NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'done')),
  position   integer     NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Index for fast queue reads (used by Claude scheduled tasks)
CREATE INDEX IF NOT EXISTS "36074_jobs_queue_status_position"
  ON "36074_jobs" (queue, status, position);

-- 3. Auto-update updated_at on row changes
CREATE OR REPLACE FUNCTION "36074_update_updated_at"()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "36074_jobs_updated_at" ON "36074_jobs";
CREATE TRIGGER "36074_jobs_updated_at"
  BEFORE UPDATE ON "36074_jobs"
  FOR EACH ROW EXECUTE FUNCTION "36074_update_updated_at"();

-- 4. Enable Row Level Security
ALTER TABLE "36074_jobs" ENABLE ROW LEVEL SECURITY;

-- 5. RLS policy: authenticated users get full CRUD
CREATE POLICY "36074_authenticated_full_access" ON "36074_jobs"
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ================================================================
-- Claude scheduled tasks access the table using the service role
-- key (bypasses RLS). No extra policy needed for service role.
--
-- Example REST calls for scheduled tasks:
--
--   Read todo jobs (cowork queue):
--   GET /rest/v1/36074_jobs?queue=eq.cowork&status=eq.todo&order=position
--   Headers: apikey: <service_role_key>, Authorization: Bearer <service_role_key>
--
--   Read todo jobs (code queue):
--   GET /rest/v1/36074_jobs?queue=eq.code&status=eq.todo&order=position
--   Headers: apikey: <service_role_key>, Authorization: Bearer <service_role_key>
--
--   Mark a job done:
--   PATCH /rest/v1/36074_jobs?id=eq.<job-uuid>
--   Body: {"status": "done"}
--   Headers: apikey: <service_role_key>, Authorization: Bearer <service_role_key>,
--            Content-Type: application/json, Prefer: return=minimal
-- ================================================================
