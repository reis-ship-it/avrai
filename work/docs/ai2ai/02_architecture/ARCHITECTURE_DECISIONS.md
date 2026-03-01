# AI2AI Architecture Decision Records (ADRs)

**Created:** December 8, 2025, 5:10 PM CST  
**Purpose:** Document key architectural decisions for the AI2AI system

---

## 📋 **ADR Index**

1. **[ADR 0002: Orchestrator Decomposition](#adr-0002-orchestrator-decomposition)**

---

## ADR 0002: Orchestrator Decomposition

**Status:** Accepted  
**Date:** 2025-08-08  
**Reference:** `docs/ADRS/0002-ai2ai-architecture-and-logging.md`

### **Context**

`VibeConnectionOrchestrator` had grown large. Logging was inconsistent across core.

### **Decision**

- Decompose orchestrator into `DiscoveryManager`, `ConnectionManager`, and `RealtimeCoordinator` while keeping API stable.
- Use `AppLogger` across ai2ai and bootstrap for consistent, filterable logs.

### **Consequences**

- Smaller, testable components; clearer responsibilities.
- Uniform logs improve diagnostics and observability.

### **Implementation Notes**

- Components live in `lib/core/ai2ai/orchestrator_components.dart` and are composed in orchestrator.
- Realtime coordination funnels listener setup/teardown.
- `AppLogger` wraps developer.log with levels and tags.

### **Code Reference**

- `lib/core/ai2ai/orchestrator_components.dart` - Decomposed components
- `lib/core/ai2ai/connection_orchestrator.dart` - Main orchestrator
- `lib/core/services/logger.dart` - AppLogger implementation

---

## 🔗 **Related Documentation**

- **Architecture Layers:** [`ARCHITECTURE_LAYERS.md`](./ARCHITECTURE_LAYERS.md)
- **Network Flows:** [`NETWORK_FLOWS.md`](./NETWORK_FLOWS.md)
- **Original ADR:** `docs/ADRS/0002-ai2ai-architecture-and-logging.md`

---

**Last Updated:** December 8, 2025, 5:10 PM CST  
**Status:** Architecture Decisions Documentation

