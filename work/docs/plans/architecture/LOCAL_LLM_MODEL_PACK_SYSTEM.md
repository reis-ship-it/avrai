# Local LLM Model Pack System (Option B Runtime)

**Date:** January 1, 2026  
**Status:** Active – Source of truth for local model pack provisioning  

---

## Purpose

Local LLM inference requires large platform-specific artifacts:
- **Android**: GGUF weights for llama.cpp runtime
- **iOS**: compiled CoreML artifacts (`.mlmodelc`) delivered as a zip

We cannot ship these inside the base app install without making updates and installs unreasonably large.

This system provides a safe, versioned way to:
- download large artifacts post-install,
- verify integrity,
- activate atomically,
- rollback on regressions (happiness-gated).

---

## Components

### Runtime
- **Pack manager:** `lib/core/services/local_llm/model_pack_manager.dart`
- **Signed manifest verification:** `lib/core/services/local_llm/signed_manifest_verifier.dart`
- **Manifest envelope type:** `lib/core/services/local_llm/signed_manifest.dart`

### Manifest provider
- **Supabase Edge Function:** `supabase/functions/local-llm-manifest/index.ts`

---

## Threat model summary

### What we must defend against
- Artifact corruption or partial downloads
- Zip slip / path traversal during extraction
- “Arbitrary URL manifest” attacks (attacker-controlled manifest + matching hashes)

### Security posture (release)
- **No user-provided manifest URLs**
- App fetches a **signed manifest envelope** from Supabase
- App verifies **Ed25519 signature locally**
- App verifies artifact **SHA-256** before installation
- Safe extraction blocks zip slip

---

## Data formats

### 1) Signed manifest envelope (returned by `local-llm-manifest`)

```json
{
  "key_id": "v1",
  "payload_b64": "...",
  "sig_b64": "..."
}
```

- `payload_b64`: base64 JSON bytes for the `LocalLlmModelPackManifest` schema.
- `sig_b64`: Ed25519 signature over the raw payload bytes.

### 2) Pack manifest payload

Schema is defined in:
- `lib/core/services/local_llm/model_pack_manifest.dart`

Key fields:
- `model_id`, `version`, `family`, `context_len`
- `min_device` requirements (soft gate; hard gate is the app’s capability gate)
- `artifacts[]` with platform-specific download URLs + SHA256

---

## Key management

### Generate keys

Use:
- `scripts/security/generate_local_llm_manifest_keys.dart`

Outputs:
- Server secret: `LOCAL_LLM_MANIFEST_SIGNING_KEY_B64`
- App build define: `LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1`

### App public key injection

Provide at build time:
- `--dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<base64_public_key>`

### Rotation

- Add a new `key_id` in the Edge Function
- Add the new public key in app build defines (or code)
- Keep previous keys available for verification during a migration window

---

## Installation lifecycle

1. Fetch signed envelope from Supabase
2. Verify signature (Ed25519)
3. Parse manifest payload
4. Download artifact to temp dir
5. Verify SHA-256
6. Extract/copy into target dir
7. Atomically set:
   - `local_llm_active_model_dir_v1`
   - `local_llm_active_model_id_v1`
   - record `last_good_*` pointers for rollback
8. Start happiness-gated rollout candidate (`chat_local_llm`)

---

## Rollback

- Rollback is handled by `ModelSafetySupervisor` and
  `LocalLlmModelPackManager.rollbackToLastGoodIfPresent()`.
- Triggers when post-rollout happiness drops materially.

---

## UX

- In release builds, user cannot paste a manifest URL.
- Settings show “Install” and uses the trusted signed-manifest path.
- Auto-install is opt-out (eligible devices default enabled), Wi‑Fi-first.

---

## Implementation status (current)

As of **January 2, 2026**, this system is implemented with:

- **Progress reporting**:
  - Download progress is reported via callbacks (`receivedBytes/totalBytes`) and surfaced via `LocalLlmProvisioningStateService`.
  - Onboarding shows percent + progress bar when downloading.

- **Safer defaults for background downloads**:
  - Auto-install is gated behind **Wi‑Fi + charging/full + idle window** (00:00–06:00 local).
  - UI can explain why it is waiting via provisioning phases: `queuedWifi`, `queuedCharging`, `queuedIdle`.

- **Trusted updates**:
  - Release builds run a best-effort trusted update check under safe conditions (once per 24h).
  - Pack manager skips re-download when the requested `packId` is already the active installed pack.

- **Memory-safe hashing**:
  - SHA-256 verification uses streamed hashing (does not load multi‑GB artifacts into memory).

---

## References

- Onboarding integration: `docs/plans/onboarding/ONBOARDING_LLM_DOWNLOAD_AND_BOOTSTRAP_ARCHITECTURE.md`

