## Paperwork Documents (Retention) + Ledger Receipts (Auditability)

**Audience:** Anyone touching legal/tax/dispute “paperwork” flows  
**Goal:** Make legal artifacts **kept** (no overwrite/delete) and **auditable** (ledger receipts you can show).

---

### What counts as “paperwork” (in this repo)
- **In-app legal documents (text)**
  - Terms of Service: `lib/core/legal/terms_of_service.dart`
  - Privacy Policy: `lib/core/legal/privacy_policy.dart`
  - Event waiver text (event-specific): `lib/core/legal/event_waiver.dart`
- **Generated documents (files)**
  - Tax PDFs (1099-K): stored in Supabase Storage
- **Uploaded evidence (files)**
  - Dispute evidence (screenshots/photos): stored in Supabase Storage

---

### Storage buckets + retention rules

#### 1) `tax-documents` (private)
- **Purpose:** tax PDFs (1099-K, etc.)
- **Ref format:** `sb://tax-documents/<userId>/<taxYear>/<documentId>.pdf`
- **Retention lock:** no overwrite, no user delete
- **Migrations:**
  - `supabase/migrations/061_tax_documents_supabase_storage_v1.sql`
  - `supabase/migrations/062_tax_documents_retention_lock_v1.sql`

#### 2) `paperwork-documents` (private)
- **Purpose:** legal/payment “paperwork” artifacts (e.g., dispute evidence, contract PDFs)
- **Ref format:** `sb://paperwork-documents/<path>`
- **Path convention (v1):** `<owner_user_id>/<doc_type>/<context_id>/<document_id>.<ext>`
  - dispute evidence: `<userId>/dispute_evidence/<disputeId>/<evidenceId>.<ext>`
- **Retention lock:** users can INSERT + SELECT only; **no UPDATE/DELETE policies**
- **Multi-party read (optional):** via `public.paperwork_object_grants_v1` (service-role managed)
- **Migration:** `supabase/migrations/063_paperwork_documents_bucket_v1.sql`

---

### Ledger receipts (what events exist)

Ledger receipts are “append-only facts” a user can later show in **Receipts UI**.

#### Legal acceptance receipts (text-based)
Emitted by `LegalDocumentService` (`lib/core/services/legal_document_service.dart`):
- `terms_of_service_accepted` (domain: `identity`)
  - includes: `version`, `effective_date`, `content_sha256`, optional `ip_address`, `user_agent`
- `privacy_policy_accepted` (domain: `identity`)
  - includes: `version`, `effective_date`, `content_sha256`, optional `ip_address`, `user_agent`
- `event_waiver_accepted` (domain: `expertise`)
  - includes: `event_id`, `waiver_type`, `waiver_sha256`, optional `ip_address`, `user_agent`

**Why hash the text?**
- It binds the acceptance to *exactly what was shown*, without storing separate PDFs for ToS/Privacy.

#### Tax receipts (file-backed)
Emitted by `TaxComplianceService` (`lib/core/services/tax_compliance_service.dart`):
- `w9_submitted` (domain: `payments`)
  - **no SSN/EIN in payload**
- `tax_document_generated` (domain: `payments`)
  - includes `document_url` (`sb://tax-documents/...`) and filing status

#### Dispute evidence receipts (file-backed)
Emitted by `DisputeEvidenceStorageService` (`lib/core/services/disputes/dispute_evidence_storage_service.dart`):
- `dispute_evidence_uploaded` (domain: `moderation`)
  - includes: `bucket_id`, `object_path`, `object_ref`, `sha256`, `byte_length`, `content_type`, `dispute_id`, `event_id`

---

### UI integration (where users see this)
- **Receipts UI:** `Profile → Receipts`
  - Lists and verifies ledger receipts (signed when available).
- **Disputes**
  - Submit: `lib/presentation/pages/disputes/dispute_submission_page.dart`
  - Status: `lib/presentation/pages/disputes/dispute_status_page.dart`
  - Evidence images are shown using short-lived signed URLs resolved from `sb://...` refs.

---

### Verification checklist (quick)

#### A) Supabase: bucket + policies
- Bucket exists: `paperwork-documents`
- User can upload to `auth.uid()/<...>` paths
- User cannot update/delete objects in that bucket

#### B) App: end-to-end dispute evidence loop
- Submit dispute with evidence:
  - evidence uploads succeed
  - dispute stores `sb://paperwork-documents/...` refs
  - evidence renders in dispute status page (via signed URLs)
- Receipts:
  - ledger contains `dispute_evidence_uploaded` rows for the uploads

