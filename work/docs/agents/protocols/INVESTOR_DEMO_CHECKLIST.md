# Investor Demo Checklist — iOS TestFlight

**Audience:** Presenter and anyone prepping the investor demo  
**Goal:** Align demo flow, device setup, and messaging with what the app actually does so the demo is stable and claims are accurate.

For release gates and automated verification, see [RELEASE_GATE_CHECKLIST_CORE_APP_V1.md](RELEASE_GATE_CHECKLIST_CORE_APP_V1.md).  
For funding context, see [docs/business/PRE_SEED_FUNDING_REQUIREMENTS.md](../../business/PRE_SEED_FUNDING_REQUIREMENTS.md).

---

## 1. Demo flow (what to show)

**Primary path (first launch):**
1. Fresh install → sign up/sign in  
2. Onboarding: legal/age → homebase → AI loading → knot discovery → **knot birth sequence** → tribes/group → home  
3. From home: Spots (browse, one spot details) → Lists (browse, create one list) → Search/suggestions → Vibe/Profile  
4. **Ask avrai** (with network): trigger and confirm a response  

**Optional (second launch):**
- Fully close the app and reopen to show “already logged in” path (no crash, user lands on home).

**Avoid unless scripted as “coming soon”:**
- BLE discovery, Signal two-device, federated sync flows that are gated/off or unstable.

---

## 2. Device setup

- **iPhone:** Developer Mode enabled (Settings → Privacy & Security → Developer Mode).  
- **Build:** TestFlight build from `flutter build ipa --release --export-method app-store`; upload via Xcode Organizer or Transporter.  
- **Install:** Install the TestFlight build on the demo iPhone; confirm launch and no crash loop.

See [IOS_SIGNED_IPA_BUILD_RUNBOOK](IOS_SIGNED_IPA_BUILD_RUNBOOK.md) for IPA build and TestFlight upload steps.

---

## 3. Safe messaging (what to say / not say)

Use the **Truth Notes** and safe wording from [RELEASE_GATE_CHECKLIST_CORE_APP_V1.md](RELEASE_GATE_CHECKLIST_CORE_APP_V1.md) (section “Truth Notes — Current Overclaims” and “Safe-to-claim wording”).

**Federated / network learning:**
- **Safe:** “Learning happens on your device. If you opt in to network learning, your agent may share small, privacy‑bounded updates — not your raw personal data.”  
- **Avoid:** “Your data never leaves your device,” “encrypted model updates,” or “all learning happens on your device” if federated sync is enabled.

**Cloud AI / Ask avrai:**
- **Safe:** “Your personal data stays on-device for learning. When you choose cloud AI, the text you submit is sent securely to our servers to generate a response.”  
- **Avoid:** Absolute “never leaves device” for cloud AI path.

---

## 4. Pre-demo verification (recommended)

- Run the six release suites (auth, infrastructure, spots_lists, search, ai_ml, security) and ensure they are green.  
- On the demo device: already-logged-in path and full demo flow (including knot birth) pass; Ask avrai works online and shows a clear offline message when network is disabled.

---

*Last updated: per iOS TestFlight Demo Solidification Plan (Phase 6).*
