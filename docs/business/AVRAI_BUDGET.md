# AVRAI — Working Budget

**Date:** February 2026  
**Status:** Draft — Pre-Pre-Seed  
**Founder:** Solo  
**Entities:** RG Enterprises LLC (Alabama) + AVRAI LLC (Delaware)  
**Domain:** avrai.org (owned)  
**Platforms:** iOS + Android (no web)

---

# TECHNICAL BUDGET

---

## Fixed Costs — Subscriptions

| Item | Monthly | Annual | Notes |
|------|---------|--------|-------|
| Supabase Pro | $25 | $300 | 8GB database, 100GB storage, 250GB bandwidth, 2M edge function invocations/mo. 15+ edge functions deployed. Overage: $2/1M additional invocations. |
| Cursor Ultra | $200 | $2,400 | AI-assisted development. 20x usage vs Pro. Unlimited model access. |
| Cursor Extra Usage Credits | $3,500 | $42,000 | Additional API usage beyond Ultra plan. Enables unrestricted model access (Opus, GPT-4, etc.). |
| GitHub Pro | $4 | $48 | Private repos + GitHub Actions CI/CD |
| Apple Developer Account | $8.25 | $99 | iOS distribution + TestFlight. $99/yr billed annually. |
| **TOTAL** | **$3,737.25** | **$44,847** | |

## Fixed Costs — One-Time Fees

| Item | Cost | Notes |
|------|------|-------|
| Google Play Developer | $25 | One-time. Required for Android distribution. |

---

## Fixed Costs — Hardware (One-Time, Buy as Needed)

| Item | Low | High | Notes |
|------|-----|------|-------|
| MacBook Pro (M3/M4) | $1,999 | $3,499 | Required for iOS builds (Xcode/macOS only). Skip if already owned. |
| Mac Mini (CI server) | $599 | $1,299 | Automated builds/tests. Skip if using GitHub Actions. |
| External Monitor (27" 4K) | $299 | $799 | Skip if already owned. |
| External SSD (1–4TB) | $79 | $299 | Backups, ML model files, Xcode archives |
| USB-C Hub/Dock + Cables | $99 | $350 | |
| iPhone 15 Pro | $999 | $1,199 | Primary iOS test device. Tier 3 (full world model + SLM capable). |
| iPhone 14 (or older) | $500 | $799 | Backward compatibility / Tier 2 testing. Refurbished OK. |
| Google Pixel 8 | $549 | $699 | Primary Android test device. Stock Android baseline. Tier 2-3. |
| Samsung Galaxy S24 | $699 | $899 | Samsung One UI behaves differently for BLE, notifications, permissions. Refurb OK. |
| Budget Android (~$150 range) | $149 | $299 | Low-end / Tier 0-1 performance testing. Real users have cheap phones. |
| **TOTAL** | **$5,971** | **$10,137** | Most founders already have a Mac + personal phone. Actual spend depends on what you own. |

---

## Variable Costs — APIs & Cloud Services

| Item | Current Cost | What It Does | Notes |
|------|-------------|--------------|-------|
| Google Gemini API | $0 | Powers AI chat via `llm-chat-stream` edge function | Free tier: 1,000 req/day, 15 RPM. Paid: ~$1.25/1M input tokens. Gemini Flash cuts 75%. |
| Google Places API (New) | $0 | Text search, nearby search, place details for spot discovery | $200/mo free credit. $17/1K text searches. Credit covers ~11K searches/mo. |
| Google Maps SDK | $0 | Renders native map view | $200/mo free credit shared with Places. $7/1K map loads. |
| Firebase (Blaze plan) | $0 | Auth, Firestore, Storage (tax docs), Analytics (free), FCM push (free) | Free tier: 50K reads/day, 20K writes/day, 5GB storage. |
| OpenWeatherMap | $0 | Weather context for recommendations (indoor spots on rainy days) | Free tier: 1,000 calls/day. API key not yet configured. |
| Stripe | $0 | Payments, refunds, identity verification | No monthly fee. 2.9% + $0.30/txn. $1.50/identity verification. Costs only when processing real money. |
| Google Cloud Storage | $0 | File/media storage beyond Supabase | 5GB free. $0.020/GB/mo after. |
| Supabase Storage (model distribution) | $0 | On-device ONNX models (~1MB) + optional SLM (700MB–2GB) downloaded by users | Included in Pro plan. Bandwidth = $0.09/GB egress. Migrate to Cloudflare R2 (free egress) before costs grow. |
| Cloudflare R2 (future CDN) | $0 | Model delivery with free egress | Not yet set up. $0.015/GB/mo storage. Use when model downloads create real bandwidth cost. |
| ML Training Compute (Cloud GPU) | $0 | Pre-training energy function, transition predictor, batch retraining | Google Colab free tier for now. RunPod/Lambda $10–$50/run when needed. |
| **TOTAL** | **$0** | | All free tiers during solo development. |

---

## Free Services (No Budget Impact)

| Item | What It Does | Why Free |
|------|-------------|----------|
| OpenStreetMap (Nominatim + Overpass) | Place search fallback, nearby amenity queries | Community API, free with rate limiting |
| Apple MapKit (MKLocalSearch) | Native iOS place search with cache | Native SDK, no per-call cost |
| Firebase Analytics | Event tracking | Always free, unlimited |
| Firebase Cloud Messaging | Push notifications | Always free, unlimited |
| Google OAuth | Google Sign-In | Free |
| Embeddings edge function | Text embeddings | Uses local hash, no external API |
| Social media OAuth (10 platforms) | Instagram, Facebook, X, Reddit, TikTok, Pinterest, LinkedIn, YouTube, Tumblr, Are.na | OAuth endpoints free. Behind feature flag. |
| HuggingFace | Token configured, no active calls | Free tier |
| TestFlight | iOS beta distribution | Included with Apple Developer |
| Signal Protocol | End-to-end encryption for AI2AI | Runs entirely on-device (Rust FFI) |
| ONNX Runtime | On-device world model inference (energy function, state encoder, transition predictor, action encoder) | Open-source, bundled in app binary |
| Drift / SQLite | On-device episodic memory, semantic memory storage | Open-source, on-device |
| PyTorch + ONNX tools | Training pipeline for world model components | Open-source Python libraries |

---
---

# OPERATIONAL BUDGET

**Entities:** RG Enterprises LLC (Alabama) + AVRAI LLC (Delaware)

---

## Fixed Costs — Business Formation (One-Time)

| Item | Low | High | Notes |
|------|-----|------|-------|
| Alabama LLC Filing (RG Enterprises) | $200 | $200 | AL Secretary of State filing fee |
| Delaware LLC Filing (AVRAI) | $90 | $90 | DE Division of Corporations filing fee |
| Delaware Registered Agent (AVRAI) — first year | $50 | $300 | Required for DE LLC. Annual recurring cost (see Recurring section). |
| Alabama Registered Agent (RG Enterprises) — first year | $0 | $100 | Can serve as your own if you have an AL address. Otherwise $50–$100/yr. |
| Operating Agreement — RG Enterprises | $500 | $1,500 | Attorney-drafted. Ownership, equity, voting. |
| Operating Agreement — AVRAI | $500 | $1,500 | Attorney-drafted. Defines relationship to RG Enterprises if parent/holding entity. |
| EIN Registration — RG Enterprises | $0 | $0 | Free from IRS |
| EIN Registration — AVRAI | $0 | $0 | Free from IRS |
| Business License (Alabama) | $50 | $300 | Varies by city/county. Some jurisdictions don't require for software. |
| Privacy Policy (attorney-drafted) | $500 | $2,000 | GDPR + CCPA compliance already coded. Legal doc needs to match implementation. |
| Terms of Service (attorney-drafted) | $500 | $2,000 | Already linked from onboarding. Needs real legal language. |
| **TOTAL** | **$2,390** | **$7,990** | |

---

## Fixed Costs — Recurring Operational

| Item | Monthly | Annual | Notes |
|------|---------|--------|-------|
| Google Workspace (Business Starter) | $7 | $84 | Custom email @avrai.org (support@, privacy@, feedback@, bugs@, business-support@, demo@). Promo: $3.50/mo through May 2026. |
| Claude Pro (or equivalent AI) | $20 | $240 | Admin, legal research, operational tasks, document drafting |
| avrai.org Domain Renewal | — | $12 | Already owned |
| Delaware Registered Agent (AVRAI) | — | $150 | Required annually for DE LLC. Range: $50–$300/yr. Midpoint used. |
| Alabama Registered Agent (RG Enterprises) | — | $0 | Free if you serve as your own agent with an AL address. Otherwise $50–$100/yr. |
| Accounting Software | $0 | $0 | Wave (free) or QuickBooks ($30/mo). Only needed once real transactions exist. Using $0 until then. |
| **TOTAL** | **$27** | **$486** | |

---

## Variable Costs — Design (One-Time)

| Item | Low | High | Notes |
|------|-----|------|-------|
| App Designer (UI/UX contract) | $3,000 | $10,000 | Full design system: all core screens, component library, interaction patterns, accessibility. Low = experienced freelancer. High = boutique agency. |
| Logo + App Icon | $200 | $2,000 | Fiverr ($200–500) to professional brand designer ($1,500+). Must work at all sizes (1024x1024 down to 29x29). |
| Design Tools (Figma) | $0 | $0 | Free for individual use. Designer uses their own account. |
| **TOTAL** | **$3,200** | **$12,000** | |

---

## Variable Costs — Intellectual Property (One-Time)

| Item | Low | High | Notes |
|------|-----|------|-------|
| Patent Attorney Consultation | $2,000 | $5,000 | Strategy session + prior art search across all patent areas |
| Provisional #1: AI2AI Personality Learning | $2,000 | $5,000 | Core tech. AI agents learn/evolve personality via device-to-device communication. Most defensible IP. |
| Provisional #2: Quantum-Inspired Matching | $2,000 | $5,000 | Quantum state personality representation + compatibility via inner products |
| Provisional #3: Offline-First Mesh Network | $2,000 | $5,000 | BLE device discovery and mesh protocol for AI2AI without internet |
| Provisional #4: Knot Theory Group Dynamics | $2,000 | $5,000 | Group formation using topological knot invariants |
| Provisional #5: Privacy-Preserving Architecture | $2,000 | $5,000 | Differential privacy, k-anonymity, internal/external boundary |
| **TOTAL (Provisionals)** | **$12,000** | **$30,000** | Deferrable. File as budget allows. |
| Non-Provisional Conversion (per patent) | $7,040 | $23,080 | 12-month window from provisional filing date. All 5 = $35,200–$115,400. Defer to post-seed. |

---

## Variable Costs — Legal & Compliance (One-Time)

| Item | Low | High | Notes |
|------|-----|------|-------|
| Cryptographic Security Audit | $15,000 | $30,000 | Signal Protocol, AI2AI encryption, BLE security, penetration testing. Required before handling real user data. |
| GDPR Compliance Review | $0 | $3,000 | Only if targeting EU at launch. Code-level compliance already built. |
| Ongoing Legal Consultation | $0 | $2,000/qtr | Contract review, NDAs. As needed. |
| **TOTAL** | **$15,000** | **$35,000** | Post-raise. |

---
---

# SUMMARY

---

## Monthly Burn (Development Phase)

| Item | Monthly |
|------|---------|
| Supabase Pro | $25 |
| Cursor Ultra | $200 |
| Cursor Extra Usage Credits | $3,500 |
| Claude Pro | $20 |
| GitHub Pro | $4 |
| Google Workspace | $7 |
| Apple Developer (amortized) | $8.25 |
| All APIs & Cloud Services | $0 |
| **TOTAL MONTHLY BURN** | **$3,764.25/mo (~$45,171/yr)** |

---

## One-Time Costs by Priority

| Priority | Item | Low | High | When |
|----------|------|-----|------|------|
| 1 | Legal formation (2 LLCs + legal docs) | $2,390 | $7,990 | Now |
| 2 | Google Play Developer account | $25 | $25 | Now |
| 3 | Test devices (1–5 phones) | $149 | $3,895 | Before beta |
| 4 | App designer (UI/UX + logo) | $3,200 | $12,000 | Before beta |
| 5 | Development hardware (if needed) | $3,075 | $6,246 | As needed — skip if already owned |
| 6 | Patent attorney + 5 provisionals | $12,000 | $30,000 | When fundable |
| 7 | Security audit + legal compliance | $15,000 | $35,000 | Post-raise |

---

## Total Capital Needed (Year 1 Scenarios)

| Scenario | One-Time | Year 1 Burn | Year 1 Total |
|----------|----------|-------------|--------------|
| Minimum viable (burn + LLCs + 1 phone) | $2,564 | $45,171 | ~$47,735 |
| Comfortable to beta (+ designer + phones + legal docs) | $10,860 | $45,171 | ~$56,031 |
| Full pre-seed (+ patents) | $22,860 | $45,171 | ~$68,031 |
| Everything (+ security audit + all hardware) | $69,306 | $45,171 | ~$114,477 |

---

**Last Updated:** February 10, 2026  
**Next Review:** Before investor presentation
