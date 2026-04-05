# AI2AI Network & Connectivity

**Purpose:** Documentation for network layer, device discovery, and connectivity

---

## 📚 **Documentation in This Folder**

1. **[DEVICE_DISCOVERY.md](./DEVICE_DISCOVERY.md)** - Device discovery system
2. **[BLE_IMPLEMENTATION.md](./BLE_IMPLEMENTATION.md)** - Bluetooth Low Energy
3. **[OFFLINE_AI2AI_PLAN.md](./OFFLINE_AI2AI_PLAN.md)** - Offline peer-to-peer plan
4. **[PROTOCOLS.md](./PROTOCOLS.md)** - AI2AI protocols
5. **[BLE_BACKGROUND.md](./BLE_BACKGROUND.md)** - Background BLE usage
6. **[RETICULUM_SIGNAL_SIMPLE_MESH_BACKLOG.md](./RETICULUM_SIGNAL_SIMPLE_MESH_BACKLOG.md)** - Reticulum-inspired transport + Signal-inspired security backlog with a simple UX contract
7. **[RETICULUM_PLAN_IMPACT_AUDIT.md](./RETICULUM_PLAN_IMPACT_AUDIT.md)** - Audit of what the Reticulum-inspired plan would change in AVRAI, what should stay the same, and why those changes help long-term
8. **[AI2AI_MESH_3_PRONG_GOVERNED_ARCHITECTURE_2026-03-11.md](../../plans/architecture/AI2AI_MESH_3_PRONG_GOVERNED_ARCHITECTURE_2026-03-11.md)** - Proposed three-prong architecture for making mesh and AI2AI kernel-governed in runtime and learnable in the reality model
9. **[AI2AI_MESH_KERNEL_IMPLEMENTATION_BACKLOG_2026-03-11.md](../../plans/architecture/AI2AI_MESH_KERNEL_IMPLEMENTATION_BACKLOG_2026-03-11.md)** - Concrete wiring and backlog for connecting mesh and AI2AI kernels to URK activation, the six kernel surfaces, control plane, and reality-model learning
10. **[HEADLESS_BACKGROUND_MESH_AI2AI_EXECUTION_PLAN_2026-03-13.md](../../plans/architecture/HEADLESS_BACKGROUND_MESH_AI2AI_EXECUTION_PLAN_2026-03-13.md)** - Plan for making mesh, AI2AI, and passive kernel learning run through a true headless/background execution envelope instead of relying on the app UI being active

---

## 🎯 **Quick Reference**

**Physical Layer:** WiFi/Bluetooth for device discovery and data transmission

**Platform Support:**
- Android: BLE + WiFi Direct
- iOS: Multipeer Connectivity + mDNS
- Web: WebRTC + WebSocket

**Code Reference:**
- `lib/core/network/device_discovery.dart` - Device discovery
- `lib/core/network/personality_advertising_service.dart` - Personality advertising
- `lib/core/network/ai2ai_protocol.dart` - AI2AI protocol

---

**See individual documents for detailed explanations.**
