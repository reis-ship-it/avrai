# Admin, Expert, and God Mode Pages - Visual Flow Diagram

**Date:** December 12, 2025  
**Visual representation of authentication flows and page access**

---

## 🔐 **AUTHENTICATION FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────┐
│                    APP LAUNCH                               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
                ┌─────────────────┐
                │  AuthWrapper    │
                │       (/)       │
                └────────┬────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                   │
        ▼                                   ▼
┌───────────────┐                  ┌───────────────┐
│ Not Logged In │                  │  Logged In    │
└───────┬───────┘                  └───────┬───────┘
        │                                   │
        ▼                                   ▼
┌───────────────┐                  ┌───────────────┐
│  LoginPage    │                  │   HomePage    │
│   (/login)    │                  │    (/home)    │
└───────┬───────┘                  └───────┬───────┘
        │                                   │
        └───────────────┐                   │
                        │                   │
                        ▼                   ▼
                ┌───────────────┐   ┌───────────────┐
                │  SignupPage   │   │  ProfilePage  │
                │   (/signup)   │   │   (/profile) │
                └───────────────┘   └───────┬───────┘
                                            │
                                            ▼
                                ┌───────────────────────┐
                                │ ExpertiseDashboard   │
                                │ (/profile/expertise) │
                                └───────────────────────┘
```

---

## 🔴 **GOD MODE ADMIN FLOW (ISOLATED)**

```
┌─────────────────────────────────────────────────────────────┐
│              GOD MODE ADMIN ACCESS                          │
│         (Completely Separate from Main App)                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │   GodModeLoginPage          │
            │   (NOT in router)          │
            │   Direct navigation only    │
            └─────────────┬───────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │  AdminAuthService           │
            │  .authenticate()            │
            └─────────────┬───────────────┘
                          │
                ┌─────────┴─────────┐
                │                   │
                ▼                   ▼
        ┌───────────────┐   ┌───────────────┐
        │   Failed      │   │   Success      │
        └───────────────┘   └───────┬───────┘
                                    │
                                    ▼
                    ┌─────────────────────────────┐
                    │  AdminSession Created       │
                    │  (8-hour expiration)       │
                    └─────────────┬───────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │  GodModeDashboardPage       │
                    │  (NOT in router)           │
                    │  9 Tabs with Admin Views    │
                    └─────────────┬───────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│ Dashboard Tab │      │   Users Tab   │      │ Progress Tab  │
│ System Health │      │ UserDataViewer│      │UserProgress   │
│ Metrics       │      │    Page       │      │   ViewerPage  │
└───────────────┘      └───────┬───────┘      └───────────────┘
                               │
                               ▼
                    ┌───────────────────────┐
                    │  UserDetailPage       │
                    │  (tap user)           │
                    └───────────────────────┘
```

---

## 🎓 **EXPERT PAGES FLOW**

```
┌─────────────────────────────────────────────────────────────┐
│              EXPERT PAGES ACCESS                             │
│         (Based on Expertise Achievements)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │   Regular User Auth         │
            │   (AuthBloc)                │
            └─────────────┬───────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │   HomePage                  │
            │   (/home)                   │
            └─────────────┬───────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │   ProfilePage               │
            │   (/profile)                │
            └─────────────┬───────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │   ExpertiseDashboardPage    │
            │   (/profile/expertise)      │
            │                             │
            │   Visible Content:           │
            │   - Expertise pins          │
            │   - Progress by category     │
            │   - Multi-path expertise    │
            │   - Golden expert status    │
            │   - Partnership boosts      │
            └─────────────────────────────┘
```

---

## 🔄 **COMPLETE ACCESS FLOW BY USER TYPE**

### **Regular User Flow:**

```
User Authentication
    ↓
HomePage
    ├─→ Map Tab
    ├─→ Spots Tab
    └─→ Explore Tab
        └─→ ProfilePage
            ├─→ ExpertiseDashboardPage (own expertise)
            ├─→ Settings pages
            └─→ Other profile features
```

**Accessible:**
- ✅ All main app pages
- ✅ Own expertise dashboard
- ❌ God mode pages
- ❌ Admin pages (except AI2AIAdminDashboard if granted)

---

### **Expert User Flow:**

```
User Authentication
    ↓
HomePage
    ├─→ Map Tab
    ├─→ Spots Tab
    └─→ Explore Tab
        └─→ ProfilePage
            └─→ ExpertiseDashboardPage
                ├─→ Shows expertise pins
                ├─→ Golden expert indicators (if applicable)
                ├─→ Multi-path expertise
                └─→ Expert-level features
```

**Accessible:**
- ✅ All regular user pages
- ✅ ExpertiseDashboardPage (with expert status)
- ✅ Golden expert badges (if 25+ years residency)
- ✅ Expert-level event hosting
- ❌ God mode pages
- ❌ Admin pages (unless also admin)

**Note:** Expert status is **achievement-based**, not authentication-based.

---

### **Admin User Flow (God Mode):**

```
Separate Admin Authentication
    ↓
GodModeLoginPage (direct navigation)
    ↓
AdminAuthService.authenticate()
    ↓
GodModeDashboardPage (direct navigation)
    ├─→ Dashboard Tab (system health)
    ├─→ FL Rounds Tab
    ├─→ Users Tab → UserDataViewerPage
    │   └─→ UserDetailPage (tap user)
    ├─→ Progress Tab → UserProgressViewerPage
    ├─→ Predictions Tab → UserPredictionsViewerPage
    ├─→ Businesses Tab → BusinessAccountsViewerPage
    ├─→ Communications Tab → CommunicationsViewerPage
    │   └─→ ConnectionCommunicationDetailPage (tap)
    ├─→ Clubs Tab → ClubsCommunitiesViewerPage
    │   └─→ ClubDetailPage (tap club)
    └─→ AI Map Tab → AILiveMapPage
```

**Accessible:**
- ✅ All god mode dashboard tabs
- ✅ All admin viewer pages
- ✅ Real-time system data
- ✅ User data, progress, predictions
- ✅ Business accounts
- ✅ Communications
- ✅ Clubs & communities
- ✅ AI live map
- ❌ Regular user pages (separate session)

**Note:** Admin can have **BOTH** regular user session AND admin session simultaneously.

---

### **Business User Flow:**

```
User Authentication
    ↓
HomePage
    └─→ ProfilePage
        ├─→ BusinessAccountCreationPage (if not created)
        └─→ EarningsDashboardPage (if created)
            ├─→ TaxProfilePage
            └─→ TaxDocumentsPage
```

**Accessible:**
- ✅ All regular user pages
- ✅ Business account pages
- ✅ Earnings dashboard
- ✅ Tax documents
- ❌ God mode pages (unless also admin)
- ❌ Admin pages (unless also admin)

---

## 🚨 **PAGES NOT IN NAVIGATION FLOW**

### **God Mode System (14 pages):**

```
┌─────────────────────────────────────────────────────────────┐
│         GOD MODE PAGES (NOT IN ROUTER)                      │
│                                                             │
│  Entry Point:                                               │
│  ┌─────────────────────┐                                    │
│  │ GodModeLoginPage   │ ← NO navigation path from main app │
│  │ (Direct nav only)  │                                    │
│  └─────────┬──────────┘                                    │
│            │                                               │
│            ▼                                               │
│  ┌─────────────────────┐                                  │
│  │GodModeDashboardPage │                                  │
│  │  (9 embedded tabs)  │                                  │
│  └─────────┬───────────┘                                  │
│            │                                               │
│    ┌───────┼───────┐                                      │
│    │       │       │                                      │
│    ▼       ▼       ▼                                      │
│  ┌───┐  ┌───┐  ┌───┐                                      │
│  │U1 │  │U2 │  │U3 │  ... (9 viewer pages)               │
│  └───┘  └───┘  └───┘                                      │
│    │       │       │                                      │
│    └───┬───┴───┬──┘                                      │
│        │       │                                          │
│        ▼       ▼                                          │
│  ┌────────┐ ┌────────┐                                   │
│  │Detail1 │ │Detail2 │  ... (detail pages)              │
│  └────────┘ └────────┘                                   │
└─────────────────────────────────────────────────────────────┘
```

**All 14 pages:**
1. ❌ GodModeLoginPage
2. ❌ GodModeDashboardPage
3. ❌ UserDataViewerPage
4. ❌ UserProgressViewerPage
5. ❌ UserPredictionsViewerPage
6. ❌ BusinessAccountsViewerPage
7. ❌ CommunicationsViewerPage
8. ❌ ClubsCommunitiesViewerPage
9. ❌ AILiveMapPage
10. ❌ UserDetailPage
11. ❌ ConnectionCommunicationDetailPage
12. ❌ ClubDetailPage
13. ❌ FraudReviewPage
14. ❌ ReviewFraudReviewPage

---

## 📊 **ACCESS MATRIX**

### **By Authentication Type:**

| Page Category | Auth System | Router Path | Access Method |
|---------------|-------------|-------------|---------------|
| **User Pages** | AuthBloc | ✅ Yes | Via router |
| **Expert Pages** | AuthBloc | ✅ Yes | Via router |
| **AI2AI Admin** | AuthBloc | ✅ Yes | `/admin/ai2ai` |
| **God Mode** | AdminAuthService | ❌ No | Direct navigation |
| **Business Pages** | AuthBloc + Flag | ✅ Yes | Via router |

### **By User Role:**

| User Type | Regular | Expert | Admin | God Mode |
|-----------|---------|--------|-------|----------|
| **Regular** | ✅ | ✅ (own) | ❌ | ❌ |
| **Expert** | ✅ | ✅ (own) | ❌ | ❌ |
| **Business** | ✅ | ✅ (own) | ❌ | ❌ |
| **Admin** | ✅ | ✅ (own) | ✅ | ❌ |
| **God Mode** | ✅ | ✅ (own) | ✅ | ✅ |

---

## 🔑 **KEY INSIGHTS**

### **1. God Mode is Completely Isolated**

- **Separate authentication system** (AdminAuthService)
- **Not in router** - no URL access
- **No navigation path** from main app
- **Direct navigation only** - must be accessed via code
- **14 pages** not integrated

### **2. Expert Pages are Integrated**

- **Uses regular user auth** (AuthBloc)
- **In router** - `/profile/expertise-dashboard`
- **Accessible to all users** - shows own expertise
- **Achievement-based** - not authentication-based

### **3. Admin Pages are Mixed**

- **AI2AIAdminDashboard** - In router (`/admin/ai2ai`)
- **God mode pages** - Not in router
- **Fraud review pages** - Not in router

### **4. Different Auth = Different Access**

- **User auth** → Regular pages + expertise dashboard
- **Admin auth** → God mode pages (separate system)
- **Expert status** → Expert features (no special auth)

---

## 🎯 **HOW TO ACCESS GOD MODE**

### **Current Method (Isolated):**

```dart
// Must navigate directly via code
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GodModeLoginPage(),
  ),
);
```

**No UI path exists** - must be added programmatically.

### **Potential Integration Options:**

**Option 1: Add to ProfilePage (Hidden)**
- Add hidden button/gesture in ProfilePage
- Only visible to admins
- Navigate to GodModeLoginPage

**Option 2: Add to Router (Secure)**
- Add route: `/admin/god-mode/login`
- Add auth guard
- Redirect if not admin

**Option 3: Keep Isolated (Current)**
- Most secure
- Prevents accidental access
- Requires explicit code navigation

---

**Last Updated:** December 12, 2025  
**Status:** Complete visual flow diagram

