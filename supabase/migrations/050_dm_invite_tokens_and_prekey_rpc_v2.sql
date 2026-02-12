-- Phase 14 / Signal Protocol: DM invite tokens + expanded prekey fetch eligibility (v2)
--
-- Adds:
-- - dm_invite_tokens: explicit “door” for starting a DM outside shared community membership.
-- - create_dm_invite_token_v1(): generates an invite token for the current user.
-- - Updates get_signal_prekey_bundle_v2() to accept an invite token as an alternative eligibility proof.
--
-- Design goal:
-- - Avoid open-directory prekey access
-- - Allow intentional “I want to talk to you” flows without requiring shared community.

create table if not exists public.dm_invite_tokens (
  token uuid primary key default gen_random_uuid(),
  target_user_id uuid not null references auth.users(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  consumed_by uuid references auth.users(id) on delete set null,
  consumed_at timestamptz
);

alter table public.dm_invite_tokens enable row level security;

-- Creator/target can view their own tokens.
drop policy if exists dm_invite_tokens_select_own on public.dm_invite_tokens;
create policy dm_invite_tokens_select_own
  on public.dm_invite_tokens
  for select
  to authenticated
  using (auth.uid() = target_user_id);

-- Target user can create tokens for themselves.
drop policy if exists dm_invite_tokens_insert_own on public.dm_invite_tokens;
create policy dm_invite_tokens_insert_own
  on public.dm_invite_tokens
  for insert
  to authenticated
  with check (
    auth.uid() is not null
    and auth.uid() = target_user_id
    and auth.uid() = created_by
  );

-- Target user can revoke (delete) their tokens.
drop policy if exists dm_invite_tokens_delete_own on public.dm_invite_tokens;
create policy dm_invite_tokens_delete_own
  on public.dm_invite_tokens
  for delete
  to authenticated
  using (auth.uid() = target_user_id);

create index if not exists idx_dm_invite_tokens_target_expires
  on public.dm_invite_tokens (target_user_id, expires_at desc);

-- Create invite token RPC
create or replace function public.create_dm_invite_token_v1(
  expires_in_seconds int default 604800 -- 7 days
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  tok uuid;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated';
  end if;

  insert into public.dm_invite_tokens (target_user_id, created_by, expires_at)
  values (
    auth.uid(),
    auth.uid(),
    now() + make_interval(secs => greatest(60, expires_in_seconds))
  )
  returning token into tok;

  return tok;
end;
$$;

revoke all on function public.create_dm_invite_token_v1(int) from public;
grant execute on function public.create_dm_invite_token_v1(int) to authenticated;

-- Update prekey RPC to accept invite token
drop function if exists public.get_signal_prekey_bundle_v2(uuid, int);
create or replace function public.get_signal_prekey_bundle_v2(
  p_target_user_id uuid,
  target_device_id int default 1,
  invite_token uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  bundle jsonb;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated';
  end if;

  if p_target_user_id is null then
    raise exception 'target_user_id required';
  end if;

  if auth.uid() <> p_target_user_id then
    -- Eligibility path A: shared community membership
    if exists (
      select 1
      from public.community_memberships a
      join public.community_memberships b
        on b.community_id = a.community_id
      where a.user_id = auth.uid()
        and b.user_id = p_target_user_id
    ) then
      -- ok
    else
      -- Eligibility path B: explicit DM invite token
      if invite_token is null then
        raise exception 'not eligible to fetch prekey bundle';
      end if;

      if not exists (
        select 1
        from public.dm_invite_tokens t
        where t.token = invite_token
          and t.target_user_id = p_target_user_id
          and t.expires_at > now()
          and (t.consumed_by is null or t.consumed_by = auth.uid())
      ) then
        raise exception 'invalid or expired invite token';
      end if;

      -- Mark consumed (idempotent for same user).
      update public.dm_invite_tokens
        set consumed_by = auth.uid(),
            consumed_at = coalesce(consumed_at, now())
      where token = invite_token
        and target_user_id = p_target_user_id;
    end if;
  end if;

  select s.prekey_bundle_json
    into bundle
  from public.signal_prekey_bundles_v2 s
  where s.user_id = p_target_user_id
    and s.device_id = target_device_id
    and s.consumed = false
    and s.expires_at > now()
  order by s.created_at desc
  limit 1;

  if bundle is null then
    raise exception 'prekey bundle not found';
  end if;

  return bundle;
end;
$$;

revoke all on function public.get_signal_prekey_bundle_v2(uuid, int, uuid) from public;
grant execute on function public.get_signal_prekey_bundle_v2(uuid, int, uuid) to authenticated;

