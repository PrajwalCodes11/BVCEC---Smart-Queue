-- ============================================================
-- BVCEC SmartQueue — Complete Permissions, Auth & Queue Fix
-- Run this in Supabase Dashboard -> SQL Editor -> Run
-- ============================================================

-- 1. Repair NULL token columns in auth.users that break GoTrue scanner
DO $$
DECLARE
  col TEXT;
  cols TEXT[] := ARRAY[
    'confirmation_token',
    'recovery_token',
    'email_change_token_new',
    'email_change',
    'email_change_token_current',
    'phone_change',
    'phone_change_token',
    'reauthentication_token'
  ];
BEGIN
  FOREACH col IN ARRAY cols LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = col
    ) THEN
      EXECUTE format('UPDATE auth.users SET %I = '''' WHERE %I IS NULL', col, col);
    END IF;
  END LOOP;
END $$;

-- 2. Grant table-level access to authenticated and anon roles (required for PostgREST)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated;

-- 3. Prevent RLS infinite recursion on public.users
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

DROP POLICY IF EXISTS "users_select_own" ON public.users;
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (id = auth.uid() OR public.get_my_role() = 'admin');

-- 4. Allow students and staff to access and create queues
DROP POLICY IF EXISTS "queue_write_staff" ON public.queues;
DROP POLICY IF EXISTS "queue_select_all" ON public.queues;
DROP POLICY IF EXISTS "queue_insert_all" ON public.queues;
DROP POLICY IF EXISTS "queue_update_staff" ON public.queues;

CREATE POLICY "queue_select_all" ON public.queues
  FOR SELECT USING (true);

CREATE POLICY "queue_insert_all" ON public.queues
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "queue_update_staff" ON public.queues
  FOR UPDATE USING (public.get_my_role() IN ('staff', 'admin'));

-- Helper RPC for atomic get-or-create of today's queue
CREATE OR REPLACE FUNCTION public.get_or_create_today_queue(
  p_service_center_id UUID,
  p_service_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_queue RECORD;
BEGIN
  SELECT * INTO v_queue
  FROM public.queues
  WHERE service_id = p_service_id AND date = p_date
  LIMIT 1;

  IF v_queue.id IS NULL THEN
    INSERT INTO public.queues (service_center_id, service_id, date, is_open)
    VALUES (p_service_center_id, p_service_id, p_date, true)
    RETURNING * INTO v_queue;
  END IF;

  RETURN to_jsonb(v_queue);
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_or_create_today_queue(UUID, UUID, DATE) TO anon, authenticated;

-- 5. Queue entries: public read of line positions, student insert of own entry, staff update
DROP POLICY IF EXISTS "qe_select" ON public.queue_entries;
DROP POLICY IF EXISTS "qe_insert_student" ON public.queue_entries;
DROP POLICY IF EXISTS "qe_update_staff" ON public.queue_entries;
DROP POLICY IF EXISTS "qe_update_cancel" ON public.queue_entries;

CREATE POLICY "qe_select" ON public.queue_entries
  FOR SELECT USING (true);

CREATE POLICY "qe_insert_student" ON public.queue_entries
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "qe_update_staff" ON public.queue_entries
  FOR UPDATE USING (public.get_my_role() IN ('staff', 'admin'));

-- Allows student to cancel their own waiting ticket
CREATE POLICY "qe_update_cancel" ON public.queue_entries
  FOR UPDATE
  USING (user_id = auth.uid() AND status = 'waiting')
  WITH CHECK (user_id = auth.uid() AND status = 'cancelled');

-- Allows admin to delete test/stale entries
DROP POLICY IF EXISTS "qe_delete_admin" ON public.queue_entries;
CREATE POLICY "qe_delete_admin" ON public.queue_entries
  FOR DELETE USING (public.get_my_role() = 'admin');

-- RPC helper for secure student cancellation
CREATE OR REPLACE FUNCTION public.cancel_my_queue_entry(p_entry_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_entry RECORD;
BEGIN
  UPDATE public.queue_entries
  SET status = 'cancelled'
  WHERE id = p_entry_id
    AND user_id = auth.uid()
    AND status = 'waiting'
  RETURNING * INTO v_entry;

  IF v_entry.id IS NOT NULL THEN
    INSERT INTO public.queue_events (queue_entry_id, event_type, actor_id, occurred_at)
    VALUES (p_entry_id, 'cancelled', auth.uid(), NOW());
    RETURN to_jsonb(v_entry);
  ELSE
    RAISE EXCEPTION 'Queue entry not found or cannot be cancelled';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.cancel_my_queue_entry(UUID) TO authenticated;

-- 6. Queue events audit log: allow insert for event actors
DROP POLICY IF EXISTS "qev_select" ON public.queue_events;
DROP POLICY IF EXISTS "qev_insert" ON public.queue_events;
DROP POLICY IF EXISTS "qev_delete_admin" ON public.queue_events;

CREATE POLICY "qev_select" ON public.queue_events
  FOR SELECT USING (true);

CREATE POLICY "qev_insert" ON public.queue_events
  FOR INSERT WITH CHECK (actor_id = auth.uid());

CREATE POLICY "qev_delete_admin" ON public.queue_events
  FOR DELETE USING (public.get_my_role() = 'admin');

-- 7. Verify users
SELECT u.id, u.registration_number, u.full_name, u.role, a.email
FROM public.users u
JOIN auth.users a ON a.id = u.id;
