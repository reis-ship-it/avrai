alter table public.users add column if not exists is_beta_tester boolean default false; update public.users set is_beta_tester = true where is_beta_tester is distinct from true;;
