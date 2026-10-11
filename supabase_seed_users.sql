-- ============================================================
-- BVCEC SmartQueue — Seed Users & Counters
-- Run this script in your Supabase Project:
-- Dashboard -> SQL Editor -> New Query -> Run
-- ============================================================

-- Ensure pgcrypto extension is active for password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
DECLARE
  v_admin_id UUID := gen_random_uuid();
  v_staff1_id UUID := gen_random_uuid();
  v_staff2_id UUID := gen_random_uuid();
  v_student_id UUID := gen_random_uuid();
  v_exam_center_id UUID;
  v_accounts_center_id UUID;
  v_library_center_id UUID;
BEGIN
  -- Retrieve existing service center IDs
  SELECT id INTO v_exam_center_id FROM public.service_centers WHERE name = 'Examination Section' LIMIT 1;
  SELECT id INTO v_accounts_center_id FROM public.service_centers WHERE name = 'Accounts' LIMIT 1;
  SELECT id INTO v_library_center_id FROM public.service_centers WHERE name = 'Library' LIMIT 1;

  -- 1. Create ADMIN User (ADMIN001 / password123)
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE registration_number = 'ADMIN001') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_admin_id, 'authenticated', 'authenticated',
      'admin001@bvcec.internal',
      crypt('password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Campus Administrator","role":"admin"}'::jsonb,
      now(), now(),
      '', '', '', '', '', '', '', ''
    );
    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_admin_id, jsonb_build_object('sub', v_admin_id::text, 'email', 'admin001@bvcec.internal'), 'email', 'admin001@bvcec.internal', now(), now(), now());
    INSERT INTO public.users (id, registration_number, full_name, role)
    VALUES (v_admin_id, 'ADMIN001', 'Campus Administrator', 'admin')
    ON CONFLICT (id) DO NOTHING;
  ELSE
    SELECT id INTO v_admin_id FROM public.users WHERE registration_number = 'ADMIN001';
  END IF;

  -- 2. Create STAFF 1 User (STAFF001 / password123) - Examination Section
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE registration_number = 'STAFF001') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_staff1_id, 'authenticated', 'authenticated',
      'staff001@bvcec.internal',
      crypt('password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Exam Section Staff","role":"staff"}'::jsonb,
      now(), now(),
      '', '', '', '', '', '', '', ''
    );
    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_staff1_id, jsonb_build_object('sub', v_staff1_id::text, 'email', 'staff001@bvcec.internal'), 'email', 'staff001@bvcec.internal', now(), now(), now());
    INSERT INTO public.users (id, registration_number, full_name, role)
    VALUES (v_staff1_id, 'STAFF001', 'Exam Section Staff', 'staff')
    ON CONFLICT (id) DO NOTHING;
  ELSE
    SELECT id INTO v_staff1_id FROM public.users WHERE registration_number = 'STAFF001';
  END IF;

  -- 3. Create STAFF 2 User (STAFF002 / password123) - Accounts Section
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE registration_number = 'STAFF002') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_staff2_id, 'authenticated', 'authenticated',
      'staff002@bvcec.internal',
      crypt('password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Accounts Section Staff","role":"staff"}'::jsonb,
      now(), now(),
      '', '', '', '', '', '', '', ''
    );
    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_staff2_id, jsonb_build_object('sub', v_staff2_id::text, 'email', 'staff002@bvcec.internal'), 'email', 'staff002@bvcec.internal', now(), now(), now());
    INSERT INTO public.users (id, registration_number, full_name, role)
    VALUES (v_staff2_id, 'STAFF002', 'Accounts Section Staff', 'staff')
    ON CONFLICT (id) DO NOTHING;
  ELSE
    SELECT id INTO v_staff2_id FROM public.users WHERE registration_number = 'STAFF002';
  END IF;

  -- 4. Create STUDENT User (22A61A0501 / password123)
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE registration_number = '22A61A0501') THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_student_id, 'authenticated', 'authenticated',
      '22a61a0501@bvcec.internal',
      crypt('password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Prajwal Varma","role":"student"}'::jsonb,
      now(), now(),
      '', '', '', '', '', '', '', ''
    );
    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_student_id, jsonb_build_object('sub', v_student_id::text, 'email', '22a61a0501@bvcec.internal'), 'email', '22a61a0501@bvcec.internal', now(), now(), now());
    INSERT INTO public.users (id, registration_number, full_name, role)
    VALUES (v_student_id, '22A61A0501', 'Prajwal Varma', 'student')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- 5. Seed Initial Counters if not present
  IF v_exam_center_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.counters WHERE service_center_id = v_exam_center_id AND name = 'Counter 1') THEN
      INSERT INTO public.counters (service_center_id, name, status, assigned_staff_id)
      VALUES (v_exam_center_id, 'Counter 1', 'available', v_staff1_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.counters WHERE service_center_id = v_exam_center_id AND name = 'Counter 2') THEN
      INSERT INTO public.counters (service_center_id, name, status, assigned_staff_id)
      VALUES (v_exam_center_id, 'Counter 2', 'available', NULL);
    END IF;
  END IF;

  IF v_accounts_center_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.counters WHERE service_center_id = v_accounts_center_id AND name = 'Fee Counter A') THEN
      INSERT INTO public.counters (service_center_id, name, status, assigned_staff_id)
      VALUES (v_accounts_center_id, 'Fee Counter A', 'available', v_staff2_id);
    END IF;
  END IF;

  IF v_library_center_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.counters WHERE service_center_id = v_library_center_id AND name = 'Circulation Desk') THEN
      INSERT INTO public.counters (service_center_id, name, status, assigned_staff_id)
      VALUES (v_library_center_id, 'Circulation Desk', 'available', NULL);
    END IF;
  END IF;

END $$;
