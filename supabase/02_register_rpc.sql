-- ============================================================
-- BVCEC SmartQueue — Complete Registration, Sign-In & Repair RPC
-- Run this script in Supabase Dashboard:
-- Dashboard -> SQL Editor -> New Query -> Paste -> Run
-- ============================================================

-- Step 1: Repair missing identities for existing accounts (e.g., 24221A4562)
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.id::text,
  now(),
  now(),
  now()
FROM auth.users u
WHERE u.id NOT IN (SELECT user_id FROM auth.identities)
ON CONFLICT DO NOTHING;

-- Step 2: Enable pgcrypto for secure password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Step 3: Add UPDATE policy on public.users so users can edit their profile
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' AND policyname = 'users_update_own'
  ) THEN
    CREATE POLICY "users_update_own" ON public.users
      FOR UPDATE USING (id = auth.uid() OR public.get_my_role() = 'admin');
  END IF;
END $$;

-- Step 4: Stored procedure: Instant User Registration with GoTrue identities
CREATE OR REPLACE FUNCTION public.register_new_user(
  p_email TEXT,
  p_password TEXT,
  p_registration_number TEXT,
  p_full_name TEXT,
  p_role TEXT,
  p_department TEXT DEFAULT NULL,
  p_year_of_study TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_meta JSONB;
  v_reg_no TEXT := UPPER(TRIM(p_registration_number));
  v_clean_email TEXT := LOWER(TRIM(p_email));
BEGIN
  -- Validate role
  IF p_role NOT IN ('student', 'staff') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  -- Check if registration number already exists
  IF EXISTS (SELECT 1 FROM public.users WHERE registration_number = v_reg_no) THEN
    RAISE EXCEPTION 'Registration Number or Staff ID "%" already exists.', v_reg_no;
  END IF;

  -- Check if email already exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_clean_email) THEN
    RAISE EXCEPTION 'Email address "%" is already registered.', v_clean_email;
  END IF;

  -- Build metadata JSON
  v_meta := jsonb_build_object(
    'full_name', TRIM(p_full_name),
    'registration_number', v_reg_no,
    'role', p_role,
    'department', COALESCE(p_department, ''),
    'year_of_study', COALESCE(p_year_of_study, ''),
    'college_email', v_clean_email,
    'phone', COALESCE(p_phone, '')
  );

  -- Insert directly into auth.users.
  -- IMPORTANT: All token columns must be '' (empty string), NOT NULL.
  -- GoTrue will throw "Database error querying schema" if any are NULL.
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at,           -- confirmed_at is generated, do NOT include it
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    -- Token columns MUST be empty string, not NULL
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_clean_email,
    crypt(p_password, gen_salt('bf')),
    now(),                        -- email_confirmed_at (confirmed_at auto-derives from this)
    '{"provider":"email","providers":["email"]}'::jsonb,
    v_meta,
    now(), now(),
    '', '', '', '', '', '', '', ''
  );

  -- Insert required identity into auth.identities for GoTrue sign-in.
  -- provider_id MUST be the email address for the 'email' provider.
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_clean_email),
    'email',
    v_clean_email,   -- must be email, not UUID
    now(),
    now(),
    now()
  );

  -- Insert into public.users
  INSERT INTO public.users (id, registration_number, full_name, role)
  VALUES (v_user_id, v_reg_no, TRIM(p_full_name), p_role);

  RETURN jsonb_build_object(
    'id', v_user_id,
    'registration_number', v_reg_no,
    'full_name', TRIM(p_full_name),
    'role', p_role,
    'department', p_department,
    'year_of_study', p_year_of_study,
    'email', v_clean_email,
    'phone', p_phone
  );
END;
$$;

-- Step 5: Stored procedure: Resolve user's email from either Email OR ID
CREATE OR REPLACE FUNCTION public.get_email_for_identifier(p_identifier TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id TEXT := TRIM(p_identifier);
  v_found_email TEXT;
BEGIN
  -- 1. If it's directly an email in auth.users
  SELECT email INTO v_found_email
  FROM auth.users
  WHERE email = LOWER(v_id)
  LIMIT 1;

  IF v_found_email IS NOT NULL THEN
    RETURN v_found_email;
  END IF;

  -- 2. Lookup by registration_number in public.users -> auth.users
  SELECT au.email INTO v_found_email
  FROM public.users u
  JOIN auth.users au ON au.id = u.id
  WHERE u.registration_number ILIKE v_id
  LIMIT 1;

  IF v_found_email IS NOT NULL THEN
    RETURN v_found_email;
  END IF;

  -- 3. Default fallback for existing seed users
  IF NOT v_id LIKE '%@%' THEN
    RETURN LOWER(v_id) || '@bvcec.internal';
  END IF;

  RETURN LOWER(v_id);
END;
$$;
