-- Ensure public.users has required columns for signup trigger
DO $$
BEGIN
  -- email column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'email'
  ) THEN
    ALTER TABLE public.users ADD COLUMN email text;
  END IF;
  
  -- name column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'name'
  ) THEN
    ALTER TABLE public.users ADD COLUMN name text;
  END IF;
  
  -- created_at column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.users ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;
  
  -- updated_at column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.users ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Unique index on email if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'ux_users_email'
  ) THEN
    CREATE UNIQUE INDEX ux_users_email ON public.users (email);
  END IF;
END $$;


