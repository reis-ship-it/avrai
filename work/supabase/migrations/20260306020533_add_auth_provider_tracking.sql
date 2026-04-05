-- Add lightweight auth provider/platform tracking for beta launch analytics.

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS signup_provider TEXT,
    ADD COLUMN IF NOT EXISTS last_sign_in_provider TEXT,
    ADD COLUMN IF NOT EXISTS last_sign_in_platform TEXT,
    ADD COLUMN IF NOT EXISTS last_sign_in_at TIMESTAMPTZ;

UPDATE public.users
SET signup_provider = 'email'
WHERE signup_provider IS NULL
  AND email IS NOT NULL;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  email_col_exists boolean;
  name_col_exists boolean;
  signup_provider_col_exists boolean;
  resolved_signup_provider text;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'email'
  ) INTO email_col_exists;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'name'
  ) INTO name_col_exists;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'signup_provider'
  ) INTO signup_provider_col_exists;

  resolved_signup_provider := COALESCE(
    NEW.raw_user_meta_data->>'signup_provider',
    NEW.raw_app_meta_data->>'provider',
    CASE WHEN NEW.email IS NOT NULL THEN 'email' ELSE NULL END
  );

  IF email_col_exists AND name_col_exists AND signup_provider_col_exists THEN
    INSERT INTO public.users (id, email, name, signup_provider)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', ''),
      resolved_signup_provider
    );
  ELSIF email_col_exists AND name_col_exists THEN
    INSERT INTO public.users (id, email, name)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', ''));
  ELSIF email_col_exists THEN
    INSERT INTO public.users (id, email)
    VALUES (NEW.id, NEW.email);
  ELSE
    INSERT INTO public.users (id)
    VALUES (NEW.id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;;
