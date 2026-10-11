-- ============================================================
-- BVCEC SmartQueue — Supabase Database Schema
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  registration_number TEXT UNIQUE NOT NULL,
  full_name    TEXT NOT NULL,
  role         TEXT NOT NULL DEFAULT 'student'
                 CHECK (role IN ('student', 'staff', 'admin')),
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- 3. Service Centers
CREATE TABLE public.service_centers (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Seed data: candidate service centers (PROTOTYPE ASSUMPTION)
INSERT INTO public.service_centers (name, description) VALUES
  ('Examination Section', 'Handles hall tickets, transcripts, re-evaluations and results'),
  ('Administration', 'General administrative services and correspondence'),
  ('Accounts', 'Fee payments, scholarships and financial queries'),
  ('Library', 'Book issue, return, ID card and reference queries'),
  ('Department Office', 'Department-level student services and records');

-- 4. Services
CREATE TABLE public.services (
  id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_center_id           UUID NOT NULL REFERENCES public.service_centers(id) ON DELETE CASCADE,
  name                        TEXT NOT NULL,
  description                 TEXT NOT NULL DEFAULT '',
  -- PROTOTYPE ASSUMPTION: estimated_duration_minutes is a placeholder.
  -- Update based on actual service data collected during pilot.
  estimated_duration_minutes  INT NOT NULL DEFAULT 10,
  is_active                   BOOLEAN NOT NULL DEFAULT true
);

-- Seed: Examination Section services (PROTOTYPE ASSUMPTION)
INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Hall Ticket Collection', 'Collect examination hall ticket', 5
FROM public.service_centers WHERE name = 'Examination Section';

INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Transcript Request', 'Apply for official transcript', 10
FROM public.service_centers WHERE name = 'Examination Section';

INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Re-evaluation Application', 'Submit re-evaluation request', 8
FROM public.service_centers WHERE name = 'Examination Section';

-- Seed: Library services
INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Book Issue', 'Issue a book from the library', 5
FROM public.service_centers WHERE name = 'Library';

INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Book Return', 'Return an issued book', 3
FROM public.service_centers WHERE name = 'Library';

-- Seed: Accounts services
INSERT INTO public.services (service_center_id, name, description, estimated_duration_minutes)
SELECT id, 'Fee Payment', 'Pay semester or other fees', 15
FROM public.service_centers WHERE name = 'Accounts';

-- 5. Counters
CREATE TABLE public.counters (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_center_id  UUID NOT NULL REFERENCES public.service_centers(id) ON DELETE CASCADE,
  name               TEXT NOT NULL,
  status             TEXT NOT NULL DEFAULT 'offline'
                       CHECK (status IN ('available', 'serving', 'paused', 'offline')),
  assigned_staff_id  UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- 6. Queues (one per service per day)
CREATE TABLE public.queues (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_center_id UUID NOT NULL REFERENCES public.service_centers(id) ON DELETE CASCADE,
  service_id        UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  date              DATE NOT NULL,
  is_open           BOOLEAN NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT now(),
  UNIQUE (service_id, date)
);

-- 7. Queue Entries
CREATE TABLE public.queue_entries (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  queue_id               UUID NOT NULL REFERENCES public.queues(id) ON DELETE CASCADE,
  user_id                UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id             UUID NOT NULL REFERENCES public.services(id),
  token_number           INT NOT NULL,
  status                 TEXT NOT NULL DEFAULT 'waiting'
                           CHECK (status IN ('waiting', 'called', 'serving', 'completed',
                                             'cancelled', 'no_show', 'transferred')),
  priority               INT NOT NULL DEFAULT 0,
  joined_at              TIMESTAMPTZ DEFAULT now(),
  called_at              TIMESTAMPTZ,
  service_started_at     TIMESTAMPTZ,
  completed_at           TIMESTAMPTZ,
  counter_id             UUID REFERENCES public.counters(id),
  estimated_wait_minutes INT,
  UNIQUE (queue_id, token_number)
);

-- 8. Queue Events (audit log)
CREATE TABLE public.queue_events (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  queue_entry_id  UUID NOT NULL REFERENCES public.queue_entries(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL
                    CHECK (event_type IN ('joined', 'called', 'serving', 'completed',
                                          'cancelled', 'no_show', 'transferred')),
  actor_id        UUID NOT NULL REFERENCES public.users(id),
  occurred_at     TIMESTAMPTZ DEFAULT now(),
  notes           TEXT
);

-- 9. Service Sessions
CREATE TABLE public.service_sessions (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  queue_entry_id           UUID NOT NULL REFERENCES public.queue_entries(id) ON DELETE CASCADE,
  counter_id               UUID NOT NULL REFERENCES public.counters(id),
  staff_id                 UUID NOT NULL REFERENCES public.users(id),
  service_id               UUID NOT NULL REFERENCES public.services(id),
  started_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at             TIMESTAMPTZ,
  actual_duration_minutes  INT
);

-- 10. EWT Stats (adaptive running average per service)
CREATE TABLE public.ewt_stats (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_id               UUID NOT NULL UNIQUE REFERENCES public.services(id) ON DELETE CASCADE,
  average_duration_minutes FLOAT NOT NULL DEFAULT 10.0,
  sample_count             INT NOT NULL DEFAULT 0,
  last_updated             TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ewt_stats ENABLE ROW LEVEL SECURITY;

-- Helper: get current user role
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL STABLE
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

-- users: users can read their own profile; admins can read all
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (id = auth.uid() OR public.get_my_role() = 'admin');

CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT WITH CHECK (id = auth.uid());

-- service_centers: everyone can read active ones; only admin can write
CREATE POLICY "sc_select_all" ON public.service_centers
  FOR SELECT USING (is_active = true OR public.get_my_role() = 'admin');

CREATE POLICY "sc_write_admin" ON public.service_centers
  FOR ALL USING (public.get_my_role() = 'admin');

-- services: everyone reads active; admin writes
CREATE POLICY "svc_select_all" ON public.services
  FOR SELECT USING (is_active = true OR public.get_my_role() = 'admin');

CREATE POLICY "svc_write_admin" ON public.services
  FOR ALL USING (public.get_my_role() = 'admin');

-- counters: everyone reads; admin and staff write
CREATE POLICY "cnt_select_all" ON public.counters
  FOR SELECT USING (true);

CREATE POLICY "cnt_write_staff_admin" ON public.counters
  FOR ALL USING (public.get_my_role() IN ('staff', 'admin'));

-- queues: everyone reads; staff/admin write
CREATE POLICY "queue_select_all" ON public.queues
  FOR SELECT USING (true);

CREATE POLICY "queue_write_staff" ON public.queues
  FOR ALL USING (public.get_my_role() IN ('staff', 'admin'));

-- queue_entries: students see own; staff/admin see all
CREATE POLICY "qe_select" ON public.queue_entries
  FOR SELECT USING (
    user_id = auth.uid() OR public.get_my_role() IN ('staff', 'admin')
  );

CREATE POLICY "qe_insert_student" ON public.queue_entries
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "qe_update_staff" ON public.queue_entries
  FOR UPDATE USING (public.get_my_role() IN ('staff', 'admin'));

CREATE POLICY "qe_update_cancel" ON public.queue_entries
  FOR UPDATE USING (user_id = auth.uid() AND status = 'waiting');

-- queue_events: everyone can read own entries' events
CREATE POLICY "qev_select" ON public.queue_events
  FOR SELECT USING (true);

CREATE POLICY "qev_insert" ON public.queue_events
  FOR INSERT WITH CHECK (actor_id = auth.uid());

-- service_sessions: staff/admin only
CREATE POLICY "ss_select" ON public.service_sessions
  FOR SELECT USING (public.get_my_role() IN ('staff', 'admin'));

CREATE POLICY "ss_write" ON public.service_sessions
  FOR ALL USING (public.get_my_role() IN ('staff', 'admin'));

-- ewt_stats: everyone reads; staff/admin write
CREATE POLICY "ewt_select" ON public.ewt_stats FOR SELECT USING (true);
CREATE POLICY "ewt_write" ON public.ewt_stats
  FOR ALL USING (public.get_my_role() IN ('staff', 'admin'));

-- ============================================================
-- Realtime: enable for live queue updates
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.counters;
ALTER PUBLICATION supabase_realtime ADD TABLE public.queues;

-- ============================================================
-- Indexes for performance
-- ============================================================
CREATE INDEX idx_queue_entries_queue_id ON public.queue_entries(queue_id);
CREATE INDEX idx_queue_entries_user_id ON public.queue_entries(user_id);
CREATE INDEX idx_queue_entries_status ON public.queue_entries(status);
CREATE INDEX idx_queues_service_date ON public.queues(service_id, date);
CREATE INDEX idx_queue_events_entry_id ON public.queue_events(queue_entry_id);
