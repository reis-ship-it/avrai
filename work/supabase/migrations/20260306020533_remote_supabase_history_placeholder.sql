-- Remote history placeholder.
-- This no-op migration preserves an already-recorded remote migration version
-- so local migration lineage stays aligned with the linked Supabase project.
-- The underlying remote schema changes were already present before this repo
-- state was checked out; do not remove this file unless the remote history is
-- explicitly repaired and documented.

select 1;
