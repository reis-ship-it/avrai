-- Make signup trigger resilient to schema differences in public.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  email_col_exists boolean;
  name_col_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'email'
  ) INTO email_col_exists;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'name'
  ) INTO name_col_exists;

  IF email_col_exists AND name_col_exists THEN
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
$$ LANGUAGE plpgsql SECURITY DEFINER;


