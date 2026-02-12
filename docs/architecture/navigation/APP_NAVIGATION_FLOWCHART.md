# SPOTS App Navigation Flowchart

**Date:** December 12, 2025  
**Purpose:** Complete navigation map of all pages, their relationships, and visible content

---

## 📱 **APP ENTRY POINT**

```
App Launch
    │
    ▼
AuthWrapper (/)
    │
    ├─→ Authenticated? ──NO──→ LoginPage (/login)
    │                          │
    │                          └─→ SignupPage (/signup)
    │
    └─→ YES
        │
        ├─→ Onboarding Complete? ──NO──→ OnboardingPage (/onboarding)
        │
        └─→ YES ──→ HomePage (/home)
```

---

## 🔐 **AUTHENTICATION FLOW**

### **LoginPage** (`/login`)
**Visible:**
- Email input field
- Password input field
- "Sign In" button
- Link to "Create Account" (→ SignupPage)
- Error messages (if login fails)

**Navigation:**
- → SignupPage (`/signup`)
- → HomePage (`/home`) - on successful login
- → OnboardingPage (`/onboarding`) - if onboarding not completed

---

### **SignupPage** (`/signup`)
**Visible:**
- Email input field
- Password input field
- Confirm password field
- Display name field
- "Create Account" button
- Link to "Sign In" (→ LoginPage)
- Error messages (if signup fails)

**Navigation:**
- → LoginPage (`/login`)
- → OnboardingPage (`/onboarding`) - on successful signup
- → HomePage (`/home`) - if already onboarded

---

## 🎯 **ONBOARDING FLOW**

### **OnboardingPage** (`/onboarding`)
**Multi-step onboarding process:**

**Step 1: Welcome**
- Welcome message
- "Get Started" button

**Step 2: Permissions**
- Location permission request
- Connectivity permission request
- "Continue" button

**Step 3: Age Collection**
- Birthday picker
- Age verification
- "Continue" button

**Step 4: Homebase Selection**
- Location search/selection
- Map view for location
- "Continue" button

**Step 5: Favorite Places**
- List of favorite places
- Add/remove places
- "Continue" button

**Step 6: Preference Survey**
- Preference questions
- Multiple choice options
- "Continue" button

**Step 7: Baseline Lists**
- Create initial lists
- "Continue" button

**Step 8: Friends Respect**
- Respect friends' lists
- "Continue" button

**Step 9: Social Media Connection** (Optional)
- Connect social accounts
- "Skip" or "Continue" button

**Navigation:**
- → AILoadingPage (`/ai-loading`) - after completion
- → HomePage (`/home`) - after AI loading completes

---

### **AILoadingPage** (`/ai-loading`)
**Visible:**
- Loading animation
- "AI is learning about you..." message
- Progress indicator

**Navigation:**
- → HomePage (`/home`) - automatically after loading

---

## 🏠 **MAIN APP (HomePage)**

### **HomePage** (`/home`)
**Bottom Navigation Tabs:**
1. **Map Tab** (Index 0)
2. **Spots Tab** (Index 1)
3. **Explore Tab** (Index 2)

**Visible:**
- Offline indicator (if offline)
- Bottom navigation bar
- Current tab content

**Navigation:**
- Switch between tabs (Map, Spots, Explore)
- Profile menu (from avatar icon)

---

### **Map Tab** (HomePage Tab 0)
**Visible:**
- Map view with spots
- App bar with "Map" title
- Spot markers on map
- Current location (if permission granted)

**Navigation:**
- → SpotDetailsPage - on marker tap
- → Profile menu - from avatar icon
- → HybridSearchPage - via search

---

### **Spots Tab** (HomePage Tab 1)
**Visible:**
- App bar with "My Lists" title
- Avatar icon (profile menu)
- Search bar ("Search lists...")
- Tab bar:
  - **My Lists** tab
  - **Respected Lists** tab

**My Lists Tab:**
- List of user's lists
- Empty state if no lists
- Search functionality

**Respected Lists Tab:**
- List of respected spots
- Empty state if none

**Navigation:**
- → ListDetailsPage - on list tap
- → Profile menu - from avatar icon
- → CreateSpotPage - via FAB (if on standalone SpotsPage)

---

### **Explore Tab** (HomePage Tab 2)
**Visible:**
- App bar with "Explore" title
- Avatar icon (profile menu)
- Tab bar:
  - **Users** tab
  - **AI** tab
  - **Events** tab
  - **Communities** tab

**Users SubTab:**
- Public lists from other users
- List cards with respect count
- Empty state if no public lists

**AI SubTab:**
- AI-powered features section
- Hybrid Search card
- AI Assistant card (active)
- Chat interface
- Universal AI Search bar
- Welcome message from AI

**Events SubTab:**
- EventsBrowsePage content
- Browse events
- Event cards

**Communities SubTab:**
- CommunitiesDiscoverPage content (embedded)
- Community cards ranked by true compatibility
- Join from discover

**Navigation:**
- → ListDetailsPage - on public list tap
- → HybridSearchPage - from Hybrid Search card
- → Profile menu - from avatar icon
- → EventDetailsPage - on event tap
- → CommunitiesDiscoverPage - via Explore → Communities tab

---

## 📍 **SPOTS & LISTS PAGES**

### **SpotsPage** (`/spots`)
**Visible:**
- App bar with "Spots" title
- Offline indicator (in app bar)
- Search bar ("Search spots...")
- List of spot cards:
  - Spot name
  - Category icon
  - Description
  - Location
- Empty state (if no spots)
- Loading state
- Error state with retry
- Floating Action Button (+) - Create new spot

**Navigation:**
- → CreateSpotPage - via FAB
- → SpotDetailsPage - on spot tap

---

### **SpotDetailsPage**
**Visible:**
- Spot name
- Spot description
- Category
- Location
- Map view
- Edit button (if owner)
- Delete button (if owner)

**Navigation:**
- → EditSpotPage - via edit button
- ← Back to previous page

---

### **CreateSpotPage**
**Visible:**
- Name input
- Description input
- Category selector
- Location picker
- "Create" button
- "Cancel" button

**Navigation:**
- → SpotDetailsPage - after creation
- ← Back to previous page

---

### **EditSpotPage**
**Visible:**
- Pre-filled name input
- Pre-filled description input
- Category selector
- Location picker
- "Save" button
- "Cancel" button

**Navigation:**
- → SpotDetailsPage - after save
- ← Back to previous page

---

### **ListsPage** (`/lists`)
**Visible:**
- App bar with "My Lists" title
- Offline indicator (in app bar)
- List of list cards:
  - List title
  - Description
  - Spot count
  - Privacy indicator
- Empty state (if no lists)
- Loading state
- Error state with retry
- Floating Action Button (+) - Create new list

**Navigation:**
- → ListDetailsPage - on list tap
- → CreateListPage - via FAB

---

### **ListDetailsPage**
**Visible:**
- List title
- List description
- List of spots in list
- Add spot button
- Edit button (if owner)
- Delete button (if owner)
- Respect count

**Navigation:**
- → SpotDetailsPage - on spot tap
- → CreateSpotPage - via add spot
- → EditListPage - via edit button

---

### **CreateListPage**
**Visible:**
- Title input
- Description input
- Privacy toggle
- "Create" button
- "Cancel" button

**Navigation:**
- → ListDetailsPage - after creation
- ← Back to previous page

---

### **EditListPage**
**Visible:**
- Pre-filled title input
- Pre-filled description input
- Privacy toggle
- "Save" button
- "Cancel" button

**Navigation:**
- → ListDetailsPage - after save
- ← Back to previous page

---

## 🗺️ **MAP PAGE**

### **MapPage** (`/map`)
**Visible:**
- Full-screen map view
- App bar with "Map" title
- Avatar icon (profile menu)
- Search bar with suggestions
- Spot markers (colored by category)
- Current location marker
- List filter dropdown
- Boundary toggle button
- Theme selector button
- My location button
- Offline indicator

**Navigation:**
- → SpotDetailsPage - on marker tap
- → HybridSearchPage - via search
- → Profile menu - from avatar icon

**Note:** Requires location permission. Redirects to onboarding if not granted.

---

## 👤 **PROFILE & SETTINGS**

### **ProfilePage** (`/profile`)
**Visible:**
- User info card:
  - Avatar (initial)
  - Display name
  - Email
  - Online/Offline status
- Partnerships section (if any)
- Settings section:
  - Notifications
  - Privacy
  - Social Media
  - Help & Support
  - About
  - AI Status
  - Expertise Dashboard
  - Partnerships
  - Identity Verification
  - Tax Profile
  - Tax Documents
  - Terms of Service
  - Privacy Policy
  - Discovery Settings
  - Federated Learning
  - AI Improvement
  - AI2AI Learning Methods
  - Continuous Learning
- Sign Out button

**Navigation:**
- → NotificationsSettingsPage
- → PrivacySettingsPage
- → SocialMediaSettingsPage
- → HelpSupportPage
- → AboutPage
- → AIPersonalityStatusPage (`/profile/ai-status`)
- → ExpertiseDashboardPage (`/profile/expertise-dashboard`)
- → PartnershipsPage (`/profile/partnerships`)
- → IdentityVerificationPage
- → TaxProfilePage
- → TaxDocumentsPage
- → TermsOfServicePage
- → PrivacyPolicyPage
- → DiscoverySettingsPage (`/discovery-settings`)
- → FederatedLearningPage (`/federated-learning`)
- → AIImprovementPage (`/ai-improvement`)
- → AI2AILearningMethodsPage (`/ai2ai-learning-methods`)
- → ContinuousLearningPage (`/continuous-learning`)
- → LoginPage - on sign out

---

### **AIPersonalityStatusPage** (`/profile/ai-status`)
**Visible:**
- AI personality status
- Learning progress
- Personality dimensions
- Improvement suggestions

**Navigation:**
- ← Back to ProfilePage

---

### **ExpertiseDashboardPage** (`/profile/expertise-dashboard`)
**Visible:**
- Expertise areas
- Skill levels
- Recommendations
- Learning paths

**Navigation:**
- ← Back to ProfilePage

---

### **PartnershipsPage** (`/profile/partnerships`)
**Visible:**
- Active partnerships
- Partnership proposals
- Partnership history
- Create partnership button

**Navigation:**
- → PartnershipProposalPage
- → PartnershipManagementPage
- → PartnershipCheckoutPage
- ← Back to ProfilePage

---

## 🔍 **SEARCH**

### **HybridSearchPage** (`/hybrid-search`)
**Visible:**
- Search bar
- Search results:
  - Community results
  - External data results
- Filters
- Result cards

**Navigation:**
- → SpotDetailsPage - on spot result tap
- → ListDetailsPage - on list result tap
- → EventDetailsPage - on event result tap
- ← Back to previous page

---

## 🎉 **EVENTS**

### **EventsBrowsePage** (in Explore Tab)
**Visible:**
- Event cards
- Filter options
- Search bar
- Category filters

**Navigation:**
- → EventDetailsPage - on event tap
- → CreateEventPage - via create button

---

### **EventDetailsPage**
**Visible:**
- Event name
- Event description
- Date & time
- Location
- Host information
- RSVP button
- Share button

**Navigation:**
- → EventReviewPage - after RSVP
- → CreateEventPage - if editing
- → CancellationFlowPage - if canceling
- ← Back to EventsBrowsePage

---

### **CreateEventPage**
**Visible:**
- Event name input
- Description input
- Date picker
- Time picker
- Location picker
- Category selector
- "Create" button

**Navigation:**
- → EventPublishedPage - after creation
- ← Back to EventsBrowsePage

---

### **EventPublishedPage**
**Visible:**
- Success message
- Event details
- Share options
- "View Event" button

**Navigation:**
- → EventDetailsPage - via view button
- ← Back to EventsBrowsePage

---

## 🌐 **NETWORK & AI2AI**

### **DeviceDiscoveryPage** (`/device-discovery`)
**Visible:**
- Device discovery status
- Nearby devices list
- Connection options
- Settings link

**Navigation:**
- → AI2AIConnectionsPage
- → DiscoverySettingsPage
- ← Back to previous page

---

### **AI2AIConnectionsPage** (`/ai2ai-connections`)
**Visible:**
- Active AI2AI connections
- Connection status
- Connection details
- Disconnect options

**Navigation:**
- → DeviceDiscoveryPage
- ← Back to previous page

---

### **DiscoverySettingsPage** (`/discovery-settings`)
**Visible:**
- Discovery toggle
- Visibility settings
- Privacy options
- Connection preferences

**Navigation:**
- ← Back to previous page

---

## 🏢 **ADMIN PAGES**

### **AI2AIAdminDashboard** (`/admin/ai2ai`)
**Visible:**
- AI2AI network status
- Connection statistics
- Network health
- Admin controls

**Navigation:**
- ← Back to previous page

---

## 🏛️ **COMMUNITIES & CLUBS**

### **CommunitiesDiscoverPage** (`/communities/discover`)
**Visible:**
- Ranked community list (true compatibility)
- View/Join actions per community
- Pull-to-refresh

**Entry points:**
- Home → Explore Tab → **Communities**
- Direct route: `/communities/discover`

**Navigation:**
- → CommunityPage (`/community/:id`) - on View/Join
- ← Back to previous page

---

### **CommunityPage** (`/community/:id`)
**Visible:**
- Community name
- Community description
- Members list
- Community events
- Join/Leave button

**Navigation:**
- → EventDetailsPage - on event tap
- ← Back to previous page

---

### **ClubPage** (`/club/:id`)
**Visible:**
- Club name
- Club description
- Members list
- Club activities
- Join/Leave button

**Navigation:**
- ← Back to previous page

---

## 💼 **BUSINESS & BRAND**

### **BusinessAccountCreationPage**
**Visible:**
- Business information form
- Verification documents
- "Create Account" button

**Navigation:**
- → EarningsDashboardPage - after creation
- ← Back to previous page

---

### **EarningsDashboardPage**
**Visible:**
- Earnings summary
- Payment history
- Payout settings
- Tax documents link

**Navigation:**
- → TaxDocumentsPage
- ← Back to previous page

---

### **BrandDashboardPage**
**Visible:**
- Brand analytics
- Sponsorship management
- Campaign performance

**Navigation:**
- → SponsorshipManagementPage
- → BrandAnalyticsPage
- ← Back to previous page

---

### **BrandDiscoveryPage**
**Visible:**
- Available brands
- Brand profiles
- Partnership opportunities

**Navigation:**
- → SponsorshipCheckoutPage
- ← Back to previous page

---

## ⚙️ **SETTINGS PAGES**

### **NotificationsSettingsPage**
**Visible:**
- Notification toggles
- Email preferences
- Push notification settings

**Navigation:**
- ← Back to ProfilePage

---

### **PrivacySettingsPage**
**Visible:**
- Privacy toggles
- Data sharing options
- Visibility settings

**Navigation:**
- ← Back to ProfilePage

---

### **SocialMediaSettingsPage**
**Visible:**
- Connected accounts
- Connect/Disconnect buttons
- Sharing preferences

**Navigation:**
- ← Back to ProfilePage

---

### **HelpSupportPage**
**Visible:**
- FAQ section
- Contact support
- Report issue

**Navigation:**
- ← Back to ProfilePage

---

### **AboutPage**
**Visible:**
- App version
- Terms of Service link
- Privacy Policy link
- Credits

**Navigation:**
- → TermsOfServicePage
- → PrivacyPolicyPage
- ← Back to ProfilePage

---

### **FederatedLearningPage** (`/federated-learning`)
**Visible:**
- Federated learning status
- Participation toggle
- Learning statistics

**Navigation:**
- ← Back to ProfilePage

---

### **AIImprovementPage** (`/ai-improvement`)
**Visible:**
- AI improvement status
- Learning progress
- Improvement suggestions

**Navigation:**
- ← Back to ProfilePage

---

### **AI2AILearningMethodsPage** (`/ai2ai-learning-methods`)
**Visible:**
- Learning methods overview
- Method selection
- Configuration options

**Navigation:**
- ← Back to ProfilePage

---

### **ContinuousLearningPage** (`/continuous-learning`)
**Visible:**
- Continuous learning status
- Learning preferences
- Auto-learning toggle

**Navigation:**
- ← Back to ProfilePage

---

## 📄 **LEGAL PAGES**

### **TermsOfServicePage**
**Visible:**
- Terms of Service text
- Accept/Decline buttons

**Navigation:**
- ← Back to previous page

---

### **PrivacyPolicyPage**
**Visible:**
- Privacy Policy text

**Navigation:**
- ← Back to previous page

---

### **EventWaiverPage**
**Visible:**
- Event waiver text
- Accept/Decline buttons

**Navigation:**
- ← Back to EventDetailsPage

---

## 🔄 **COMPLETE NAVIGATION FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────┐
│                    APP LAUNCH                                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ AuthWrapper   │
                │      (/)      │
                └───────┬───────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐              ┌───────────────┐
│  LoginPage    │              │  SignupPage   │
│   (/login)    │◄─────────────┤   (/signup)   │
└───────┬───────┘              └───────┬───────┘
        │                               │
        └───────────────┬───────────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │  OnboardingPage        │
            │   (/onboarding)       │
            │  (Multi-step flow)    │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │  AILoadingPage         │
            │   (/ai-loading)       │
            └───────────┬───────────┘
                        │
                        ▼
            ┌───────────────────────┐
            │    HomePage           │
            │     (/home)           │
            │  [Bottom Nav Tabs]    │
            └───────────┬───────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌───────────┐   ┌───────────┐   ┌───────────┐
│  Map Tab  │   │ Spots Tab │   │Explore Tab│
│           │   │           │   │           │
│  MapView  │   │ My Lists  │   │  Users    │
│  Markers  │   │ Respected │   │  AI       │
│           │   │           │   │  Events   │
└─────┬─────┘   └─────┬─────┘   └─────┬─────┘
      │               │               │
      │               │               │
      └───────────────┼───────────────┘
                      │
                      ▼
            ┌───────────────────────┐
            │   ProfilePage         │
            │    (/profile)         │
            └───────────┬───────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Settings    │ │  AI Status    │ │ Partnerships │
│   Pages      │ │  Expertise    │ │   Pages      │
└──────────────┘ └──────────────┘ └──────────────┘
```

---

## 📊 **PAGE CATEGORIES**

### **Authentication (2 pages)**
1. LoginPage
2. SignupPage

### **Onboarding (10 pages)**
1. OnboardingPage (multi-step)
2. WelcomePage
3. AgeCollectionPage
4. HomebaseSelectionPage
5. FavoritePlacesPage
6. PreferenceSurveyPage
7. BaselineListsPage
8. FriendsRespectPage
9. SocialMediaConnectionPage
10. AILoadingPage

### **Main App (3 tabs)**
1. Map Tab
2. Spots Tab
3. Explore Tab

### **Spots & Lists (8 pages)**
1. SpotsPage
2. SpotDetailsPage
3. CreateSpotPage
4. EditSpotPage
5. ListsPage
6. ListDetailsPage
7. CreateListPage
8. EditListPage

### **Map (1 page)**
1. MapPage

### **Profile & Settings (20+ pages)**
1. ProfilePage
2. AIPersonalityStatusPage
3. ExpertiseDashboardPage
4. PartnershipsPage
5. NotificationsSettingsPage
6. PrivacySettingsPage
7. SocialMediaSettingsPage
8. HelpSupportPage
9. AboutPage
10. DiscoverySettingsPage
11. FederatedLearningPage
12. AIImprovementPage
13. AI2AILearningMethodsPage
14. ContinuousLearningPage
15. IdentityVerificationPage
16. TaxProfilePage
17. TaxDocumentsPage
18. TermsOfServicePage
19. PrivacyPolicyPage
20. + More...

### **Search (1 page)**
1. HybridSearchPage

### **Events (9 pages)**
1. EventsBrowsePage
2. EventDetailsPage
3. CreateEventPage
4. EventPublishedPage
5. EventReviewPage
6. MyEventsPage
7. CreateCommunityEventPage
8. QuickEventBuilderPage
9. CancellationFlowPage

### **Network & AI2AI (3 pages)**
1. DeviceDiscoveryPage
2. AI2AIConnectionsPage
3. DiscoverySettingsPage

### **Communities & Clubs (2 pages)**
1. CommunityPage
2. ClubPage

### **Business & Brand (6 pages)**
1. BusinessAccountCreationPage
2. EarningsDashboardPage
3. BrandDashboardPage
4. BrandDiscoveryPage
5. BrandAnalyticsPage
6. SponsorshipManagementPage

### **Partnerships (4 pages)**
1. PartnershipProposalPage
2. PartnershipManagementPage
3. PartnershipCheckoutPage
4. PartnershipAcceptancePage

### **Admin (12+ pages)**
1. AI2AIAdminDashboard
2. GodModeDashboardPage
3. UserDataViewerPage
4. + More admin pages...

### **Legal (3 pages)**
1. TermsOfServicePage
2. PrivacyPolicyPage
3. EventWaiverPage

### **Other (5+ pages)**
1. SupabaseTestPage (dev only)
2. DisputeSubmissionPage
3. ActionHistoryPage
4. + More...

---

## 🔑 **KEY NAVIGATION PATTERNS**

### **Bottom Navigation (HomePage)**
- Always visible on HomePage
- 3 tabs: Map, Spots, Explore
- Switches between tab content

### **Profile Menu**
- Accessible from avatar icon in:
  - Spots Tab
  - Explore Tab
  - ProfilePage
- Shows user info and sign out

### **Back Navigation**
- Most pages support back navigation
- Uses Flutter's Navigator.pop()
- Some pages use GoRouter context.go()

### **Deep Links**
- Profile sub-pages use paths like `/profile/ai-status`
- Communities use `/community/:id`
- Clubs use `/club/:id`

---

## 📝 **VISIBILITY NOTES**

### **Conditional Visibility:**
- **Offline Indicator:** Shows when offline (HomePage, SpotsPage)
- **Profile Menu:** Only shows when authenticated
- **Create/Edit Buttons:** Only show for owned content
- **Admin Pages:** Only accessible to admins
- **Business Pages:** Only accessible to business accounts

### **Permission-Based:**
- **MapPage:** Requires location permission
- **DeviceDiscoveryPage:** Requires connectivity permissions
- **Some features:** Require specific permissions

---

## 🎯 **QUICK REFERENCE**

### **Main Entry Points:**
1. `/` - AuthWrapper (auto-redirects)
2. `/login` - LoginPage
3. `/signup` - SignupPage
4. `/home` - HomePage (main app)

### **Most Used Pages:**
1. HomePage (with 3 tabs)
2. ProfilePage
3. ListDetailsPage
4. SpotDetailsPage
5. HybridSearchPage

### **Navigation Depth:**
- **Level 1:** HomePage tabs
- **Level 2:** Detail pages (SpotDetails, ListDetails)
- **Level 3:** Edit/Create pages
- **Level 4:** Settings sub-pages

---

**Last Updated:** December 12, 2025  
**Total Pages:** 80+ pages  
**Main Navigation:** Bottom tabs (3) + Profile menu

