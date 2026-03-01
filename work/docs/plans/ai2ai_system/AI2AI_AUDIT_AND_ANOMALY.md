# AI2AI Audit and Anomaly Detection

**Status:** Active reference  
**Purpose:** Document how admin access and AI2AI security events are audited, and how simple anomaly detection surfaces in the Security dashboard.

---

## Audit

- **Admin actions:** God-mode login, session, and access are handled by [AdminAuthService](lib/core/services/admin_auth_service.dart). Admin access is gated; all access is logged per existing admin audit practices.
- **AI2AI security events:** [NetworkActivityMonitor](lib/core/monitoring/network_activity_monitor.dart) logs security-relevant events only (no message content). When [LedgerAuditV0](lib/core/services/ledgers/ledger_audit_v0.dart) is enabled (`SPOTS_LEDGER_AUDIT=true` and correlation id set), each event is appended to the ledger with domain `security`, entity type `ai2ai_network`, and source `network_activity_monitor`. Events include: routing attempt, connection established/closed, encryption failure, node discovery, delivery success/failure, anomaly.
- **Third-party API:** Requests to the outside-buyer-insights Edge Function are logged in `api_request_logs` and audit; see [OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md](docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md).

---

## Anomaly Detection

- **Logic:** The monitor keeps a sliding window of recent events. If the number of failure-type events (delivery_failure, encryption_failure) in the last 50 events reaches at least 10, it emits an `ai2ai_anomaly` event with reason `failure_spike` and payload `failure_count_in_window`, `window_size`. Anomaly events are rate-limited (at most one per 5 minutes) to avoid spam.
- **Surfacing:** Anomaly events appear in the in-memory buffer and on the Security/Network tab of the God-Mode dashboard like any other event. When LedgerAuditV0 is enabled, they are also persisted to the ledger.
