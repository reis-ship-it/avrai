-- Add is_beta_tester column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_beta_tester BOOLEAN DEFAULT false;
-- Set all existing users (who are by definition beta testers) to true
UPDATE public.users SET is_beta_tester = true;
