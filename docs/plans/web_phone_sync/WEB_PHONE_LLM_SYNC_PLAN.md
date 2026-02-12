# Phase 24: Web App ↔ Phone LLM Sync Hub

**Created:** January 2, 2026  
**Status:** 📋 Planning  
**Tier:** 2  
**Dependencies:** Phase 12 (Neural Network), Phase 17 (Model Deployment)

---

## 🎯 Vision

The Web App serves as an always-online "Ground Station" that continuously downloads LLM updates, training data, and model improvements—then syncs them to the user's phone over local network or BLE when available.

**Core Insight:** Browser has constant internet → Phone stays offline-first → AI stays up-to-date without mobile data drain.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    WEB APP (Browser - Always Online)             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Service Worker (Background Sync)                        │    │
│  │  ├── Download LLM weight deltas from cloud               │    │
│  │  ├── Fetch personality learning improvements             │    │
│  │  ├── Pre-compute expensive AI operations                 │    │
│  │  └── Cache in IndexedDB                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Sync Engine                                             │    │
│  │  ├── WebRTC (same WiFi P2P)                              │    │
│  │  ├── Local Network Discovery (mDNS)                      │    │
│  │  └── BLE (proximity transfer)                            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Delta Sync Protocol
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PHONE APP (Offline-First)                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Local LLM Runtime (ONNX)                                │    │
│  │  ├── Apply weight deltas from web                        │    │
│  │  ├── Update personality learning models                  │    │
│  │  └── Works fully offline between syncs                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Sync Client                                             │    │
│  │  ├── Discover web app on local network                   │    │
│  │  ├── Authenticate via shared secret / QR code            │    │
│  │  └── Apply deltas with rollback capability               │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Sections

### 24.1 Core Sync Protocol

| Subsection | Task | Description |
|------------|------|-------------|
| 24.1.1 | Delta Format Design | Design efficient delta format for ONNX model weight updates |
| 24.1.2 | Sync Manifest | Version manifest tracking what's on cloud, web, phone |
| 24.1.3 | Conflict Resolution | Handle version conflicts (web ahead, phone ahead, diverged) |
| 24.1.4 | Rollback Mechanism | Allow rollback if delta application fails |

### 24.2 Web App Ground Station

| Subsection | Task | Description |
|------------|------|-------------|
| 24.2.1 | Service Worker Setup | Background sync for LLM updates |
| 24.2.2 | IndexedDB Storage | Store model deltas, manifests, queued updates |
| 24.2.3 | Cloud Fetch Worker | Poll/subscribe to model update channel |
| 24.2.4 | Pre-computation Engine | Run expensive computations while browser open |

### 24.3 Phone Sync Client

| Subsection | Task | Description |
|------------|------|-------------|
| 24.3.1 | Local Network Discovery | mDNS/Bonjour to find web app on same WiFi |
| 24.3.2 | BLE Transfer Protocol | Fallback for no-WiFi proximity sync |
| 24.3.3 | WebRTC Direct Connect | P2P transfer for large deltas |
| 24.3.4 | Delta Application | Apply ONNX weight deltas to local model |

### 24.4 Security & Authentication

| Subsection | Task | Description |
|------------|------|-------------|
| 24.4.1 | Device Pairing | QR code or PIN-based pairing |
| 24.4.2 | Session Keys | Rotate session keys for each sync |
| 24.4.3 | Integrity Verification | SHA-256 checksums on all deltas |
| 24.4.4 | Audit Logging | Log all sync operations for debugging |

---

## 🏢 Business / Admin / Enterprise Extensions

### 24.5 Business Dashboard (Web-First)

| Subsection | Task | Description |
|------------|------|-------------|
| 24.5.1 | Business Account Model | Business entity with multiple users/devices |
| 24.5.2 | Fleet Management | View all company devices and their sync status |
| 24.5.3 | Centralized Model Distribution | Push model updates to all business devices |
| 24.5.4 | Usage Analytics | Aggregate AI usage across business |

### 24.6 Admin Console

| Subsection | Task | Description |
|------------|------|-------------|
| 24.6.1 | Admin Roles & Permissions | Admin, Manager, User role hierarchy |
| 24.6.2 | Model Version Control | Pin specific model versions for compliance |
| 24.6.3 | Sync Policy Management | Control when/how devices sync (WiFi only, etc.) |
| 24.6.4 | Remote Wipe | Ability to wipe AI data from lost devices |

### 24.7 Enterprise Integration

| Subsection | Task | Description |
|------------|------|-------------|
| 24.7.1 | SSO Integration | SAML/OIDC for enterprise auth |
| 24.7.2 | MDM Compatibility | Work with Mobile Device Management systems |
| 24.7.3 | On-Premise Deployment | Option to host sync server on-premise |
| 24.7.4 | Compliance Reports | Generate compliance reports for auditors |
| 24.7.5 | Data Residency Controls | Control where AI data is stored/processed |

### 24.8 Multi-Location Business Support

| Subsection | Task | Description |
|------------|------|-------------|
| 24.8.1 | Location Groups | Group devices by physical location |
| 24.8.2 | Location-Specific Models | Different AI models per location |
| 24.8.3 | Cross-Location Insights | Aggregate insights across all locations |
| 24.8.4 | Franchise Support | White-label sync hub for franchise businesses |

---

## 🔗 Dependencies

| Dependency | Why Needed | Phase |
|------------|------------|-------|
| Neural Network Implementation | ONNX models to sync | Phase 12 |
| Complete Model Deployment | Model versioning/distribution | Phase 17 |
| Signal Protocol | Secure device pairing | Phase 14 |
| White-Label Infrastructure | Enterprise customization | Phase 18 |

---

## 📊 Success Metrics

| Metric | Target |
|--------|--------|
| Sync latency (same WiFi) | < 5 seconds for typical delta |
| BLE sync throughput | > 50 KB/s sustained |
| Model freshness | Phone within 24h of latest model |
| Battery impact | < 1% per sync operation |
| Business onboarding | < 30 min to set up fleet |

---

## 🚪 Doors This Opens

1. **Always-current AI** - Phone AI stays up-to-date without mobile data
2. **Business adoption** - Enterprise-grade fleet management
3. **Offline-first preserved** - Phone never depends on internet directly
4. **Professional tools** - Admins can manage AI across organization
5. **Compliance-ready** - Audit trails, version pinning, data residency

---

## 📅 Estimated Timeline

| Section | Estimate |
|---------|----------|
| 24.1 Core Sync Protocol | 2 weeks |
| 24.2 Web App Ground Station | 2 weeks |
| 24.3 Phone Sync Client | 2 weeks |
| 24.4 Security & Authentication | 1 week |
| 24.5-24.8 Business/Enterprise | 4 weeks |
| **Total** | **11 weeks** |

---

## 📚 Related Documents

- `docs/plans/neural_network/NEURAL_NETWORK_IMPLEMENTATION_PLAN.md`
- `docs/plans/ml_models/COMPLETE_MODEL_DEPLOYMENT_PLAN.md`
- `docs/plans/white_label/WHITE_LABEL_VPN_PROXY_PLAN.md`
- `docs/ai2ai/` - AI2AI communication patterns
