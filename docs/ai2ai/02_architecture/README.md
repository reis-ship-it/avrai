# AI2AI Architecture & Design

**Purpose:** System architecture, design decisions, and architectural documentation

---

## 📚 **Documentation in This Folder**

1. **[ARCHITECTURE_LAYERS.md](./ARCHITECTURE_LAYERS.md)** - Physical + Personality AI layers
2. **[NETWORK_FLOWS.md](./NETWORK_FLOWS.md)** - Complete flow diagrams
3. **[ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md)** - ADRs and design decisions
4. **[EXPERTISE_NETWORK_LAYERS.md](./EXPERTISE_NETWORK_LAYERS.md)** - Expertise-based network layers
5. **[diagrams/](./diagrams/)** - Visual diagrams (ASCII and Mermaid)

---

## 🎯 **Quick Reference**

**Architecture:** Two-layer system (Physical Infrastructure + Personality AI Layer)

**Key Principle:** All device connections route through Personality AI Layer, NOT direct peer-to-peer

**Code Reference:**
- `lib/core/network/` - Physical layer
- `lib/core/ai2ai/` - Personality AI layer
- `lib/core/ai/` - AI systems

---

**See individual documents for detailed explanations.**

