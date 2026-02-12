-- Phase 14 / Signal Protocol: Eligibility-gated prekey bundle fetch (v2)
--
-- IMPORTANT:
-- - We do NOT allow open directory reads on `signal_prekey_bundles_v2`.
-- - Clients fetch another user's bundle through this RPC, which enforces SPOTS eligibility.
--
-- Eligibility (v1, minimal but safe for community + sender-key sharing):
-- - Caller is the same user, OR
-- - Caller and target share at least one `community_memberships.community_id`.
--
-- This is intentionally narrow: it enables community sender-key distribution (group chat)
-- without turning the key server into a global directory.

create or replace function public.get_signal_prekey_bundle_v2(
  target_user_id uuid,
  target_device_id int default 1
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

  if target_user_id is null then
    raise exception 'target_user_id required';
  end if;

  if auth.uid() <> target_user_id then
    if not exists (
      select 1
      from public.community_memberships a
      join public.community_memberships b
        on b.community_id = a.community_id
      where a.user_id = auth.uid()
        and b.user_id = target_user_id
    ) then
      raise exception 'not eligible to fetch prekey bundle';
    end if;
  end if;

  select s.prekey_bundle_json
    into bundle
  from public.signal_prekey_bundles_v2 s
  where s.user_id = target_user_id
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

revoke all on function public.get_signal_prekey_bundle_v2(uuid, int) from public;
grant execute on function public.get_signal_prekey_bundle_v2(uuid, int) to authenticated;

