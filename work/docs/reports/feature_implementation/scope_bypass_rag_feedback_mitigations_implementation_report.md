# Scope, Bypass & Federated RAG Feedback Mitigations — Implementation Report

**Plan:** `scope_bypass_and_rag_feedback_mitigations_09e4e818`  
**Date:** January 2026  
**Status:** Implemented

---

## Overview

This follow-up implements rule-based improvements to RAG-as-answer scope/bypass classification and hardens the federated RAG feedback feature flag. It reduces obvious misclassifications (e.g. “capital of my heart” out-of-scope, “keep going to the gym” as bypass) and makes it harder to enable RAG feedback before migration 082 is applied.

Deferred (per plan): #3 learningHistory merge, #5 formatter verification/NLI, #8 fire-and-forget retry/queue, #9 search vs RAG-as-answer, #10 empty-retrieval UX.

---

## 1. Bypass Phrases and “Keep Going” Narrowing

### 1.1 New Bypass Phrases

**File:** `lib/core/ai/bypass_intent_detector.dart`

Added phrases so more natural follow-ups trigger the bypass path (full LLM context instead of RAG-as-answer):

- **New regex groups:**  
  - `(dig deeper|dive deeper|expand further|go further)`  
  - `(give me more|a bit more|more about that|more on that)`  
  - `(explain more|break it down more)`

Existing phrases (“tell me more”, “continue”, “go on”, “go deeper”, “elaborate”, “expand on that”, “more details”, “and?”, “more?”, etc.) are unchanged.

### 1.2 “Keep Going” Narrowing

**Problem:** `\b(continue|go on|keep going)\b` matched any occurrence. “I want to keep going to the gym” wrongly triggered bypass.

**Change:**

- Removed “keep going” from the shared regex; “continue” and “go on” stay as-is.
- “Keep going” triggers bypass only when:
  - **`lastAssistantMessage != null`** (clearly a follow-up), or  
  - **Short follow-up:** message matches `^\s*keep\s+going\s*[!.]?\s*$` (e.g. “Keep going”, “Keep going!”, “keep going.”).

**Implementation:**

- `_keepGoingMatch`: `\bkeep\s+going\b` to detect the phrase.
- `_shortKeepGoingOnly`: `^\s*keep\s+going\s*[!.]?\s*$` for short-only.
- In `bypassRequested`, if “keep going” matches, return `true` only when `lastAssistantMessage != null || _isShortKeepGoing(t)`; otherwise skip “keep going” and continue with other phrases.

### 1.3 Tests

**File:** `test/unit/ai/bypass_intent_detector_test.dart`

- **New phrases:** “Dig deeper”, “Expand further”, “Give me more”, “Can you dig deeper?” → bypass.
- **Keep going – bypass:** “Keep going”, “Keep going!”, “keep going.”, and “keep going” with `lastAssistantMessage: 'Prior'` → bypass.
- **Keep going – no bypass:** “I want to keep going to the gym”, “We should keep going with the project” → no bypass.

All existing bypass tests still pass.

---

## 2. Scope In-Scope Overrides

### 2.1 Goal

Avoid labelling preference-like or metaphorical phrases as out-of-scope. Example: “capital of my heart” should stay in-scope; “what is the capital of France?” stays out-of-scope.

### 2.2 Implementation

**File:** `lib/core/ai/scope_classifier.dart`

- **`_inScopeOverrides`:** List of `RegExp` run *before* out-of-scope patterns.  
  - `\bcapital of my heart\b`  
  - `\bcapital of the world\b`  
- In `classify`:
  1. Trim and lowercase the message.
  2. If any override matches → `Scope.inScope`.
  3. Else run existing `_outOfScopePatterns` (general knowledge, math, current events, etc.); if any match → `Scope.outOfScope`.
  4. Else → `Scope.inScope`.

Out-of-scope patterns are unchanged; overrides only add exceptions.

### 2.3 Tests

**File:** `test/unit/ai/scope_classifier_test.dart`

- “Capital of my heart” → `inScope`.
- “You’re the capital of my heart” → `inScope`.
- “What is the capital of France?” → `outOfScope` (unchanged).
- Existing in-scope / out-of-scope cases unchanged.

---

## 3. Federated RAG Feedback Flag Comments

### 3.1 Prefs Key Comment

**File:** `lib/core/ai2ai/connection_orchestrator.dart`

At `_prefsKeyRagFeedbackInFederatedSync`:

- **Comment:** This flag must only be enabled **after** migration `082_rag_feedback_aggregates_v1` is applied. Otherwise federated-sync may fail or RAG feedback inserts will error.

### 3.2 Usage-Site Comment

At the `includeRagFeedback` check (where we decide whether to add `rag_feedback` to the federated-sync body):

- **Comment:** “Enable only after migration 082_rag_feedback_aggregates_v1 is applied.”

No logic changes; comments only, so anyone enabling the flag sees the requirement.

---

## 4. Optional: Table-Missing Signalling and Client Skip

### 4.1 Edge Function

**File:** `supabase/functions/federated-sync/index.ts`

- When `storeRagFeedback` is true:
  - Wrap the `rag_feedback_aggregates_v1` insert in try/catch.
  - **Success:** set `ragFeedbackStored = true`.
  - **Failure:** log error, set `ragFeedbackStored = false`.
- Add `rag_feedback_stored` to the JSON response only when we attempted to store (i.e. when `storeRagFeedback` was true):
  - **Success response:** `rag_feedback_stored: true`.
  - **Failure response:** `rag_feedback_stored: false`.
- Both the normal success path and the early-return path (when delta aggregation read fails) include `rag_feedback_stored` when defined.

Deltas insert and HTTP 200 behaviour are unchanged; RAG feedback remains best-effort.

### 4.2 Client Skip Logic

**File:** `lib/core/ai2ai/connection_orchestrator.dart`

- **New prefs key:** `_prefsKeyRagFeedbackSkipUntil` — stores a timestamp (ms) until when we skip sending `rag_feedback`.
- **`_shouldSkipRagFeedback()`:** Reads the stored timestamp; returns `true` if it exists and `now < skipUntil`.
- **Building the sync body:**  
  - If `includeRagFeedback` is true but `_shouldSkipRagFeedback()` is true, we **do not** add `rag_feedback` to the body.
- **Handling 200 response:**  
  - If `decoded['rag_feedback_stored'] == false`: set `rag_feedback_skip_until` to `now + 24h`.  
  - If `decoded['rag_feedback_stored'] == true`: clear `rag_feedback_skip_until`.

Effect: after a “table missing” (or other) RAG insert failure, the client stops sending `rag_feedback` for 24h, then retries. Once the backend reports success, we clear the skip and send again on subsequent syncs.

---

## 5. Documentation

### 5.1 RAG Implementation Report

**File:** `docs/reports/feature_implementation/rag_wiring_rag_as_answer_bypass_preferences_implementation_report.md`

New section **“Scope / Bypass & Federated RAG Feedback Mitigations (Follow-up)”** summarises:

- New bypass phrases and “keep going” narrowing.
- Scope in-scope overrides (“capital of my heart”, “capital of the world”).
- Federated RAG feedback flag: enable only after migration 082.
- Optional `rag_feedback_stored` signalling and client skip behaviour.

---

## 6. Files Touched

| Area | File | Changes |
|------|------|---------|
| Bypass | `lib/core/ai/bypass_intent_detector.dart` | New phrases; “keep going” conditional logic |
| Bypass tests | `test/unit/ai/bypass_intent_detector_test.dart` | New-phrase and “keep going” edge-case tests |
| Scope | `lib/core/ai/scope_classifier.dart` | `_inScopeOverrides`; run overrides before out-of-scope |
| Scope tests | `test/unit/ai/scope_classifier_test.dart` | “Capital of my heart” in-scope tests |
| Federated RAG | `lib/core/ai2ai/connection_orchestrator.dart` | Flag comments; skip pref + `_shouldSkipRagFeedback`; `rag_feedback_stored` handling |
| Edge function | `supabase/functions/federated-sync/index.ts` | RAG insert try/catch; `rag_feedback_stored` in response |
| Docs | `rag_wiring_rag_as_answer_bypass_preferences_implementation_report.md` | New mitigations follow-up section |
| This report | `scope_bypass_rag_feedback_mitigations_implementation_report.md` | Standalone write-up |

---

## 7. Testing

- **Unit:** `scope_classifier_test.dart`, `bypass_intent_detector_test.dart`, `conversation_preferences_test.dart`, `rag_signals_collector_test.dart`, `connection_orchestrator_test.dart` — all passed.
- **Analyzer:** `flutter analyze` on modified Dart files — no issues.

---

## 8. Summary

- **Bypass:** More phrases; “keep going” only triggers bypass when it’s a clear follow-up or short standalone.
- **Scope:** In-scope overrides for “capital of my heart” / “capital of the world” avoid false out-of-scope.
- **Federated RAG:** Comments stress “enable only after 082”; optional `rag_feedback_stored` + client skip reduce avoidable failures when the table is missing.

These are incremental improvements; they do not remove the need for a richer classifier or verification layer later.
