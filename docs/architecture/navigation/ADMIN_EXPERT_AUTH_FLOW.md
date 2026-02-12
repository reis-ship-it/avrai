# Admin, God Mode, and Expert Pages - Authentication & Access Flow

**Date:** December 12, 2025  
**Purpose:** Complete explanation of admin pages, god mode pages, expert pages, and how different authentication leads to different pages

---

## 🔐 **AUTHENTICATION TYPES**

SPOTS has **three distinct authentication systems** that lead to different page access:

1. **User Authentication** (AuthBloc) - Standard user login
2. **Admin Authentication** (AdminAuthService) - God-mode admin login
3. **Expert Status** (ExpertiseService) - Based on expertise achievements

---

## 👤 **USER AUTHENTICATION FLOW**

### **Standard User Login**
```
LoginPage (/login)
    ↓
AuthBloc.authenticate()
    ↓
Authenticated State
    ↓
HomePage (/home)
    ├─→ Map Tab
    ├─→ Spots Tab
    └─→ Explore Tab
        └─→ ProfilePage (/profile)
            └─→ ExpertiseDashboardPage (/profile/expertise-dashboard)
```

**Accessible Pages:**
- All main app pages (HomePage, Spots, Lists, Map, etc.)
- ProfilePage and all settings pages
- **ExpertiseDashboardPage** - Available to ALL users (shows their expertise)
- Community pages
- Event pages
- Search pages

**Note:** ExpertiseDashboardPage is **NOT restricted** - all users can see their own expertise profile.

---

## 🔴 **GOD MODE ADMIN AUTHENTICATION**

### **Separate Authentication System**

God Mode uses a **completely separate authentication system** from regular users:

```
GodModeLoginPage (NOT in router - direct navigation)
    ↓
AdminAuthService.authenticate()
    ↓
AdminSession (8-hour session)
    ↓
GodModeDashboardPage (NOT in router - direct navigation)
    ├─→ Dashboard Tab
    ├─→ FL Rounds Tab
    ├─→ Users Tab → UserDataViewerPage
    ├─→ Progress Tab → UserProgressViewerPage
    ├─→ Predictions Tab → UserPredictionsViewerPage
    ├─→ Businesses Tab → BusinessAccountsViewerPage
    ├─→ Communications Tab → CommunicationsViewerPage
    ├─→ Clubs Tab → ClubsCommunitiesViewerPage
    └─→ AI Map Tab → AILiveMapPage
```

### **God Mode Features:**

**Authentication:**
- Separate login page (`GodModeLoginPage`)
- Username/password authentication
- Optional 2FA support
- 8-hour session expiration
- Account lockout (5 failed attempts = 15 min lockout)
- Session stored in SharedPreferences

**Access Level:**
- `AdminAccessLevel.godMode` - Full access
- All permissions enabled (`AdminPermissions.all()`)

**Dashboard Tabs (9 tabs):**
1. **Dashboard** - System health metrics
2. **FL Rounds** - Federated learning rounds
3. **Users** - User data viewer
4. **Progress** - User progress viewer
5. **Predictions** - User predictions viewer
6. **Businesses** - Business accounts viewer
7. **Communications** - Communications viewer
8. **Clubs** - Clubs & communities viewer
9. **AI Map** - AI live map

### **⚠️ CRITICAL: God Mode Pages NOT in Router**

**God Mode pages are NOT integrated into the main app router!**

They use **direct Navigator.push()** navigation:
- `GodModeLoginPage` → `GodModeDashboardPage`
- No route paths defined
- Cannot be accessed via URL/deep link
- Must navigate directly via code

**Why?**
- Security: Prevents accidental exposure
- Isolation: Separate from user app
- Direct access: Only via explicit navigation

---

## 🎓 **EXPERT PAGES & EXPERTISE SYSTEM**

### **Expertise-Based Access**

Expert pages are **NOT gated by authentication** - they're based on **expertise achievements**:

```
ExpertiseDashboardPage (/profile/expertise-dashboard)
    │
    ├─→ Available to ALL users
    ├─→ Shows user's own expertise
    ├─→ Expertise pins by category
    ├─→ Progress tracking
    ├─→ Multi-path expertise display
    └─→ Partnership expertise boosts
```

### **Expert Status Types:**

1. **Local Expert** - Expertise in a specific locality
2. **City Expert** - Expertise at city level
3. **Regional Expert** - Expertise at regional level
4. **National Expert** - Expertise at national level
5. **Global Expert** - Expertise at global level
6. **Universal Expert** - Universal expertise
7. **Golden Local Expert** - 25+ years residency in locality

### **Expert Features:**

**ExpertiseDashboardPage:**
- Shows all expertise pins
- Progress by category
- Multi-path expertise (6 paths)
- Partnership expertise boosts
- Golden expert indicators

**Expertise-Based UI Elements:**
- Golden expert badges (in communities/clubs)
- Expertise level indicators
- Geographic scope indicators
- Expert recommendations

**Access:**
- **No special authentication required**
- All users can view their own expertise
- Expertise is **earned**, not granted
- Based on contributions, respect, reviews, etc.

---

## 📋 **PAGES NOT INTEGRATED INTO ROUTER**

### **God Mode Pages (NOT in Router):**

1. **GodModeLoginPage** ❌
   - No route path
   - Direct navigation only
   - Access: `Navigator.push(MaterialPageRoute(builder: (c) => GodModeLoginPage()))`

2. **GodModeDashboardPage** ❌
   - No route path
   - Direct navigation only
   - Access: From `GodModeLoginPage` after authentication

3. **UserDataViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Users tab)
   - Access: Via god mode dashboard

4. **UserProgressViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Progress tab)
   - Access: Via god mode dashboard

5. **UserPredictionsViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Predictions tab)
   - Access: Via god mode dashboard

6. **BusinessAccountsViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Businesses tab)
   - Access: Via god mode dashboard

7. **CommunicationsViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Communications tab)
   - Access: Via god mode dashboard

8. **ClubsCommunitiesViewerPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (Clubs tab)
   - Access: Via god mode dashboard

9. **AILiveMapPage** ❌
   - No route path
   - Embedded in `GodModeDashboardPage` (AI Map tab)
   - Access: Via god mode dashboard

10. **UserDetailPage** ❌
    - No route path
    - Access: From `UserDataViewerPage` (tap user)
    - Direct navigation only

11. **ConnectionCommunicationDetailPage** ❌
    - No route path
    - Access: From `CommunicationsViewerPage` (tap communication)
    - Direct navigation only

12. **ClubDetailPage** ❌
    - No route path
    - Access: From `ClubsCommunitiesViewerPage` (tap club)
    - Direct navigation only

### **Admin Pages (Partially Integrated):**

1. **AI2AIAdminDashboard** ✅
   - Route: `/admin/ai2ai`
   - **ONLY admin page in router**
   - Access: Via URL or navigation

2. **FraudReviewPage** ❌
   - No route path
   - Direct navigation only
   - Access: From event review flow

3. **ReviewFraudReviewPage** ❌
   - No route path
   - Direct navigation only
   - Access: From fraud review flow

### **Expert Pages (Integrated):**

1. **ExpertiseDashboardPage** ✅
   - Route: `/profile/expertise-dashboard`
   - **Fully integrated**
   - Access: From ProfilePage → "Expertise Dashboard"

---

## 🔄 **HOW DIFFERENT AUTH LEADS TO DIFFERENT PAGES**

### **Scenario 1: Regular User**

```
User opens app
    ↓
AuthWrapper checks AuthBloc
    ↓
Authenticated? YES
    ↓
Onboarding complete? YES
    ↓
HomePage (/home)
    ↓
ProfilePage → ExpertiseDashboardPage
```

**Access:**
- ✅ All main app pages
- ✅ ExpertiseDashboardPage (their own)
- ❌ God Mode pages
- ❌ Admin pages (except AI2AIAdminDashboard if they have access)

---

### **Scenario 2: Admin User (God Mode)**

```
Admin opens app
    ↓
Navigates to GodModeLoginPage (direct navigation)
    ↓
AdminAuthService.authenticate()
    ↓
AdminSession created
    ↓
GodModeDashboardPage (direct navigation)
    ↓
9 tabs with admin views
```

**Access:**
- ✅ God Mode Dashboard (9 tabs)
- ✅ All god mode viewer pages
- ✅ Real-time system data
- ✅ User data, progress, predictions
- ✅ Business accounts
- ✅ Communications
- ✅ Clubs & communities
- ✅ AI live map
- ❌ Regular user pages (separate session)

**Note:** Admin can have BOTH:
- Regular user session (AuthBloc)
- Admin session (AdminAuthService)
- These are **separate** and **independent**

---

### **Scenario 3: Expert User**

```
Expert user (has expertise achievements)
    ↓
Regular user authentication
    ↓
HomePage
    ↓
ProfilePage
    ↓
ExpertiseDashboardPage
    ↓
Shows expertise pins, progress, golden expert status
```

**Access:**
- ✅ All regular user pages
- ✅ ExpertiseDashboardPage (shows their expertise)
- ✅ Golden expert indicators (if applicable)
- ✅ Expert-level event hosting (based on expertise)
- ❌ God Mode pages (unless also admin)
- ❌ Admin pages (unless also admin)

**Expert Status:**
- **Not authentication-based**
- **Achievement-based**
- Earned through contributions
- Visible in ExpertiseDashboardPage

---

### **Scenario 4: Business Account**

```
Business user
    ↓
Regular user authentication
    ↓
Has business account flag
    ↓
HomePage
    ↓
ProfilePage
    ↓
BusinessAccountCreationPage (if not created)
    ↓
EarningsDashboardPage (if created)
```

**Access:**
- ✅ All regular user pages
- ✅ Business account pages
- ✅ Earnings dashboard
- ✅ Tax documents
- ❌ God Mode pages (unless also admin)
- ❌ Admin pages (unless also admin)

---

## 🚨 **PAGES MISSING FROM NAVIGATION FLOW**

### **God Mode Pages (14 pages):**

**Not in router, not accessible via navigation flow:**

1. `GodModeLoginPage` - Entry point for god mode
   - **NO navigation path from main app**
   - Must be accessed via direct code: `Navigator.push(MaterialPageRoute(builder: (c) => GodModeLoginPage()))`
   - Completely isolated

2. `GodModeDashboardPage` - Main dashboard
   - Accessible only from `GodModeLoginPage` after authentication
   - 9 tabs with embedded viewer pages

3. `UserDataViewerPage` - User data viewer
   - Embedded in GodModeDashboardPage (Users tab)
   - No standalone route

4. `UserProgressViewerPage` - Progress viewer
   - Embedded in GodModeDashboardPage (Progress tab)
   - No standalone route

5. `UserPredictionsViewerPage` - Predictions viewer
   - Embedded in GodModeDashboardPage (Predictions tab)
   - No standalone route

6. `BusinessAccountsViewerPage` - Business accounts
   - Embedded in GodModeDashboardPage (Businesses tab)
   - No standalone route

7. `CommunicationsViewerPage` - Communications
   - Embedded in GodModeDashboardPage (Communications tab)
   - No standalone route

8. `ClubsCommunitiesViewerPage` - Clubs & communities
   - Embedded in GodModeDashboardPage (Clubs tab)
   - No standalone route

9. `AILiveMapPage` - AI live map
   - Embedded in GodModeDashboardPage (AI Map tab)
   - No standalone route

10. `UserDetailPage` - User detail view
    - Accessible from `UserDataViewerPage` (tap user)
    - Direct navigation only

11. `ConnectionCommunicationDetailPage` - Communication detail
    - Accessible from `CommunicationsViewerPage` (tap communication)
    - Direct navigation only

12. `ClubDetailPage` - Club detail view
    - Accessible from `ClubsCommunitiesViewerPage` (tap club)
    - Direct navigation only

13. `FraudReviewPage` - Fraud review (admin)
    - Accessible from event review flow
    - Direct navigation only

14. `ReviewFraudReviewPage` - Review fraud review (admin)
    - Accessible from fraud review flow
    - Direct navigation only

**How to Access:**
- **GodModeLoginPage:** Must navigate directly via code (no UI path)
- **All other god mode pages:** Via GodModeDashboardPage tabs
- **No URL/deep link access**
- **No UI navigation path from main app**
- **Completely isolated system**

---

## 🔗 **INTEGRATION STATUS**

### **✅ Fully Integrated Pages:**

1. **AI2AIAdminDashboard** - `/admin/ai2ai`
2. **ExpertiseDashboardPage** - `/profile/expertise-dashboard`

### **❌ NOT Integrated Pages:**

**God Mode System (13 pages):**
- All god mode pages use direct navigation
- Not in router
- Separate authentication system
- Isolated from main app

**Why Not Integrated?**
- **Security:** Prevents accidental exposure
- **Isolation:** Separate admin system
- **Access Control:** Requires explicit navigation
- **Privacy:** God mode is sensitive

---

## 🎯 **ACCESS CONTROL SUMMARY**

### **By Authentication Type:**

| Page Type | Auth Required | Router Path | Access Method |
|-----------|---------------|-------------|---------------|
| **User Pages** | AuthBloc | ✅ Yes | Via router |
| **Expert Pages** | AuthBloc | ✅ Yes | Via router |
| **AI2AI Admin** | AuthBloc | ✅ Yes | `/admin/ai2ai` |
| **God Mode** | AdminAuthService | ❌ No | Direct navigation |
| **Business Pages** | AuthBloc + Business flag | ✅ Yes | Via router |

### **By User Role:**

| User Type | Regular Pages | Expert Pages | Admin Pages | God Mode |
|-----------|---------------|--------------|-------------|----------|
| **Regular User** | ✅ | ✅ (own) | ❌ | ❌ |
| **Expert User** | ✅ | ✅ (own) | ❌ | ❌ |
| **Business User** | ✅ | ✅ (own) | ❌ | ❌ |
| **Admin User** | ✅ | ✅ (own) | ✅ | ❌ |
| **God Mode Admin** | ✅ | ✅ (own) | ✅ | ✅ |

---

## 🔐 **SECURITY IMPLICATIONS**

### **God Mode Security:**

1. **Separate Authentication**
   - Different auth system
   - Different session management
   - No connection to user auth

2. **No Router Integration**
   - Cannot be accessed via URL
   - Cannot be deep linked
   - Must navigate explicitly

3. **Session Management**
   - 8-hour expiration
   - Account lockout protection
   - Secure credential storage

4. **Privacy Protection**
   - "Privacy: IDs Only" display
   - Data anonymization
   - Audit logging

### **Expert Pages Security:**

1. **No Special Auth Required**
   - Uses regular user auth
   - Shows only own expertise
   - No cross-user access

2. **Achievement-Based**
   - Cannot be granted manually
   - Based on contributions
   - Transparent criteria

---

## 📊 **COMPLETE PAGE INVENTORY**

### **Admin Pages (15 total):**

**In Router:**
1. ✅ `AI2AIAdminDashboard` - `/admin/ai2ai`

**NOT in Router (God Mode):**
2. ❌ `GodModeLoginPage`
3. ❌ `GodModeDashboardPage`
4. ❌ `UserDataViewerPage`
5. ❌ `UserProgressViewerPage`
6. ❌ `UserPredictionsViewerPage`
7. ❌ `BusinessAccountsViewerPage`
8. ❌ `CommunicationsViewerPage`
9. ❌ `ClubsCommunitiesViewerPage`
10. ❌ `AILiveMapPage`
11. ❌ `UserDetailPage`
12. ❌ `ConnectionCommunicationDetailPage`
13. ❌ `ClubDetailPage`
14. ❌ `FraudReviewPage`
15. ❌ `ReviewFraudReviewPage`

### **Expert Pages (1 total):**

**In Router:**
1. ✅ `ExpertiseDashboardPage` - `/profile/expertise-dashboard`

**Expert-Related Widgets (not pages):**
- `GoldenExpertIndicator` - Widget, not page
- `ExpertiseDisplayWidget` - Widget, not page
- `MultiPathExpertiseWidget` - Widget, not page

---

## 🎯 **RECOMMENDATIONS**

### **For God Mode Integration:**

**Option 1: Keep Isolated (Current)**
- ✅ Most secure
- ✅ Prevents accidental access
- ❌ Not discoverable
- ❌ No deep linking

**Option 2: Add to Router (Secure)**
- ✅ Deep linking support
- ✅ Better navigation
- ⚠️ Requires auth guards
- ⚠️ Must protect routes

**Option 3: Hybrid Approach**
- ✅ Keep login isolated
- ✅ Add dashboard to router (with auth guard)
- ✅ Best of both worlds

### **For Missing Pages:**

**Pages that should be integrated:**
1. `FraudReviewPage` - Should be accessible from event review
2. `ReviewFraudReviewPage` - Should be accessible from fraud review
3. `UserDetailPage` - Could be `/admin/user/:id` (with auth guard)

---

## 📝 **SUMMARY**

### **Key Findings:**

1. **God Mode is Completely Isolated**
   - Separate auth system
   - Not in router
   - Direct navigation only
   - 13 pages not integrated

2. **Expert Pages are Integrated**
   - ExpertiseDashboardPage is in router
   - Accessible to all users
   - Shows own expertise only

3. **Admin Pages are Mixed**
   - AI2AIAdminDashboard is in router
   - God mode pages are not
   - Fraud review pages are not

4. **Different Auth = Different Access**
   - User auth → Regular pages
   - Admin auth → God mode pages
   - Expert status → Expert features (no special auth)

### **Access Patterns:**

- **Regular User:** HomePage → ProfilePage → ExpertiseDashboardPage
- **Admin User:** GodModeLoginPage → GodModeDashboardPage → Admin views
- **Expert User:** Same as regular + expertise features
- **Business User:** Same as regular + business pages

---

**Last Updated:** December 12, 2025  
**Status:** Complete analysis of admin, god mode, and expert pages

