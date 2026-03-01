# SPOTS App Navigation Flowchart - Visual Diagram

**Date:** December 12, 2025  
**Purpose:** Visual flowchart showing all pages, navigation paths, and visible content

---

## 🎨 **MAIN NAVIGATION FLOW**

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                              │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  AuthWrapper    │
                    │       (/)       │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼───────┐         ┌───────▼───────┐
        │  Authenticated │         │Unauthenticated│
        │      YES       │         │      NO       │
        └───────┬───────┘         └───────┬───────┘
                │                         │
                │                         ▼
                │              ┌──────────────────┐
                │              │   LoginPage      │
                │              │    (/login)     │
                │              └────────┬─────────┘
                │                       │
                │              ┌────────┴─────────┐
                │              │                  │
                │      ┌───────▼──────┐  ┌───────▼──────┐
                │      │  SignupPage  │  │  LoginPage    │
                │      │   (/signup)  │◄─┤   (/login)    │
                │      └───────┬──────┘  └───────────────┘
                │              │
                │              └──────────────┐
                │                             │
                │                             ▼
                │              ┌──────────────────────────┐
                │              │   OnboardingPage         │
                │              │    (/onboarding)         │
                │              │  [Multi-step process]    │
                │              └────────────┬─────────────┘
                │                           │
                │                           ▼
                │              ┌──────────────────────────┐
                │              │   AILoadingPage          │
                │              │    (/ai-loading)        │
                │              └────────────┬─────────────┘
                │                           │
                └───────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │    HomePage     │
                    │     (/home)     │
                    │ [Bottom Nav Bar]│
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Map Tab    │    │  Spots Tab   │    │ Explore Tab  │
│   (Index 0)  │    │  (Index 1)   │    │  (Index 2)   │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
   [MapView]         [Lists View]         [Explore View]
```

---

## 🏠 **HOMEPAGE TABS DETAILED**

### **Tab 0: Map Tab**
```
Map Tab
    │
    ├─→ MapView Widget
    │   ├─→ Map display
    │   ├─→ Spot markers
    │   ├─→ Current location
    │   ├─→ Search bar
    │   ├─→ List filter
    │   ├─→ Boundary toggle
    │   ├─→ Theme selector
    │   └─→ My location button
    │
    └─→ Navigation:
        ├─→ SpotDetailsPage (marker tap)
        ├─→ HybridSearchPage (search)
        └─→ Profile menu (avatar)
```

### **Tab 1: Spots Tab**
```
Spots Tab
    │
    ├─→ App Bar
    │   ├─→ "My Lists" title
    │   └─→ Avatar icon (profile menu)
    │
    ├─→ Search Bar
    │   └─→ "Search lists..."
    │
    ├─→ Tab Bar
    │   ├─→ "My Lists" tab
    │   └─→ "Respected Lists" tab
    │
    ├─→ My Lists Tab Content
    │   ├─→ List cards
    │   │   ├─→ List title
    │   │   ├─→ Description
    │   │   ├─→ Spot count
    │   │   └─→ Respect count
    │   └─→ Empty state (if no lists)
    │
    └─→ Respected Lists Tab Content
        ├─→ Respected spot cards
        └─→ Empty state (if none)
    
    Navigation:
    ├─→ ListDetailsPage (list tap)
    └─→ Profile menu (avatar)
```

### **Tab 2: Explore Tab**
```
Explore Tab
    │
    ├─→ App Bar
    │   ├─→ "Explore" title
    │   ├─→ Avatar icon (profile menu)
    │   └─→ Tab Bar
    │       ├─→ Users tab
    │       ├─→ AI tab
    │       └─→ Events tab
    │
    ├─→ Users SubTab
    │   ├─→ Public lists from users
    │   ├─→ List cards with respect count
    │   └─→ Empty state
    │
    ├─→ AI SubTab
    │   ├─→ AI Features Section
    │   │   ├─→ Hybrid Search card
    │   │   └─→ AI Assistant card (active)
    │   ├─→ Chat messages
    │   ├─→ Welcome message
    │   └─→ Universal AI Search bar
    │
    └─→ Events SubTab
        └─→ EventsBrowsePage content
    
    Navigation:
    ├─→ ListDetailsPage (public list tap)
    ├─→ HybridSearchPage (Hybrid Search card)
    ├─→ EventDetailsPage (event tap)
    └─→ Profile menu (avatar)
```

---

## 📍 **SPOTS & LISTS FLOW**

```
SpotsPage (/spots)
    │
    ├─→ App Bar: "Spots" + Offline indicator
    ├─→ Search Bar: "Search spots..."
    ├─→ Spots List
    │   └─→ Spot Cards
    └─→ FAB (+)
        │
        ├─→ CreateSpotPage
        │   ├─→ Name input
        │   ├─→ Description input
        │   ├─→ Category selector
        │   ├─→ Location picker
        │   └─→ Create button
        │       │
        │       └─→ SpotDetailsPage
        │
        └─→ SpotDetailsPage (spot tap)
            ├─→ Spot name
            ├─→ Description
            ├─→ Category
            ├─→ Location
            ├─→ Map view
            ├─→ Edit button (if owner)
            └─→ Delete button (if owner)
                │
                └─→ EditSpotPage
                    └─→ SpotDetailsPage (after save)

ListsPage (/lists)
    │
    ├─→ App Bar: "My Lists" + Offline indicator
    ├─→ Lists List
    │   └─→ List Cards
    └─→ FAB (+)
        │
        ├─→ CreateListPage
        │   ├─→ Title input
        │   ├─→ Description input
        │   ├─→ Privacy toggle
        │   └─→ Create button
        │       │
        │       └─→ ListDetailsPage
        │
        └─→ ListDetailsPage (list tap)
            ├─→ List title
            ├─→ Description
            ├─→ Spots in list
            ├─→ Add spot button
            ├─→ Edit button (if owner)
            └─→ Delete button (if owner)
                │
                ├─→ EditListPage
                │   └─→ ListDetailsPage (after save)
                │
                └─→ CreateSpotPage (add spot)
                    └─→ ListDetailsPage (after creation)
```

---

## 👤 **PROFILE & SETTINGS FLOW**

```
ProfilePage (/profile)
    │
    ├─→ User Info Card
    │   ├─→ Avatar (initial)
    │   ├─→ Display name
    │   ├─→ Email
    │   └─→ Online/Offline status
    │
    ├─→ Partnerships Section (if any)
    │
    └─→ Settings Section
        │
        ├─→ Notifications ──→ NotificationsSettingsPage
        ├─→ Privacy ──→ PrivacySettingsPage
        ├─→ Social Media ──→ SocialMediaSettingsPage
        ├─→ Help & Support ──→ HelpSupportPage
        ├─→ About ──→ AboutPage
        │   ├─→ Terms of Service ──→ TermsOfServicePage
        │   └─→ Privacy Policy ──→ PrivacyPolicyPage
        │
        ├─→ AI Status ──→ AIPersonalityStatusPage (/profile/ai-status)
        ├─→ Expertise Dashboard ──→ ExpertiseDashboardPage (/profile/expertise-dashboard)
        ├─→ Partnerships ──→ PartnershipsPage (/profile/partnerships)
        │   ├─→ PartnershipProposalPage
        │   ├─→ PartnershipManagementPage
        │   └─→ PartnershipCheckoutPage
        │
        ├─→ Identity Verification ──→ IdentityVerificationPage
        ├─→ Tax Profile ──→ TaxProfilePage
        ├─→ Tax Documents ──→ TaxDocumentsPage
        │
        ├─→ Discovery Settings ──→ DiscoverySettingsPage (/discovery-settings)
        ├─→ Federated Learning ──→ FederatedLearningPage (/federated-learning)
        ├─→ AI Improvement ──→ AIImprovementPage (/ai-improvement)
        ├─→ AI2AI Learning Methods ──→ AI2AILearningMethodsPage (/ai2ai-learning-methods)
        └─→ Continuous Learning ──→ ContinuousLearningPage (/continuous-learning)
        │
        └─→ Sign Out ──→ LoginPage
```

---

## 🎉 **EVENTS FLOW**

```
EventsBrowsePage (in Explore Tab)
    │
    ├─→ Event cards
    ├─→ Filter options
    ├─→ Search bar
    └─→ Category filters
        │
        ├─→ EventDetailsPage (event tap)
        │   ├─→ Event name
        │   ├─→ Description
        │   ├─→ Date & time
        │   ├─→ Location
        │   ├─→ Host info
        │   ├─→ RSVP button
        │   └─→ Share button
        │       │
        │       ├─→ EventReviewPage (after RSVP)
        │       ├─→ CreateEventPage (if editing)
        │       └─→ CancellationFlowPage (if canceling)
        │
        └─→ CreateEventPage (create button)
            ├─→ Event name input
            ├─→ Description input
            ├─→ Date picker
            ├─→ Time picker
            ├─→ Location picker
            ├─→ Category selector
            └─→ Create button
                │
                └─→ EventPublishedPage
                    └─→ EventDetailsPage
```

---

## 🔍 **SEARCH FLOW**

```
HybridSearchPage (/hybrid-search)
    │
    ├─→ Search bar
    ├─→ Filters
    └─→ Search Results
        ├─→ Community Results
        │   ├─→ Spots
        │   ├─→ Lists
        │   └─→ Events
        │
        └─→ External Data Results
            └─→ Places from external APIs
    
    Navigation:
    ├─→ SpotDetailsPage (spot result tap)
    ├─→ ListDetailsPage (list result tap)
    └─→ EventDetailsPage (event result tap)
```

---

## 🌐 **NETWORK & AI2AI FLOW**

```
DeviceDiscoveryPage (/device-discovery)
    │
    ├─→ Device discovery status
    ├─→ Nearby devices list
    ├─→ Connection options
    └─→ Settings link
        │
        ├─→ AI2AIConnectionsPage (/ai2ai-connections)
        │   ├─→ Active connections
        │   ├─→ Connection status
        │   └─→ Disconnect options
        │
        └─→ DiscoverySettingsPage (/discovery-settings)
            ├─→ Discovery toggle
            ├─→ Visibility settings
            └─→ Privacy options
```

---

## 🏛️ **COMMUNITIES & CLUBS FLOW**

```
CommunityPage (/community/:id)
    │
    ├─→ Community name
    ├─→ Description
    ├─→ Members list
    ├─→ Community events
    └─→ Join/Leave button
        │
        └─→ EventDetailsPage (event tap)

ClubPage (/club/:id)
    │
    ├─→ Club name
    ├─→ Description
    ├─→ Members list
    ├─→ Club activities
    └─→ Join/Leave button
```

---

## 💼 **BUSINESS & BRAND FLOW**

```
BusinessAccountCreationPage
    │
    ├─→ Business info form
    ├─→ Verification documents
    └─→ Create Account button
        │
        └─→ EarningsDashboardPage
            ├─→ Earnings summary
            ├─→ Payment history
            ├─→ Payout settings
            └─→ Tax documents link
                │
                └─→ TaxDocumentsPage

BrandDashboardPage
    │
    ├─→ Brand analytics
    ├─→ Sponsorship management
    └─→ Campaign performance
        │
        ├─→ SponsorshipManagementPage
        ├─→ BrandAnalyticsPage
        └─→ BrandDiscoveryPage
            └─→ SponsorshipCheckoutPage
```

---

## 📊 **COMPLETE PAGE INVENTORY**

### **Authentication (2)**
1. **LoginPage** - Email/password login
2. **SignupPage** - Account creation

### **Onboarding (10)**
1. **OnboardingPage** - Multi-step coordinator
2. **WelcomePage** - Welcome screen
3. **AgeCollectionPage** - Age verification
4. **HomebaseSelectionPage** - Location selection
5. **FavoritePlacesPage** - Favorite places
6. **PreferenceSurveyPage** - Preferences
7. **BaselineListsPage** - Initial lists
8. **FriendsRespectPage** - Respect friends
9. **SocialMediaConnectionPage** - Social connect
10. **AILoadingPage** - AI learning

### **Main App (1 with 3 tabs)**
1. **HomePage** - Main container
   - Map Tab
   - Spots Tab
   - Explore Tab

### **Spots & Lists (8)**
1. **SpotsPage** - Spots list
2. **SpotDetailsPage** - Spot details
3. **CreateSpotPage** - Create spot
4. **EditSpotPage** - Edit spot
5. **ListsPage** - Lists list
6. **ListDetailsPage** - List details
7. **CreateListPage** - Create list
8. **EditListPage** - Edit list

### **Map (1)**
1. **MapPage** - Full map view

### **Profile & Settings (20+)**
1. **ProfilePage** - Main profile
2. **AIPersonalityStatusPage** - AI status
3. **ExpertiseDashboardPage** - Expertise
4. **PartnershipsPage** - Partnerships
5. **NotificationsSettingsPage** - Notifications
6. **PrivacySettingsPage** - Privacy
7. **SocialMediaSettingsPage** - Social media
8. **HelpSupportPage** - Help
9. **AboutPage** - About
10. **DiscoverySettingsPage** - Discovery
11. **FederatedLearningPage** - Federated learning
12. **AIImprovementPage** - AI improvement
13. **AI2AILearningMethodsPage** - Learning methods
14. **ContinuousLearningPage** - Continuous learning
15. **IdentityVerificationPage** - Verification
16. **TaxProfilePage** - Tax profile
17. **TaxDocumentsPage** - Tax docs
18. **TermsOfServicePage** - Terms
19. **PrivacyPolicyPage** - Privacy policy
20. + More...

### **Search (1)**
1. **HybridSearchPage** - Hybrid search

### **Events (9)**
1. **EventsBrowsePage** - Browse events
2. **EventDetailsPage** - Event details
3. **CreateEventPage** - Create event
4. **EventPublishedPage** - Event published
5. **EventReviewPage** - Event review
6. **MyEventsPage** - My events
7. **CreateCommunityEventPage** - Community event
8. **QuickEventBuilderPage** - Quick event
9. **CancellationFlowPage** - Cancel event

### **Network & AI2AI (3)**
1. **DeviceDiscoveryPage** - Device discovery
2. **AI2AIConnectionsPage** - AI2AI connections
3. **DiscoverySettingsPage** - Discovery settings

### **Communities & Clubs (2)**
1. **CommunityPage** - Community view
2. **ClubPage** - Club view

### **Business & Brand (6)**
1. **BusinessAccountCreationPage** - Create business
2. **EarningsDashboardPage** - Earnings
3. **BrandDashboardPage** - Brand dashboard
4. **BrandDiscoveryPage** - Brand discovery
5. **BrandAnalyticsPage** - Brand analytics
6. **SponsorshipManagementPage** - Sponsorships

### **Partnerships (4)**
1. **PartnershipProposalPage** - Propose
2. **PartnershipManagementPage** - Manage
3. **PartnershipCheckoutPage** - Checkout
4. **PartnershipAcceptancePage** - Accept

### **Admin (12+)**
1. **AI2AIAdminDashboard** - AI2AI admin
2. **GodModeDashboardPage** - God mode
3. **UserDataViewerPage** - User data
4. + More admin pages...

### **Legal (3)**
1. **TermsOfServicePage** - Terms
2. **PrivacyPolicyPage** - Privacy
3. **EventWaiverPage** - Event waiver

### **Other (5+)**
1. **SupabaseTestPage** - Dev test
2. **DisputeSubmissionPage** - Disputes
3. **ActionHistoryPage** - Action history
4. + More...

**Total: 80+ pages**

---

## 🔑 **KEY NAVIGATION PATTERNS**

### **1. Bottom Navigation (HomePage)**
- **Always visible** on HomePage
- **3 tabs:** Map, Spots, Explore
- **Switches content** without navigation

### **2. Profile Menu**
- **Accessible from:** Avatar icon in multiple pages
- **Shows:** User info, Sign out
- **Modal bottom sheet**

### **3. Back Navigation**
- **Standard:** Navigator.pop()
- **Router:** context.go() for deep navigation
- **Most pages** support back

### **4. Deep Links**
- **Profile:** `/profile/ai-status`, `/profile/expertise-dashboard`
- **Communities:** `/community/:id`
- **Clubs:** `/club/:id`
- **Admin:** `/admin/ai2ai`

---

## 📱 **VISIBILITY MATRIX**

### **Always Visible:**
- Bottom navigation (on HomePage)
- App bar (on most pages)
- Offline indicator (when offline)

### **Conditional Visibility:**
- **Profile menu:** Only when authenticated
- **Create/Edit buttons:** Only for owned content
- **Admin pages:** Only for admins
- **Business pages:** Only for business accounts
- **FAB:** Only on list/spot pages

### **Permission-Based:**
- **MapPage:** Requires location permission
- **DeviceDiscoveryPage:** Requires connectivity permissions
- **Some features:** Require specific permissions

---

## 🎯 **QUICK NAVIGATION REFERENCE**

### **From HomePage:**
- **Map Tab** → MapView → SpotDetailsPage
- **Spots Tab** → ListDetailsPage → SpotDetailsPage
- **Explore Tab** → ListDetailsPage / EventDetailsPage / HybridSearchPage
- **Avatar** → Profile menu → ProfilePage

### **From ProfilePage:**
- **Settings** → Various settings pages
- **AI Status** → AIPersonalityStatusPage
- **Expertise** → ExpertiseDashboardPage
- **Partnerships** → PartnershipsPage
- **Sign Out** → LoginPage

### **From Any Page:**
- **Back button** → Previous page
- **Search** → HybridSearchPage
- **Profile menu** → ProfilePage

---

**Last Updated:** December 12, 2025  
**Total Pages:** 80+  
**Main Navigation:** Bottom tabs (3) + Profile menu  
**Documentation:** Complete navigation map

