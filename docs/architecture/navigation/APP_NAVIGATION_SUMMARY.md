# SPOTS App Navigation - Quick Reference

**Date:** December 12, 2025  
**Quick visual reference for all pages and navigation**

---

## 🚀 **APP FLOW OVERVIEW**

```
App Launch
    ↓
Auth Check
    ↓
┌─────────────┐
│ Not Logged  │ → Login → Signup → Onboarding → AI Loading → Home
└─────────────┘
    ↓
┌─────────────┐
│  Logged In  │ → Home (3 Tabs: Map | Spots | Explore)
└─────────────┘
```

---

## 🏠 **HOMEPAGE STRUCTURE**

```
HomePage (/home)
│
├─→ [Bottom Nav Bar]
│   ├─→ Map Tab (Index 0)
│   ├─→ Spots Tab (Index 1)
│   └─→ Explore Tab (Index 2)
│
└─→ [Avatar Icon] → Profile Menu → ProfilePage
```

---

## 📍 **MAP TAB (Tab 0)**

**Visible:**
- Interactive map
- Spot markers (colored by category)
- Current location
- Search bar
- List filter dropdown
- Boundary toggle
- Theme selector
- My location button

**Can Navigate To:**
- SpotDetailsPage (tap marker)
- HybridSearchPage (search)
- Profile menu (avatar)

---

## 📝 **SPOTS TAB (Tab 1)**

**Visible:**
- App bar: "My Lists" + Avatar
- Search bar
- Two sub-tabs:
  - **My Lists:** User's lists
  - **Respected Lists:** Respected spots
- List cards with details

**Can Navigate To:**
- ListDetailsPage (tap list)
- Profile menu (avatar)

---

## 🔍 **EXPLORE TAB (Tab 2)**

**Visible:**
- App bar: "Explore" + Avatar
- Four sub-tabs:
  - **Users:** Public lists
  - **AI:** AI assistant chat
  - **Events:** Events browse
  - **Communities:** Community discovery + join (true-compat ranked)

**Users SubTab:**
- Public lists from other users
- Respect counts

**AI SubTab:**
- AI features section
- Chat interface
- Universal AI search

**Events SubTab:**
- Events browse page
- Event cards

**Communities SubTab:**
- Community discovery feed (ranked by combined true compatibility)
- Join from discover
- Compatibility breakdown (quantum/topological/weave)

**Can Navigate To:**
- ListDetailsPage (public list)
- HybridSearchPage (AI card)
- EventDetailsPage (event)
- CommunitiesDiscoverPage (Explore → Communities)
- Profile menu (avatar)

---

## 📄 **DETAIL PAGES**

### **SpotDetailsPage**
**Visible:**
- Spot name, description, category
- Location on map
- Edit/Delete (if owner)

**Can Navigate To:**
- EditSpotPage (edit button)
- ← Back

### **ListDetailsPage**
**Visible:**
- List title, description
- Spots in list
- Respect count
- Add spot, Edit, Delete (if owner)

**Can Navigate To:**
- SpotDetailsPage (spot tap)
- CreateSpotPage (add spot)
- EditListPage (edit button)
- ← Back

---

## 👤 **PROFILE PAGE**

**Visible:**
- User info card (avatar, name, email, online status)
- Partnerships section
- Settings list:
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
  - Discovery Settings
  - Federated Learning
  - AI Improvement
  - AI2AI Learning Methods
  - Continuous Learning
- Sign Out button

**Can Navigate To:**
- 20+ settings pages
- ← Back

---

## 🔍 **SEARCH**

### **HybridSearchPage**
**Visible:**
- Search bar
- Filters
- Results:
  - Community (spots, lists, events)
  - External data (places)

**Can Navigate To:**
- SpotDetailsPage (spot result)
- ListDetailsPage (list result)
- EventDetailsPage (event result)
- ← Back

---

## 🎉 **EVENTS**

### **EventsBrowsePage**
**Visible:**
- Event cards
- Filters
- Search

**Can Navigate To:**
- EventDetailsPage (event tap)
- CreateEventPage (create button)

### **EventDetailsPage**
**Visible:**
- Event info
- RSVP button
- Share button

**Can Navigate To:**
- EventReviewPage (after RSVP)
- CreateEventPage (edit)
- CancellationFlowPage (cancel)
- ← Back

---

## 🌐 **NETWORK**

### **DeviceDiscoveryPage**
**Visible:**
- Discovery status
- Nearby devices
- Connection options

**Can Navigate To:**
- AI2AIConnectionsPage
- DiscoverySettingsPage
- ← Back

---

## 📊 **PAGE COUNT BY CATEGORY**

- **Authentication:** 2 pages
- **Onboarding:** 10 pages
- **Main App:** 1 page (3 tabs)
- **Spots & Lists:** 8 pages
- **Map:** 1 page
- **Profile & Settings:** 20+ pages
- **Search:** 1 page
- **Events:** 9 pages
- **Network:** 3 pages
- **Communities:** 3 pages
- **Business:** 6 pages
- **Partnerships:** 4 pages
- **Admin:** 12+ pages
- **Legal:** 3 pages
- **Other:** 5+ pages

**Total: 80+ pages**

---

## 🎯 **MOST COMMON NAVIGATION PATHS**

1. **Home → Spots Tab → List → Spot Details**
2. **Home → Map Tab → Marker → Spot Details**
3. **Home → Explore Tab → AI → Hybrid Search**
4. **Home → Avatar → Profile → Settings**
5. **Home → Explore Tab → Events → Event Details**

---

**Last Updated:** December 12, 2025

