# Brand Discovery & Sponsorship - Key Requirements Summary

**Date:** November 21, 2025  
**Status:** ✅ All Requirements Addressed  
**Main Plan:** [`BRAND_DISCOVERY_SPONSORSHIP_PLAN.md`](./BRAND_DISCOVERY_SPONSORSHIP_PLAN.md)

---

## ✅ User Requirements → Implementation

### **1. "10% on ALL paid events, no matter what"**

**Requirement:**
> SPOTS should take 10% on any fee for any event type, regardless of how many people show up

**Implementation:**
```dart
class PlatformFeePolicy {
  static const double PLATFORM_FEE_PERCENTAGE = 10.0;
  
  // 10% on EVERYTHING:
  ✅ Walking tours ($25 tour → $2.50 to SPOTS)
  ✅ Workshops ($35 class → $3.50 to SPOTS)
  ✅ Event tickets ($75 ticket → $7.50 to SPOTS)
  ✅ Product sales ($25 item → $2.50 to SPOTS)
  ✅ Sponsor contributions ($500 → $50 to SPOTS)
  
  // No exceptions:
  ❌ No reduced fees for small events
  ❌ No waivers for non-profits
  ❌ No discounts for partners
  ✅ Simple: 10% always
}
```

**Status:** ✅ Implemented in plan

---

### **2. "Product tracking for everything sold on SPOTS"**

**Requirement:**
> Product tracking should include anything being sold, like walking tours, not just physical products

**Implementation:**
- Tours = treated as "products" (services sold)
- All paid events tracked in revenue system
- 10% fee applies to all of it
- Universal tracking dashboard for all revenue streams

**Examples:**
```
Walking Coffee Tour:
├─ Service: Guided tour (sold as "product")
├─ Price: $25/person
├─ SPOTS fee: 10% on all ticket sales
└─ Tracked same as physical product

Workshop with Materials:
├─ Ticket: $35/person (SPOTS gets 10%)
├─ Materials sold: $15/kit (SPOTS gets 10%)
└─ Both tracked and distributed automatically
```

**Status:** ✅ Clarified - all paid events are "products"

---

### **3. "Users can reach out to businesses on the app"**

**Requirement:**
> If a qualified user wants to host at a specific place, they can reach out to the business through the app

**Implementation:**

**User Flow:**
```
1. User creates event
2. Searches for venue: "Third Coast Coffee"
3. Options:
   ├─ If on SPOTS: "Add as Partner" (instant)
   └─ If not on SPOTS: "Invite to SPOTS" (earn referral)
4. Business receives invitation
5. Business can accept and join
6. Partnership auto-created
```

**UI:**
```
Search Results:
├─ ✅ Third Coast Coffee (On SPOTS)
│   [Add as Partner] → Immediate
│
└─ ⚠️  Brew Haven (Not on SPOTS)
    [Invite to SPOTS] (earn $50!)
    [Use Anyway] (unaffiliated)
```

**Status:** ✅ Fully implemented in plan

---

### **4. "User gets paid to onboard unaffiliated businesses"**

**Requirement:**
> If the place is unaffiliated, user can approach them and get paid a fee to get them to sign up

**Implementation:**

**Referral Incentive:**
```
User refers business to SPOTS:

Immediate Bonus:           $50.00 (when they complete signup)
First Event Bonus:         10% of business's earnings
Max Total Bonus:           $200.00

Example:
├─ Business signs up: User gets $50
├─ Business's first event earns them $210
├─ User gets additional $21 (10% of $210)
└─ User total: $71.00
```

**Business Invitation Email:**
```
"Sarah wants to host at your cafe!

Accept this event partnership and join SPOTS:
✅ Earn $210 from this event
✅ Host your own future events
✅ Get discovered by local community

[Accept & Join SPOTS]"
```

**Status:** ✅ $50 + 10% referral program implemented

---

### **5. "Revenue splits decided BEFORE event starts"**

**Requirement:**
> Splits for payment have to be decided by user, business, and affiliates before the event starts

**Implementation:**

**Agreement Workflow:**
```
Step 1: Host proposes splits
        ├─ "You: 60%, Cafe: 40%"
        └─ Sends to cafe for approval

Step 2: All partners review
        ├─ Cafe can accept, decline, or counter
        └─ If counter: "We want 50/50"

Step 3: Negotiation
        ├─ Host reviews counter-proposal
        └─ Can accept or modify

Step 4: All approve
        ├─ Agreement LOCKED
        ├─ Cannot change after locked
        └─ Event can now go live

Step 5: Event publishes
        ├─ Splits are final
        └─ No post-event negotiations
```

**Enforcement:**
```dart
class RevenueAgreement {
  bool canModify() {
    // Cannot modify after event starts
    if (event.startTime.isBefore(DateTime.now())) {
      return false;
    }
    // Can only modify if not locked
    return !isLocked;
  }
}
```

**Status:** ✅ Pre-event lock-in enforced

---

### **6. "Separate UI for users, businesses, and sponsor companies"**

**Requirement:**
> There should be separate UIs for users, businesses, and companies looking to participate

**Implementation:**

**Three Distinct Interfaces:**

#### **A. User Interface (Event Hosts & Attendees)**
```
Navigation:
├─ 🏠 Home (discover events)
├─ 🔍 Discover
├─ ➕ Host Event (quick creation)
├─ 🎫 My Events
├─ 💰 Earnings (from hosting + referrals)
└─ 👤 Profile

Focus: Easy hosting, finding events, earning money
```

#### **B. Business Interface (Venues & Shops)**
```
Navigation:
├─ 🏢 My Business (profile, hours, photos)
├─ 📅 Events Calendar (partnerships + own events)
├─ 🤝 Partnership Requests (approve/decline)
├─ 💰 Revenue & Analytics (earnings, traffic, ROI)
├─ 🎯 Host Your Own Event
└─ ⚙️  Settings

Focus: Partnership management, revenue tracking, venue optimization
```

#### **C. Company/Sponsor Interface (Brands)**
```
Navigation:
├─ 🔍 Discover Events (search & filter)
├─ 🤝 Active Sponsorships (track contributions)
├─ 📊 ROI & Analytics (performance, reach, sales)
├─ 💼 Brand Profile (preferences, products)
└─ ⚙️  Preferences (budget, categories, targeting)

Focus: Finding sponsorship opportunities, ROI tracking, brand exposure
```

**Key Differences:**
- **Users** see: "Host Event", "Earn by Hosting", "Find Partners"
- **Businesses** see: "Partnership Requests", "Revenue Analytics", "Events at My Location"
- **Companies** see: "Discover Events to Sponsor", "Sponsorship ROI", "Brand Reach Metrics"

**Status:** ✅ Three separate UIs designed

---

## 🎯 Complete Feature Summary

| Feature | Requirement | Implementation | Status |
|---------|-------------|----------------|--------|
| **Universal 10% Fee** | On all paid events | Platform fee on tickets, tours, products, everything | ✅ |
| **Product = Anything Sold** | Tours, workshops, tickets, items | All revenue streams tracked uniformly | ✅ |
| **User → Business Outreach** | Search and invite businesses | In-app invitation system | ✅ |
| **Referral Incentives** | Get paid for onboarding | $50 + 10% of first event (max $200) | ✅ |
| **Pre-Event Split Lock** | All splits agreed before start | Multi-party approval workflow with lock | ✅ |
| **Separate UIs** | Users, businesses, companies | Three role-specific interfaces | ✅ |
| **Multi-Party Partnerships** | 3+ partners per event | N-way revenue distribution | ✅ |
| **Product Sales Tracking** | Track inventory and sales | Real-time sales + automatic splits | ✅ |
| **Brand Discovery** | Companies find events | Search marketplace with AI matching | ✅ |
| **Payment Verification** | Track who paid what | Complete contribution tracking | ✅ |

---

## 💡 Key Examples

### **Example 1: User Invites Unaffiliated Business**

**Scenario:**
> Sarah (coffee expert) wants to host workshop at Brew Haven (not on SPOTS)

**Flow:**
```
1. Sarah searches "Brew Haven" in venue finder
   Result: "⚠️  Not on SPOTS"

2. Sarah clicks "Invite to SPOTS"
   ├─ Proposes partnership (60/40 split)
   └─ System sends invitation to Brew Haven

3. Brew Haven receives email:
   "Sarah wants to host a $35 workshop for 15 people at your cafe.
   Join SPOTS to earn $182 from this event.
   [Accept & Join]"

4. Brew Haven signs up (5 min onboarding)
   └─ Sarah gets $50 referral bonus immediately

5. Brew Haven reviews partnership terms
   ├─ Counter-proposes: 50/50 split
   └─ Sarah accepts

6. Agreement locked, event goes live

7. Event happens: $525 revenue
   ├─ SPOTS: $52.50 (10%)
   ├─ Sarah: $236.25 (50% of net)
   ├─ Brew Haven: $236.25 (50% of net)
   └─ Sarah also gets $23.63 (10% of Brew Haven's $236.25)

Total for Sarah: $236.25 + $50 + $23.63 = $309.88
Total for Brew Haven: $236.25
Total for SPOTS: $52.50
```

---

### **Example 2: Company Sponsors Multi-Party Event**

**Scenario:**
> Oil company finds influencer's dinner through brand discovery, wants to sponsor

**Flow:**
```
1. Oil company logs into Sponsor UI
2. Searches: Category [Food], Location [Brooklyn], Budget [$500-1000]
3. Sees Sarah's dinner event (98% match)
4. Proposes sponsorship:
   ├─ $300 cash
   ├─ 20 bottles oil (for use + sale)
   └─ Wants logo on event page

5. Sarah reviews proposal
   ├─ Adjusts splits to include sponsor
   └─ Sends to all partners for approval

6. Current split proposal:
   ├─ Sarah (Host): 40% tickets, 30% oil sales
   ├─ Restaurant: 30% tickets, 10% oil sales
   └─ Oil Company: 30% tickets, 60% oil sales

7. All three parties review and approve
8. Agreement LOCKED before event
9. Event happens:
   ├─ Tickets: 25 × $75 = $1,875
   ├─ Oil sales: 15 × $25 = $375
   └─ Total: $2,250

10. Automatic distribution:
    ├─ SPOTS: $225 (10% of everything)
    ├─ Sarah: $862.50 (40% tickets + 30% oil)
    ├─ Restaurant: $641.25 (30% tickets + 10% oil)
    └─ Oil Company: $521.25 (30% tickets + 60% oil)

All paid automatically 2 days after event!
```

---

## 🏗️ Technical Implementation

### **New Data Models:**

```dart
// Universal revenue tracking
class RevenueStream {
  final RevenueType type; // ticket, product, tour, workshop, sponsor
  final double amount;
  final double platformFee; // Always 10%
  final Map<String, double> partnerSplits;
}

// Pre-event agreement
class RevenueAgreement {
  final List<PartnerSplit> splits;
  final AgreementStatus status; // proposed, locked
  final DateTime? lockedAt;
  final bool canModify; // false after event starts
}

// Business referral tracking
class BusinessReferral {
  final String referrerId;
  final String businessId;
  final double signupBonus; // $50
  final double firstEventBonus; // 10% of business's first earnings
  final ReferralStatus status;
}

// Role-specific UI state
enum UserRole {
  host,      // See user interface
  business,  // See business interface
  sponsor,   // See sponsor/company interface
  attendee,  // See simplified user interface
}
```

---

## 📊 Revenue Projections Updated

### **With All New Features:**

**Year 1 Monthly Progression:**

| Month | Feature | Events | SPOTS Revenue |
|-------|---------|--------|---------------|
| 1-2 | Base hosting | 50 | $0 |
| 3 | + 10% fee | 100 (30% paid) | $750 |
| 4-5 | + Partnerships | 150 (40% paid) | $3,000 |
| 6 | + Multi-party | 200 (50% paid) | $7,500 |
| 7-8 | + Brand sponsors | 250 (60% paid) | $13,500 |
| 9-10 | + Product sales | 300 (65% paid) | $19,500 |
| 11-12 | Scale | 400 (70% paid) | $30,000 |

**Year 1 Total:** ~$200K in platform fees  
**Year 2 Projection:** ~$750K+ (with growth)

**Additional Revenue (Referrals):**
- Average 10 business referrals/month
- $50/referral = $500/month
- Paid to users (platform growth incentive)

---

## ✅ Summary

**All User Requirements Addressed:**

1. ✅ **10% on everything** - Universal platform fee on all paid events/products
2. ✅ **Product = anything sold** - Tours, workshops, tickets all tracked
3. ✅ **User → business outreach** - In-app invitation system
4. ✅ **Referral incentives** - $50 + 10% for business onboarding
5. ✅ **Pre-event split lock** - All agreements finalized before start
6. ✅ **Separate UIs** - Three role-specific interfaces

**Status:** 🟢 Ready for implementation  
**Timeline:** 10 weeks  
**Dependencies:** Event Partnership Plan (Phases 1-2)

---

**This system now provides complete flexibility, transparency, and incentives for all parties while ensuring SPOTS earns a consistent 10% on all revenue streams.** 🚪✨💰

---

**Last Updated:** November 21, 2025  
**Main Plan:** [`BRAND_DISCOVERY_SPONSORSHIP_PLAN.md`](./BRAND_DISCOVERY_SPONSORSHIP_PLAN.md)

