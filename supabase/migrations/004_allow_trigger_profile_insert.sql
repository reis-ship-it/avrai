-- Allow auth.users creation trigger to insert into public.users
-- The trigger runs as a privileged role; RLS can block it. This policy permits inserts when executed by postgres.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Allow trigger inserts into users'
  ) THEN
    CREATE POLICY "Allow trigger inserts into users"
    ON public.users
    FOR INSERT
    WITH CHECK (current_user = 'postgres' OR auth.uid() = id);
  END IF;
END $$;


