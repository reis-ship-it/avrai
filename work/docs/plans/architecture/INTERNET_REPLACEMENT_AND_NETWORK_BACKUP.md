# Internet Replacement + Network Backup

**Date:** January 2026  
**Status:** Implemented  
**Purpose:** Document the product goal and implementation pattern for "internet replacement functional + network backup."

---

## Goal

1. **Internet replacement:** The primary in-app experience is fully functional without internet. Users can use core features offline (local-first reads, write to local/queue, AI2AI mesh, etc.).
2. **Network backup:** When internet/service is available, it is used for sync, enhanced AI, federation, and optional routing. Sync is coordinated by a single component so "back online" triggers all backup steps once.

---

## Implementation

### Single network-status source

- **EnhancedConnectivityService** (`lib/core/services/enhanced_connectivity_service.dart`):
  - `hasInternetAccess()` — real internet (HTTP ping), not just "WiFi associated."
  - `onBackOnline` — stream that emits only when transitioning from offline to online (debounced). Use for "when to run backup sync."
- Use `hasInternetAccess()` and `onBackOnline` for backup/sync decisions. Use `connectivityStream` only for UI (e.g. offline indicator) if needed.

### Backup sync coordinator

- **BackupSyncCoordinator** (`lib/core/sync/backup_sync_coordinator.dart`):
  - Subscribes to `EnhancedConnectivityService.onBackOnline`.
  - On "back online," runs sync steps in order: CloudIntelligenceSync, Quantum sync offline matches, ConnectionOrchestrator federated sync, EventQueue process, ReservationNotificationService sync.
  - Each step is wrapped in a per-step **NetworkCircuitBreaker** so a flaky backend does not block others.
- Started from `main.dart` (deferred init, priority 7).

### Local-first and per-feature backend

- **Reads:** Prefer `SimplifiedRepositoryBase.executeOfflineFirst()` (or equivalent): local read first, then optional remote refresh + syncToLocal when online. See `lib/data/repositories/repository_patterns.dart`.
- **Writes:** Write to local DB or local queue first; return success to the user immediately. Sync to cloud only when BackupSyncCoordinator runs (or when online). EventQueue, ConnectionLogQueue, ReservationNotificationService queue, federated delta queue follow this pattern.
- **Per-feature backend selection:** For features with both local and cloud (e.g. LLM, search), use one decision point: prefer local; use cloud only when online and local not sufficient. See `LLMService` for the pattern.

---

## Checklist for new features

When adding a feature that should work as "internet replacement + network backup":

- [ ] **Reads:** Use local/cache first; optional background refresh when online. Prefer `executeOfflineFirst` where applicable.
- [ ] **Writes:** Write to local or queue first; show success immediately. Do not block on network. If the feature has a queue that must sync when online, register a sync step with BackupSyncCoordinator (or call an existing sync service that the coordinator already runs).
- [ ] **Connectivity:** Use `EnhancedConnectivityService.hasInternetAccess()` for "may I use network as backup?" Do not create a new connectivity listener for "when back online" — BackupSyncCoordinator is the single subscriber to `onBackOnline`.
- [ ] **Circuit breaker:** If the feature adds a new backup sync step that hits the network, wrap it in a `NetworkCircuitBreaker` in the coordinator so repeated failures do not spin.

---

## References

- `docs/plans/architecture/OFFLINE_CLOUD_AI_ARCHITECTURE.md`
- `docs/plans/architecture/AI_DATA_CENTER_RESILIENCE.md`
- `docs/plans/architecture/ONLINE_OFFLINE_STRATEGY.md`
- `docs/plans/ai2ai_system/AI2AI_SYNC_AND_OFFLINE.md`
