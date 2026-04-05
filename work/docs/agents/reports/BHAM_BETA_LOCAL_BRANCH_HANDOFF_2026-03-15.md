# BHAM Beta Local Branch Handoff

**Date:** March 15, 2026  
**Purpose:** Give agents one local branch to continue active BHAM beta work without depending on GitHub PR state.

## Active BHAM Branch Guidance

- **Canonical active branch for ongoing agent work:** `bham-beta`
- **Historical rescue/local branch:** `bham-beta-local`
- **Current base commit at handoff time:** `ce571725`
- **Historical note:** `bham-beta-local` was created from the rescued `bham-beta` line so the full mixed working set remained available on disk during the rescue phase

## What Agents Should Use

- If the goal is to continue the full BHAM beta / replay / smoke / governance work now, start from `bham-beta`.
- If a clean review-only slice is needed later, use the split branches as references only.
- Do **not** treat `bham-beta-local` as the active branch instruction anymore.

## Important Branch Roles

- `bham-beta`
  - Canonical active BHAM beta branch.
  - This is the branch agents should branch from now.

- `bham-beta-local`
  - Historical local integration/rescue branch.
  - Keep only as a recovery note or reference line if needed.

- `agent/bham-replay-admin-and-artifacts`
  - Narrow replay/admin split for review.
  - Trimmed for GitHub pushability; some oversized raw replay artifacts were intentionally excluded from the pushed split.

- `agent/bham-smoke-and-fallback-runtime`
  - Narrow smoke/bootstrap/trajectory split for review.

- `agent/bham-governance-and-db-hardening`
  - Narrow governance/runtime/migration split for review.

- `agent/vibe-kernel-fallback-review`
  - Isolated `vibe_kernel.dart` review branch.

## Working Rule For Agents

1. Check out `bham-beta`.
2. Create new local child branches from `bham-beta` for active implementation.
3. Use the split `agent/...` branches only when you need to compare, port, or salvage a narrower review slice.
4. Treat `bham-beta-local` as historical rescue context only.

## Notes

- The local repo contains the actual file content and history needed for ongoing work.
- GitHub currently contains review branches and PR metadata, but that is secondary to the local integration flow for now.
- The replay split branch was rewritten for GitHub because several raw artifacts exceeded GitHub's hard file-size limit; `bham-beta-local` remains a historical rescue reference, but not the active branch instruction.
