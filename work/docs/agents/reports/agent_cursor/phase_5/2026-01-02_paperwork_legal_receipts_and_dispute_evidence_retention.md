## Agent Cursor — Phase 5 — Paperwork: Legal receipts + dispute evidence retention (2026-01-02)

### Goal
Connect “legal side” artifacts into a **kept + auditable** loop:
- **Kept**: retention-locked uploads (no overwrite, no delete)
- **Auditable**: ledger receipts (tamper-evident, signed when available) + minimal “receipts UI”

### What shipped (high signal)

#### 1) Legal acceptances are connected (text → hash → receipt)
- **Terms / Privacy / Waiver acceptance**
  - **Local durability**: persisted into `StorageService` so acceptances survive app restart.
  - **Ledger receipts**: appended via `LegalDocumentService`:
    - `terms_of_service_accepted`
    - `privacy_policy_accepted`
    - `event_waiver_accepted`
  - **Content binding**: each acceptance includes a `sha256` of the exact text shown (and version/effective date) so acceptance is defensible without storing PDFs.

#### 2) Paperwork storage bucket (retention locked) is connected
- Added migration:
  - `supabase/migrations/063_paperwork_documents_bucket_v1.sql`
- Creates:
  - bucket: `paperwork-documents` (private)
  - optional grants table: `public.paperwork_object_grants_v1` (service role managed)
- Policies:
  - users can `INSERT` (only under `auth.uid()/…`) and `SELECT`
  - **no user `UPDATE` / `DELETE` policies** → retention lock
- Applied to active Supabase project:
  - Project: `SPOTS_` (`nfzlwgbvezwwrutqpedy`)
  - Migration record: `paperwork_documents_bucket_v1` (20260102211209)

#### 3) Dispute evidence is now “real” and auditable
- New service: `lib/core/services/disputes/dispute_evidence_storage_service.dart`
  - uploads evidence images to `paperwork-documents` with `upsert: false`
  - returns stable `sb://paperwork-documents/...` refs
  - provides `resolveSignedUrl()` for display (short-lived HTTPS)
  - ledger event for each upload:
    - domain: `moderation`
    - `dispute_evidence_uploaded` with `object_ref`, `object_path`, `sha256`, etc.
- UI:
  - `DisputeSubmissionPage`:
    - gallery selection via `file_picker` (multi-select)
    - camera capture via `image_picker`
    - uploads after dispute ID exists, then attaches `sb://...` refs to dispute
  - `DisputeStatusPage`:
    - shows thumbnails by resolving signed URLs from `sb://...` refs
    - tap opens a larger preview dialog

#### 4) DI + state coherence for disputes
Because `DisputeResolutionService` is currently **in-memory**, it must be a singleton so the “status” page can see what the “submit” page created:
- Registered singleton in `lib/injection_container.dart`
- Dispute pages updated to use `GetIt.instance<DisputeResolutionService>()`

### Protocol docs updated/added
- Added: `docs/agents/protocols/PAPERWORK_DOCUMENTS_RETENTION_AND_LEDGER_RECEIPTS.md`
- Updated index: `docs/agents/protocols/README.md`
- Updated canonical status: `docs/agents/status/status_tracker.md`

### Notes / caveats
- Disputes are still stored in-memory (temporary). Evidence is real (Supabase Storage) but dispute records are not yet persisted server-side.
- Camera/gallery behavior varies by platform; iOS/Android permissions were added in app manifests.

