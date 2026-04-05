-- Lock down public place tables flagged by the Supabase database linter.
--
-- `claimed_places` exists in local migrations, so this migration also supplies
-- the explicit service-role policy required by the new edge-function path.
--
-- `spot_aliases` and `place_corrections` currently exist in the linked remote
-- database but their full table DDL is not present in this repository. Keep the
-- hardening idempotent so remote applies cleanly without breaking local resets
-- where those tables may not exist yet.

DO $$
BEGIN
  IF to_regclass('public.claimed_places') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.claimed_places ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Service role can manage claimed_places" ON public.claimed_places';
    EXECUTE $policy$
      CREATE POLICY "Service role can manage claimed_places"
      ON public.claimed_places
      FOR ALL
      USING ((SELECT auth.role()) = 'service_role')
      WITH CHECK ((SELECT auth.role()) = 'service_role')
    $policy$;
  END IF;
END
$$;

DO $$
BEGIN
  IF to_regclass('public.spot_aliases') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.spot_aliases ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Service role can manage spot_aliases" ON public.spot_aliases';
    EXECUTE $policy$
      CREATE POLICY "Service role can manage spot_aliases"
      ON public.spot_aliases
      FOR ALL
      USING ((SELECT auth.role()) = 'service_role')
      WITH CHECK ((SELECT auth.role()) = 'service_role')
    $policy$;
  END IF;
END
$$;

DO $$
BEGIN
  IF to_regclass('public.place_corrections') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.place_corrections ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Service role can manage place_corrections" ON public.place_corrections';
    EXECUTE $policy$
      CREATE POLICY "Service role can manage place_corrections"
      ON public.place_corrections
      FOR ALL
      USING ((SELECT auth.role()) = 'service_role')
      WITH CHECK ((SELECT auth.role()) = 'service_role')
    $policy$;
  END IF;
END
$$;
