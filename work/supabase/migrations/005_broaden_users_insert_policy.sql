-- Broaden policy so auth.users -> public.users trigger can insert under RLS
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Allow trigger inserts into users'
  ) THEN
    DROP POLICY "Allow trigger inserts into users" ON public.users;
  END IF;
END $$;

CREATE POLICY "Allow trigger inserts into users"
ON public.users
FOR INSERT
WITH CHECK (
  -- normal app insert
  auth.uid() = id
  OR
  -- inserts via internal triggers/privileged roles
  current_user IN ('postgres','supabase_admin','authenticator','service_role')
  OR
  coalesce(auth.role(), '') = 'service_role'
);


