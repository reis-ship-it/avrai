# Brand Discovery & Multi-Party Sponsorship System

**Created:** November 21, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** HIGH  
**Extends:** Event Partnership & Monetization Plan  
**Philosophy Alignment:** "The key opens doors" + "Always Learning With You" + "Business With Integrity"

---

## 🎯 Executive Summary

This plan extends the Event Partnership System to enable:
1. **Universal 10% Platform Fee** - SPOTS takes 10% on ALL paid events (tours, workshops, tickets, products - everything)
2. **Brand Discovery** - Companies search for events to sponsor
3. **Multi-Party Partnerships** - 3+ partners per event (influencer + venue + sponsor)
4. **User-Initiated Business Outreach** - Qualified users can invite businesses to join events
5. **Business Referral Incentives** - Users earn fees for onboarding new businesses
6. **Pre-Event Split Agreements** - All revenue splits locked before event starts
7. **Role-Specific UIs** - Separate interfaces for users, businesses, and sponsor companies
8. **In-App Payment Tracking** - Complete visibility into who pays what

**Key Innovation:** Transform from 2-party partnerships to N-party ecosystems where multiple brands can participate in a single event, with complete pre-event transparency and agreement.

---

## 💡 Your Example Scenario

### **Instagram Influencer Dinner Event:**

**Primary Partnership:**
- 🎭 **Influencer:** Food blogger (50K followers, City-level expertise)
- 🍽️ **Restaurant:** Farm-to-table venue (hosting location)

**Additional Sponsor:**
- 🫒 **Oil Company:** Premium olive oil brand (wants to participate)

**Sponsorship Options:**

#### **Option A: Financial Sponsorship**
```
Oil Company pays $500 to be featured sponsor
├─ SPOTS Platform Fee (10%): $50
└─ Distributed to Partners (90%): $450
    ├─ Influencer (60%): $270
    ├─ Restaurant (30%): $135
    └─ Reserved for future sponsors: $45
```

#### **Option B: Product Sponsorship**
```
Oil Company provides 20 bottles ($400 retail value)
- Used in dinner preparation
- Sold at event: 15 bottles × $25 = $375
├─ SPOTS Platform Fee (10%): $37.50
└─ Distributed (90%): $337.50
    ├─ Oil Company (40%): $135
    ├─ Influencer (35%): $118.13
    └─ Restaurant (25%): $84.37
```

#### **Option C: Hybrid Sponsorship**
```
$300 cash + 20 bottles of oil ($400 value) = $700 total
- Cash split immediately
- Product sales split after event
- Complete tracking of both contributions
```

---

## 💰 Universal Platform Fee Structure

### **CRITICAL: 10% on EVERYTHING**

**SPOTS Platform Fee: 10% on ALL paid events, no exceptions**

**What "everything" means:**

```dart
class PlatformFeePolicy {
  static const double PLATFORM_FEE_PERCENTAGE = 10.0;
  
  /// SPOTS takes 10% on ALL of these:
  List<RevenueStream> get allRevenueStreams => [
    // Event tickets
    RevenueStream.eventTickets,        // ✅ $75 ticket → $7.50 to SPOTS
    
    // Tours
    RevenueStream.walkingTour,         // ✅ $25 tour → $2.50 to SPOTS
    RevenueStream.guidedExperience,    // ✅ $50 experience → $5 to SPOTS
    
    // Workshops
    RevenueStream.workshop,            // ✅ $35 workshop → $3.50 to SPOTS
    RevenueStream.class,               // ✅ $40 class → $4 to SPOTS
    
    // Products sold at events
    RevenueStream.productSales,        // ✅ $25 bottle → $2.50 to SPOTS
    RevenueStream.merchandise,         // ✅ $15 merch → $1.50 to SPOTS
    
    // Sponsor contributions
    RevenueStream.sponsorshipCash,     // ✅ $500 sponsor → $50 to SPOTS
    RevenueStream.sponsorshipProduct,  // ✅ $400 product value → calculated on sales
    
    // Any other paid event type
    RevenueStream.other,               // ✅ Anything paid → 10% to SPOTS
  ];
  
  /// The rule is simple: If money changes hands through SPOTS, we take 10%
  double calculatePlatformFee(double amount) {
    return amount * (PLATFORM_FEE_PERCENTAGE / 100);
  }
}
```

### **Examples:**

**Walking Coffee Tour:**
```
User hosts coffee tour: $25/person × 15 people = $375
├─ SPOTS Platform Fee (10%): $37.50
├─ Payment Processing (~3%): $11.58
└─ Host Payout (87%): $325.92

Simple. Clean. Always 10%.
```

**Workshop at Business:**
```
Expert hosts brewing class at cafe: $35/person × 12 people = $420
├─ SPOTS Platform Fee (10%): $42.00
├─ Payment Processing (~3%): $12.95
└─ Remaining (87%): $365.05
    ├─ Expert (70%): $255.54
    └─ Cafe (30%): $109.51
```

**Event with Product Sales:**
```
Dinner event: $75/ticket × 20 = $1,500
Product sales: 15 bottles @ $25 = $375
TOTAL: $1,875

SPOTS gets 10% on BOTH:
├─ From tickets: $150.00
├─ From products: $37.50
└─ Total SPOTS fee: $187.50

Then partners split the remaining 87%
```

### **No Exceptions Policy:**

❌ **WRONG:**
- "Free events with product sales" → No fee on products
- "Small events under 5 people" → Reduced fee
- "Non-profit events" → Waived fee
- "Partner discounts" → Different percentage

✅ **CORRECT:**
- **ANY paid event = 10% to SPOTS**
- **ANY product sale = 10% to SPOTS**
- **ANY sponsorship = 10% to SPOTS**
- **Size doesn't matter**
- **Event type doesn't matter**
- **Number of people doesn't matter**

**Philosophy:** Transparent, consistent, predictable. Everyone knows the cost.

---

## 🤝 User-Initiated Business Outreach

### **New Capability: Users Can Invite Businesses**

**Scenario:**
> Expert wants to host coffee workshop at Third Coast Coffee  
> Third Coast isn't on SPOTS yet  
> Expert can invite them through the app

### **The Flow:**

#### **1. User Searches for Venue**

```
User hosting coffee workshop:
├─ Opens event creation wizard
├─ Searches for venues: "Third Coast Coffee"
├─ Result shows:
│   ┌────────────────────────────────────┐
│   │ 🏢 Third Coast Coffee              │
│   │ 📍 Chicago, IL                     │
│   │ ⚠️  Not yet on SPOTS               │
│   │                                    │
│   │ [Invite to SPOTS] [Use Anyway]    │
│   └────────────────────────────────────┘
└─ User can invite them
```

#### **2. Invitation Options**

**Option A: Invite to Join SPOTS (Referral)**
```
┌──────────────────────────────────────────┐
│  Invite Third Coast Coffee to SPOTS     │
├──────────────────────────────────────────┤
│                                          │
│  Benefits for them:                      │
│  ✅ List their business                  │
│  ✅ Host their own events                │
│  ✅ Earn from partnerships               │
│  ✅ Gain community visibility            │
│                                          │
│  Your referral bonus:                    │
│  💰 $50 when they sign up                │
│  💰 +10% of their first event revenue    │
│                                          │
│  We'll send them:                        │
│  📧 Email invitation                     │
│  📱 SMS invitation                       │
│  📄 Business benefits deck               │
│                                          │
│  [Send Invitation]                       │
│                                          │
└──────────────────────────────────────────┘
```

**Option B: Use Venue (Unaffiliated)**
```
┌──────────────────────────────────────────┐
│  Host Event at Third Coast Coffee       │
│  (Unaffiliated Venue)                    │
├──────────────────────────────────────────┤
│                                          │
│  ⚠️  They're not on SPOTS, so:           │
│  - No automatic revenue split            │
│  - You handle payment with them          │
│  - SPOTS still takes 10% of tickets      │
│                                          │
│  Your arrangement with venue:            │
│  [ ] I have permission to use venue      │
│  [ ] I'm paying venue separately         │
│  [ ] Venue gets $___ per event           │
│                                          │
│  Note: If they join SPOTS later,         │
│  you'll earn $50 referral bonus!         │
│                                          │
│  [Continue with Unaffiliated Venue]      │
│                                          │
└──────────────────────────────────────────┘
```

#### **3. Business Receives Invitation**

**Email/SMS to Third Coast Coffee:**
```
Subject: Sarah wants to host an event at your cafe!

Hi Third Coast Coffee,

Sarah Chen (coffee expert with 15K followers) wants to 
host a coffee brewing workshop at your location.

Join SPOTS to:
✅ Partner on this event (earn $150+ from revenue share)
✅ Host your own future events
✅ Get discovered by local coffee enthusiasts
✅ Build your community presence

This event specifically:
- Coffee Brewing Workshop
- 15 attendees @ $35/person = $525 revenue
- Proposed split: Sarah 60%, You 40% = $210 for you
- Date: December 15, 2025

[Accept & Join SPOTS] [Learn More] [Decline]

Questions? Reply to this email.
```

#### **4. Business Onboarding (Fast Track)**

**If business accepts:**
```
1. Quick signup (5 minutes)
   ├─ Business info
   ├─ Stripe Connect onboarding
   └─ Accept partnership terms

2. Event partnership auto-created
   ├─ Pre-configured from Sarah's proposal
   ├─ Revenue split already set
   └─ Ready to approve

3. Business clicks "Approve"
   └─ Event goes live!

Sarah gets $50 referral bonus + 10% of cafe's first event revenue
```

### **Referral Incentive Structure**

```dart
class BusinessReferralProgram {
  // Immediate bonus when business completes signup
  static const double SIGNUP_BONUS = 50.0;
  
  // Bonus percentage of referred business's first event
  static const double FIRST_EVENT_BONUS_PERCENTAGE = 10.0;
  
  // Maximum referral bonus
  static const double MAX_REFERRAL_BONUS = 200.0;
  
  /// Calculate referral payout
  ReferralPayout calculateReferralPayout(
    BusinessAccount referredBusiness,
    ExpertiseEvent? firstEvent,
  ) {
    double total = SIGNUP_BONUS;
    
    if (firstEvent != null && firstEvent.revenue != null) {
      // User gets 10% of what the business earned
      final businessEarnings = firstEvent.revenue!.businessPayout;
      final bonus = businessEarnings * (FIRST_EVENT_BONUS_PERCENTAGE / 100);
      total += min(bonus, MAX_REFERRAL_BONUS - SIGNUP_BONUS);
    }
    
    return ReferralPayout(
      signupBonus: SIGNUP_BONUS,
      firstEventBonus: total - SIGNUP_BONUS,
      totalPayout: total,
    );
  }
}
```

**Example Referral Payouts:**

```
Sarah refers Third Coast Coffee:

Signup Bonus:            $50.00 (immediate)
First Event:
├─ Total revenue:        $525.00
├─ Cafe's share (40%):   $210.00
├─ Sarah's bonus (10%):  $21.00
└─ Sarah's total:        $71.00

If cafe's first event was bigger:
├─ Total revenue:        $2,000
├─ Cafe's share:         $800
├─ Sarah's bonus:        $80 (capped at $150 additional)
└─ Sarah's total:        $130.00
```

---

## 📋 Pre-Event Revenue Split Agreement

### **CRITICAL: All Splits Locked Before Event Starts**

**The Rule:**
> Revenue splits MUST be agreed upon and locked by all parties BEFORE the event goes live. No post-event negotiations.

### **Agreement Workflow:**

#### **Step 1: Event Creator Proposes Splits**

```
┌──────────────────────────────────────────────────┐
│  Configure Event Revenue Splits                  │
│  Coffee Brewing Workshop                         │
├──────────────────────────────────────────────────┤
│                                                  │
│  💰 Expected Revenue                             │
│  Tickets: 15 @ $35 = $525                       │
│  Product Sales: ~$150 (estimated)                │
│  Total: ~$675                                    │
│                                                  │
│  ⚙️  Configure Splits                            │
│                                                  │
│  From Ticket Sales ($525):                       │
│  ├─ SPOTS Platform Fee (10%): $52.50 [locked]   │
│  ├─ Payment Processing (~3%): ~$16 [auto]       │
│  └─ Remaining: $456.50 [to split]               │
│                                                  │
│  Split Between Partners:                         │
│  ┌──────────────────────────────────────┐       │
│  │ You (Host)           60% │ $273.90   │       │
│  │ Third Coast (Venue)  40% │ $182.60   │       │
│  │                     100% │ ✅         │       │
│  └──────────────────────────────────────┘       │
│                                                  │
│  From Product Sales ($150 est.):                 │
│  ├─ SPOTS Platform Fee (10%): $15.00            │
│  └─ Split (if selling cafe's coffee):           │
│      ├─ You: 30% ($40.50)                       │
│      └─ Third Coast: 70% ($94.50)               │
│                                                  │
│  📊 Your Projected Earnings: $314.40             │
│  📊 Cafe's Projected Earnings: $277.10           │
│                                                  │
│  ⚠️  These splits will be LOCKED when all        │
│     parties approve. Changes after approval      │
│     require re-approval from everyone.           │
│                                                  │
│  [Save & Send for Approval]                      │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### **Step 2: All Partners Review & Approve**

**Third Coast Coffee receives:**
```
┌──────────────────────────────────────────┐
│  Event Partnership Proposal              │
│  from Sarah Chen                         │
├──────────────────────────────────────────┤
│                                          │
│  Event: Coffee Brewing Workshop          │
│  Date: Dec 15, 2025                      │
│  Location: Your cafe                     │
│                                          │
│  💰 Proposed Revenue Split               │
│                                          │
│  Total Expected: ~$675                   │
│                                          │
│  Your Earnings:                          │
│  ├─ From tickets: $182.60 (40%)         │
│  ├─ From products: $94.50 (70%)         │
│  └─ Total: ~$277.10                      │
│                                          │
│  Your Responsibilities:                  │
│  ✅ Provide venue space                  │
│  ✅ Provide coffee beans                 │
│  ✅ Provide brewing equipment            │
│                                          │
│  Sarah's Responsibilities:               │
│  ✅ Lead workshop instruction            │
│  ✅ Market to her audience               │
│  ✅ Handle registrations                 │
│                                          │
│  Terms:                                  │
│  ⚠️  Once approved, revenue splits are   │
│      LOCKED and cannot be changed        │
│                                          │
│  [View Full Agreement]                   │
│  [Approve] [Request Changes] [Decline]   │
│                                          │
└──────────────────────────────────────────┘
```

**If requesting changes:**
```
┌──────────────────────────────────────────┐
│  Request Changes to Agreement            │
├──────────────────────────────────────────┤
│                                          │
│  Current Proposal:                       │
│  You: 40% tickets, 70% products          │
│                                          │
│  Your Counter-Proposal:                  │
│  ┌────────────────────────────────┐     │
│  │ Tickets: [50%] (You want more) │     │
│  │ Products: [70%] (Same)         │     │
│  └────────────────────────────────┘     │
│                                          │
│  Message to Sarah:                       │
│  [We'd like 50/50 on tickets since      │
│   we're providing all materials...]      │
│                                          │
│  [Send Counter-Proposal]                 │
│                                          │
└──────────────────────────────────────────┘
```

#### **Step 3: Negotiation (If Needed)**

**Status Tracking:**
```
Event Status: ⏳ Pending Partner Approval

Partners:
├─ Sarah (Host): ✅ Approved
├─ Third Coast: 🔄 Requested Changes (50/50 split)
└─ Premium Oil Co: ⏳ Awaiting review

Next: Sarah must respond to counter-proposal
```

#### **Step 4: Agreement Locked**

**When all approve:**
```
┌──────────────────────────────────────────┐
│  🎉 Partnership Agreement Finalized!     │
├──────────────────────────────────────────┤
│                                          │
│  Coffee Brewing Workshop                 │
│  All partners have approved!             │
│                                          │
│  Final Revenue Splits:                   │
│  ├─ SPOTS: 10% (platform fee)           │
│  ├─ Sarah: 50% tickets, 30% products    │
│  └─ Third Coast: 50% tickets, 70% products │
│                                          │
│  🔒 This agreement is now LOCKED         │
│  Changes require re-approval from all    │
│                                          │
│  Event Status: Ready to Publish          │
│                                          │
│  [Publish Event] [View Agreement]        │
│                                          │
└──────────────────────────────────────────┘
```

#### **Step 5: No Changes After Event Starts**

```dart
class RevenueAgreement {
  final String eventId;
  final List<PartnerSplit> splits;
  final AgreementStatus status;
  final DateTime? lockedAt;
  final List<PartnerApproval> approvals;
  
  /// Once all partners approve, agreement is locked
  bool get isLocked => 
    status == AgreementStatus.locked && 
    lockedAt != null;
  
  /// Cannot modify splits after event starts
  bool canModify() {
    if (isLocked && event.startTime.isBefore(DateTime.now())) {
      return false; // Event already started
    }
    return !isLocked; // Can modify if not locked
  }
  
  /// Require unanimous re-approval for any changes
  Future<void> requestModification(
    String requestorId,
    List<PartnerSplit> newSplits,
  ) async {
    if (!canModify()) {
      throw Exception('Cannot modify agreement after event starts');
    }
    
    // Reset all approvals except requestor
    // All partners must re-approve
    await resetApprovalsExcept(requestorId);
    await notifyPartnersOfChanges(newSplits);
  }
}
```

---

## 🎨 Role-Specific User Interfaces

### **Three Separate UIs for Three User Types**

**CRITICAL: Each role sees a different interface optimized for their needs**

### **1. USER INTERFACE (Event Hosts & Attendees)**

**Navigation:**
```
┌──────────────────────────────────────────┐
│  SPOTS - Your Events                     │
├──────────────────────────────────────────┤
│  🏠 Home                                  │
│  🔍 Discover                              │
│  ➕ Host Event                            │
│  🎫 My Events                             │
│  💰 Earnings                              │
│  👤 Profile                               │
└──────────────────────────────────────────┘
```

**Host Event Tab:**
```
┌──────────────────────────────────────────┐
│  Host an Event                           │
├──────────────────────────────────────────┤
│                                          │
│  Quick Start:                            │
│  ┌─────────────────────────────────┐    │
│  │ 📋 Choose Template              │    │
│  │ 📅 Set Date & Time              │    │
│  │ 📍 Choose Location              │    │
│  │ 🤝 Add Partners (optional)      │    │
│  │ 💰 Set Price & Splits           │    │
│  │ 🚀 Publish                      │    │
│  └─────────────────────────────────┘    │
│                                          │
│  Or:                                     │
│  [Copy Past Event] [Use AI Assistant]   │
│                                          │
└──────────────────────────────────────────┘
```

**Add Partners Flow:**
```
┌──────────────────────────────────────────┐
│  Find Partners for Your Event            │
├──────────────────────────────────────────┤
│                                          │
│  Need a venue? Search businesses:        │
│  [Search: "coffee shops near me"...]     │
│                                          │
│  Results:                                │
│  ✅ Third Coast Coffee (On SPOTS)        │
│     [Add as Partner]                     │
│                                          │
│  ⚠️  Brew Haven (Not on SPOTS)           │
│     [Invite to SPOTS] (earn $50!)        │
│     [Use Anyway]                         │
│                                          │
│  Want sponsors? Browse companies:        │
│  [Find Sponsors →]                       │
│                                          │
└──────────────────────────────────────────┘
```

**Earnings Tab:**
```
┌──────────────────────────────────────────┐
│  Your Earnings                           │
├──────────────────────────────────────────┤
│                                          │
│  💰 Total Earned: $1,847.50              │
│  ⏳ Pending: $314.40                     │
│  💸 Paid Out: $1,533.10                  │
│                                          │
│  Recent Events:                          │
│  ├─ Coffee Workshop (Dec 15)             │
│  │   Earned: $314.40 (pending)          │
│  │   [View Breakdown]                   │
│  │                                      │
│  ├─ Coffee Tour (Dec 1)                  │
│  │   Earned: $287.50 (paid Nov 3)      │
│  │   [View Receipt]                     │
│                                          │
│  Referral Bonuses:                       │
│  ├─ Referred: Third Coast Coffee         │
│  │   Earned: $71.00                     │
│  │   [View Details]                     │
│                                          │
│  [Export Tax Docs] [Payout Settings]     │
│                                          │
└──────────────────────────────────────────┘
```

---

### **2. BUSINESS INTERFACE (Venues & Shops)**

**Navigation:**
```
┌──────────────────────────────────────────┐
│  SPOTS Business Dashboard                │
├──────────────────────────────────────────┤
│  🏢 My Business                           │
│  📅 Events Calendar                       │
│  🤝 Partnership Requests                  │
│  💰 Revenue & Analytics                   │
│  🎯 Host Your Own Event                   │
│  ⚙️  Settings                             │
└──────────────────────────────────────────┘
```

**Partnership Requests Tab:**
```
┌──────────────────────────────────────────┐
│  Partnership Requests                    │
├──────────────────────────────────────────┤
│                                          │
│  🆕 New Requests (2)                     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Sarah Chen wants to host at your   │ │
│  │ location                           │ │
│  │                                    │ │
│  │ Event: Coffee Brewing Workshop     │ │
│  │ Date: Dec 15, 2025                 │ │
│  │ Your Earnings: ~$277               │ │
│  │                                    │ │
│  │ [Review Proposal]                  │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Active Partnerships (5)                 │
│  ├─ With Sarah Chen (3 events)          │
│  ├─ With Mike's Tours (2 events)        │
│  │                                      │
│                                          │
└──────────────────────────────────────────┘
```

**Revenue & Analytics Tab:**
```
┌──────────────────────────────────────────┐
│  Business Revenue Dashboard              │
├──────────────────────────────────────────┤
│                                          │
│  💰 This Month: $2,847                   │
│  ├─ From partnerships: $1,920            │
│  ├─ From your events: $927               │
│  └─ Growth: +45% vs last month           │
│                                          │
│  📊 Event Impact:                        │
│  ├─ Events hosted: 12                    │
│  ├─ New customers: 87                    │
│  ├─ Repeat rate: 34%                     │
│  └─ Avg spend per visitor: $32           │
│                                          │
│  Top Partners:                           │
│  1. Sarah Chen - $420/month avg          │
│  2. Mike's Tours - $315/month avg        │
│                                          │
│  [Export Report] [View Analytics]        │
│                                          │
└──────────────────────────────────────────┘
```

**Host Your Own Event Tab:**
```
┌──────────────────────────────────────────┐
│  Host Events at Your Business            │
├──────────────────────────────────────────┤
│                                          │
│  Popular Business Event Types:           │
│                                          │
│  🎉 Grand Opening                        │
│  🍸 Happy Hour Special                   │
│  🎸 Live Music Night                     │
│  🍷 Tasting Event                        │
│  💰 Flash Sale                           │
│                                          │
│  [Create Event] [View Past Events]       │
│                                          │
│  Want an expert to co-host?              │
│  [Find Expert Partners →]                │
│                                          │
└──────────────────────────────────────────┘
```

---

### **3. COMPANY/SPONSOR INTERFACE (Brands)**

**Navigation:**
```
┌──────────────────────────────────────────┐
│  SPOTS Sponsorship Dashboard             │
├──────────────────────────────────────────┤
│  🔍 Discover Events                       │
│  🤝 Active Sponsorships                   │
│  📊 ROI & Analytics                       │
│  💼 Brand Profile                         │
│  ⚙️  Preferences                          │
└──────────────────────────────────────────┘
```

**Discover Events Tab:**
```
┌──────────────────────────────────────────────┐
│  Find Events to Sponsor                      │
├──────────────────────────────────────────────┤
│                                              │
│  🎯 AI Recommendations for Premium Olive Oil │
│                                              │
│  ⭐ 98% Match                                │
│  ┌────────────────────────────────────────┐ │
│  │ Farm-to-Table Dinner Experience        │ │
│  │ by @foodie_sarah (52K followers)       │ │
│  │                                        │ │
│  │ 📍 Brooklyn • 📅 Dec 20 • 👥 25       │ │
│  │                                        │ │
│  │ Seeking: Olive Oil Sponsor             │ │
│  │ Budget: $500-1,000 or product          │ │
│  │                                        │ │
│  │ Projected ROI:                         │ │
│  │ ├─ Reach: 52K impressions              │ │
│  │ ├─ Sampling: 25 people                 │ │
│  │ ├─ Revenue: $200-300                   │ │
│  │                                        │ │
│  │ [View Details] [Propose Sponsorship]   │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  Custom Search:                              │
│  [Category] [Location] [Budget] [Audience]   │
│                                              │
└──────────────────────────────────────────────┘
```

**Active Sponsorships Tab:**
```
┌──────────────────────────────────────────┐
│  Your Active Sponsorships                │
├──────────────────────────────────────────┤
│                                          │
│  Upcoming:                               │
│  ┌────────────────────────────────────┐ │
│  │ Farm-to-Table Dinner (Dec 20)      │ │
│  │ Status: ✅ Confirmed                │ │
│  │                                    │ │
│  │ Your Contribution:                 │ │
│  │ ├─ Cash: $300 (Paid ✅)            │ │
│  │ └─ Product: 20 bottles (Shipped ✅)│ │
│  │                                    │ │
│  │ Expected Returns:                  │ │
│  │ ├─ Revenue: ~$225                  │ │
│  │ ├─ Reach: 52K                      │ │
│  │ └─ Samples: 25 people              │ │
│  │                                    │ │
│  │ [View Event] [Track Products]      │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Past Events (12):                       │
│  [View Performance Reports]              │
│                                          │
└──────────────────────────────────────────┘
```

**ROI & Analytics Tab:**
```
┌──────────────────────────────────────────┐
│  Sponsorship ROI Dashboard               │
├──────────────────────────────────────────┤
│                                          │
│  📊 Q4 2025 Performance                  │
│                                          │
│  Total Investment: $3,200                │
│  ├─ Cash: $2,000                         │
│  └─ Products: $1,200 (cost)              │
│                                          │
│  Returns:                                │
│  ├─ Direct Revenue: $1,847               │
│  ├─ Brand Reach: 340K impressions        │
│  ├─ Product Sampling: 187 people         │
│  ├─ Email Signups: 94                    │
│  ├─ Website Visits: 412                  │
│  └─ Estimated Brand Value: $12,400       │
│                                          │
│  ROI: 387% (direct) / 1,200%+ (total)    │
│                                          │
│  Top Performing Events:                  │
│  1. Sarah's Farm Dinner - 410% ROI       │
│  2. Mike's Italian Night - 385% ROI      │
│                                          │
│  [Detailed Analytics] [Export Report]    │
│                                          │
└──────────────────────────────────────────┘
```

**Brand Profile Tab:**
```
┌──────────────────────────────────────────┐
│  Your Brand Profile                      │
├──────────────────────────────────────────┤
│                                          │
│  Premium Olive Oil Company               │
│  [Logo Upload]                           │
│                                          │
│  Target Categories:                      │
│  ☑️ Food & Dining                        │
│  ☑️ Culinary Experiences                 │
│  ☐ Health & Wellness                     │
│                                          │
│  Sponsorship Preferences:                │
│  Budget Range: [$500] - [$2,000]         │
│  Preferred Type: ☑️ Cash ☑️ Product     │
│  Min Attendees: [20]                     │
│  Min Influencer Size: [10K followers]    │
│                                          │
│  Products Available for Sponsorship:     │
│  ├─ 750ml Premium EVOO ($25 retail)      │
│  ├─ 375ml Infused Oil ($15 retail)       │
│  └─ Gift Sets ($45 retail)               │
│                                          │
│  [Save Preferences]                      │
│                                          │
└──────────────────────────────────────────┘
```

---

## 🔍 Brand Discovery System

### **1. Event Discovery for Brands**

**New Search Interface for Companies:**

```dart
class BrandEventDiscovery {
  /// Search events looking for sponsors
  /// CRITICAL: Only shows events where vibes match
  Future<List<SponsorableEvent>> searchSponsorableEvents({
    String? category,           // "Food", "Coffee", "Wellness"
    String? location,           // "Brooklyn", "Manhattan"
    DateTimeRange? dateRange,   // Next 30 days
    double? budgetMin,          // $100+
    double? budgetMax,          // Up to $5,000
    SponsorshipType? type,      // Financial, Product, or Both
    int? minAttendees,          // Events with 20+ attendees
    int? minInfluencerFollowers, // Host has 10K+ followers
  }) async {
    // Find events that are:
    // 1. Marked as "seeking sponsors"
    // 2. Match brand's category interests
    // 3. Within brand's budget range
    // 4. Meet brand's audience size requirements
    // 5. ⚠️  CRITICAL: Vibe compatibility check passed
  }
  
  /// Get recommendations for brand
  /// ONLY recommends when vibes align
  Future<List<EventRecommendation>> getRecommendedEvents(
    String brandId,
  ) async {
    // AI-powered recommendations based on:
    // - Brand's past sponsorships
    // - Brand's product categories
    // - Brand's target demographics
    // - Event host's audience alignment
    // - ⚠️  VIBE MATCH: Both parties must have compatible vibes
  }
  
  /// Check if brand and expert vibes are compatible
  Future<VibeCompatibility> checkVibeCompatibility(
    String brandId,
    String expertId,
    String? businessId,
  ) async {
    // Analyze personality dimensions for compatibility
    // See: EXPAND_PERSONALITY_DIMENSIONS_PLAN.md
    final brandVibe = await _getBusinessVibe(brandId);
    final expertVibe = await _getUserVibe(expertId);
    final venueVibe = businessId != null 
      ? await _getBusinessVibe(businessId)
      : null;
    
    // Calculate compatibility across dimensions:
    // - Value alignment (authenticity vs. mass appeal)
    // - Crowd tolerance (intimate vs. large events)
    // - Communication style (casual vs. professional)
    // - Pace preference (relaxed vs. energetic)
    // - Decision making (spontaneous vs. planned)
    
    final compatibility = _calculateVibeScore(
      brandVibe,
      expertVibe,
      venueVibe,
    );
    
    return VibeCompatibility(
      score: compatibility,
      isMatch: compatibility >= 0.70, // 70%+ required
      dimensions: _getDimensionBreakdown(),
      reasoning: _explainCompatibility(),
    );
  }
}

class VibeCompatibility {
  final double score;           // 0.0 - 1.0
  final bool isMatch;            // true if >= 70%
  final Map<String, double> dimensions; // Per-dimension scores
  final String reasoning;        // Human-readable explanation
  
  /// Only show partnerships with 70%+ vibe match
  static const double MINIMUM_MATCH_THRESHOLD = 0.70;
}
```

**Partnership Filtering Logic:**

```dart
class PartnershipMatchingService {
  /// CRITICAL: Both parties can decline, but system only suggests if vibes match
  Future<List<PartnershipMatch>> findMatches(
    String userId,
    String category,
  ) async {
    // Step 1: Find potential partners (category, location, etc.)
    final candidates = await _findPotentialPartners(userId, category);
    
    // Step 2: VIBE CHECK - Filter by compatibility
    final vibeMatches = <PartnershipMatch>[];
    for (final candidate in candidates) {
      final vibeCheck = await checkVibeCompatibility(
        userId,
        candidate.id,
        candidate.type,
      );
      
      // ⚠️  ONLY include if vibes match (70%+)
      if (vibeCheck.isMatch) {
        vibeMatches.add(PartnershipMatch(
          partner: candidate,
          vibeScore: vibeCheck.score,
          vibeReasoning: vibeCheck.reasoning,
          // ... other match details
        ));
      }
      // If vibes don't match, silently exclude
      // No suggestion shown to either party
    }
    
    // Step 3: Sort by vibe compatibility + other factors
    vibeMatches.sort((a, b) => b.vibeScore.compareTo(a.vibeScore));
    
    return vibeMatches;
  }
  
  /// User/business can always decline suggested partnerships
  Future<void> declinePartnership(
    String partnershipId,
    String declinerUserId,
    String? reason,
  ) async {
    final partnership = await getPartnership(partnershipId);
    
    // Update status
    await _updatePartnershipStatus(
      partnershipId,
      PartnershipStatus.declined,
      declinerUserId,
      reason,
    );
    
    // Notify proposer
    await _notifyPartnershipDeclined(partnership, reason);
    
    // Learn from decline for future matching
    await _updateMatchingModel(declinerUserId, partnership, declined: true);
  }
}
```

### **2. Filterable Event Marketplace**

**UI: Brand Dashboard → "Discover Events to Sponsor"**

```
┌─────────────────────────────────────────────────────────────┐
│  🔍 Find Events to Sponsor                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Filters:                                                   │
│  📍 Location: [Brooklyn ▼]                                  │
│  📅 Date Range: [Next 30 Days ▼]                            │
│  🏷️ Category: [Food & Dining ▼]                             │
│  👥 Min Attendees: [20] ─────────○────── [100]             │
│  💰 Budget: [$100] ─────○──────────── [$5,000]             │
│  📱 Influencer Size: [10K+ followers]                       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🌟 Recommended for Your Brand                              │
│                                                             │
│  ┌──────────────────────────────────────────────┐          │
│  │ 🍽️ Farm-to-Table Dinner Experience           │          │
│  │ By @foodie_sarah (52K followers)             │          │
│  │                                               │          │
│  │ 📍 The Garden Restaurant, Brooklyn            │          │
│  │ 📅 Dec 15, 2025 • 7:00 PM                    │          │
│  │ 👥 25 attendees • $75/ticket                  │          │
│  │                                               │          │
│  │ 🎯 Seeking: Product Sponsor (Olive Oil)      │          │
│  │ 💰 Budget: $500-1,000 or product              │          │
│  │                                               │          │
│  │ Match Score: 98% ⭐                           │          │
│  │ - Your product fits perfectly                │          │
│  │ - Audience demographic match                 │          │
│  │ - Host's content aligns with brand           │          │
│  │                                               │          │
│  │ [View Details] [Propose Sponsorship]         │          │
│  └──────────────────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### **3. Event Visibility Control**

**Event hosts choose sponsorship visibility:**

```dart
enum SponsorshipVisibility {
  none,              // Not seeking sponsors
  invitation,        // Invite-only (host approves brands first)
  marketplace,       // Visible in brand discovery search
  featured,          // Featured sponsorship opportunities (premium)
}

class ExpertiseEvent {
  // ... existing fields ...
  
  // New sponsorship fields
  SponsorshipVisibility sponsorshipVisibility;
  List<SponsorshipOpportunity> sponsorshipOpportunities;
  int maxSponsors;
  bool acceptingProductSponsors;
  bool acceptingFinancialSponsors;
}
```

---

## 🤝 Multi-Party Partnership Model

### **From 2-Party to N-Party:**

**Old Model (Current):**
```
Expert + Business = Partnership
├─ Expert: 50%
└─ Business: 50%
```

**New Model (Multi-Party):**
```
Primary Partnership + Sponsors = Multi-Party Event
├─ Influencer/Expert: 40%
├─ Venue/Restaurant: 30%
├─ Sponsor 1 (Oil Company): 20%
└─ Sponsor 2 (Wine Company): 10%
```

### **Data Model:**

```dart
enum PartnerRole {
  primaryHost,        // Lead organizer (influencer/expert)
  coHost,             // Equal partner (restaurant)
  financialSponsor,   // Cash contribution
  productSponsor,     // Product contribution
  venueSponsor,       // Provides venue
  mediaPartner,       // Promotion support
  technologySponsor,  // Tech/equipment
}

enum SponsorshipTier {
  title,      // Title sponsor (biggest contribution)
  platinum,   // Major sponsor
  gold,       // Mid-level sponsor
  silver,     // Supporting sponsor
  bronze,     // Minor sponsor
  inkind,     // In-kind/product only
}

class EventPartner {
  final String id;
  final String userId;        // User ID or Business ID
  final PartnerRole role;
  final SponsorshipTier? tier;
  
  // Contribution tracking
  final SponsorContribution contribution;
  
  // Revenue share
  final double revenueSharePercentage;
  
  // Status
  final PartnerStatus status;
  final DateTime? joinedAt;
  final DateTime? approvedAt;
  
  // Visibility
  final bool displayOnEvent;  // Show as sponsor on event page
  final int displayOrder;     // Order in sponsor list
  final String? customMessage; // "Proudly sponsored by..."
}

class SponsorContribution {
  final String partnerId;
  
  // Financial contribution
  final double? cashAmount;
  final PaymentStatus? cashPaymentStatus;
  final DateTime? cashPaidAt;
  
  // Product contribution
  final List<ProductItem>? products;
  final double? productRetailValue;
  final bool productsForSale;
  final ProductSalesTracking? salesTracking;
  
  // Combined value
  double get totalContributionValue {
    return (cashAmount ?? 0) + (productRetailValue ?? 0);
  }
}

class ProductItem {
  final String id;
  final String name;
  final String? sku;
  final int quantity;
  final double unitRetailPrice;
  final double unitCostPrice;    // For margin calculation
  final String? description;
  final String? imageUrl;
  final bool forSale;
  final bool forSample;          // Free samples to attendees
  final bool forUseInEvent;      // Used in event (e.g., cooking)
}

class ProductSalesTracking {
  final String productItemId;
  final int quantityAvailable;
  final int quantitySold;
  final int quantityGivenAway;
  final int quantityUsedInEvent;
  
  final double totalSalesRevenue;
  final double platformFee;      // SPOTS 10%
  final Map<String, double> revenueDistribution; // partnerId -> amount
  
  final List<ProductSale> sales; // Individual sale records
}

class ProductSale {
  final String id;
  final String productItemId;
  final String buyerId;          // Who bought it
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime soldAt;
  final String? paymentIntentId; // Stripe payment
  final PaymentStatus paymentStatus;
}
```

---

## 🤝 Partnership Approval & Decline Rights

### **CRITICAL: Both Parties Can Always Say No**

**The Rule:**
> System ONLY suggests partnerships where vibes match (70%+), but either party can still decline for any reason. No forced partnerships.

### **Approval Flow:**

```dart
enum PartnershipProposalStatus {
  proposed,      // Initial proposal sent
  reviewing,     // Partner is reviewing
  accepted,      // Partner accepted
  declined,      // Partner declined
  countered,     // Partner counter-proposed
  expired,       // No response after 7 days
}

class PartnershipProposal {
  final String id;
  final String proposerId;
  final String partnerId;
  final PartnershipProposalStatus status;
  
  /// Either party can decline
  final bool proposerCanDecline = true;
  final bool partnerCanDecline = true;
  
  /// Vibes must match for proposal to be sent
  final VibeCompatibility vibeMatch;
  final bool vibesMatch; // Must be true to send proposal
  
  /// Decline reasons (optional but helpful)
  final String? declineReason;
  final DeclineCategory? declineCategory;
}

enum DeclineCategory {
  timing,              // Not right now
  capacity,            // Too busy
  notInterested,       // Not interested in this event
  differentVision,     // Different event approach
  previousExperience,  // Bad past experience
  other,               // Other reason
}
```

### **User Can Decline Incoming Partnership Requests:**

```
┌──────────────────────────────────────────┐
│  Partnership Request from Premium Oil Co.│
├──────────────────────────────────────────┤
│                                          │
│  They want to sponsor your dinner event  │
│                                          │
│  Vibe Match: 92% ⭐⭐⭐⭐⭐                │
│  - Value alignment: Excellent            │
│  - Style compatibility: Great            │
│  - Quality focus: Aligned                │
│                                          │
│  Offering:                               │
│  💰 $300 cash                            │
│  📦 20 bottles premium oil               │
│                                          │
│  Your potential earnings: +$214          │
│                                          │
│  [Accept] [Negotiate Terms] [Decline]    │
│                                          │
└──────────────────────────────────────────┘
```

**If user clicks "Decline":**

```
┌──────────────────────────────────────────┐
│  Decline Partnership Request             │
├──────────────────────────────────────────┤
│                                          │
│  Why decline? (optional - helps us learn)│
│                                          │
│  ○ Not the right timing                  │
│  ○ Event is already full of sponsors     │
│  ○ Don't want oil at this event          │
│  ○ Prefer different sponsor type         │
│  ● Other reason                          │
│                                          │
│  Optional note to sponsor:               │
│  [Thank you for the offer, but I'm       │
│   keeping this event small and intimate  │
│   without sponsors this time.]           │
│                                          │
│  [Cancel] [Confirm Decline]              │
│                                          │
└──────────────────────────────────────────┘
```

### **Business Can Decline Partnership Proposals:**

```
┌──────────────────────────────────────────┐
│  Partnership Proposal from Sarah Chen    │
├──────────────────────────────────────────┤
│                                          │
│  She wants to host a workshop at your    │
│  coffee shop.                            │
│                                          │
│  Vibe Match: 85% ⭐⭐⭐⭐                  │
│  - Communication style: Compatible        │
│  - Event approach: Aligned               │
│  - Quality expectations: Matched         │
│                                          │
│  Event: Coffee Brewing Workshop          │
│  Date: Dec 15, 2025                      │
│  Your earnings: ~$182                    │
│                                          │
│  [Accept] [Counter-Propose] [Decline]    │
│                                          │
└──────────────────────────────────────────┘
```

**If business clicks "Decline":**

```
┌──────────────────────────────────────────┐
│  Decline Partnership Proposal            │
├──────────────────────────────────────────┤
│                                          │
│  Reason for declining?                   │
│                                          │
│  ○ Too busy on that date                 │
│  ○ Not enough capacity                   │
│  ● Different vision for our space        │
│  ○ Prefer different revenue split        │
│  ○ Other reason                          │
│                                          │
│  Message to Sarah (optional):            │
│  [We appreciate the proposal, but we're  │
│   focusing on our own events right now.  │
│   Maybe we can partner in the future!]   │
│                                          │
│  [Cancel] [Send Decline]                 │
│                                          │
└──────────────────────────────────────────┘
```

### **Why Vibe Matching + Decline Rights Work Together:**

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  WITHOUT vibe matching:                         │
│  ├─ 100 proposals sent                          │
│  ├─ 92 declined (bad fit, spam)                 │
│  ├─ 8 accepted                                  │
│  └─ Lots of wasted time, frustrated users       │
│                                                 │
│  WITH vibe matching + decline rights:           │
│  ├─ 20 proposals sent (only 70%+ matches)       │
│  ├─ 4 declined (timing, capacity, preferences)  │
│  ├─ 16 accepted                                 │
│  └─ Better hit rate, less spam, happier users   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Key Benefits:**

✅ **Vibe matching = Pre-filter** (removes obvious bad fits)  
✅ **Decline rights = Final say** (personal preferences still matter)  
✅ **Less spam** (only good matches get proposed)  
✅ **Higher acceptance rate** (better matches)  
✅ **User control** (never forced into partnerships)  
✅ **Learning system** (declines improve future matching)  

### **Learning from Declines:**

```dart
class PartnershipLearningSystem {
  /// Learn from declined proposals to improve future matching
  Future<void> learnFromDecline(
    String proposalId,
    String declinerId,
    DeclineCategory category,
    String? reason,
  ) async {
    final proposal = await _getProposal(proposalId);
    
    // Update user preferences
    await _updateUserPreferences(declinerId, {
      'declinedPartnerType': proposal.partnerType,
      'declineReason': category,
      'declineContext': reason,
    });
    
    // Adjust matching algorithm
    if (category == DeclineCategory.differentVision) {
      // Lower vibe matching weight for this dimension
      await _adjustVibeWeights(declinerId, proposal.partnerId);
    }
    
    if (category == DeclineCategory.timing) {
      // Don't penalize match quality, just bad timing
      // No algorithm adjustment needed
    }
    
    // Improve future suggestions
    await _updateMatchingModel(declinerId, proposal);
  }
}
```

---

## 💰 Multi-Party Revenue Distribution

### **Complex Revenue Splits:**

#### **Scenario 1: Ticket Sales (Primary Revenue)**

**Event:** Dinner for 25 attendees @ $75/ticket = $1,875

**Partners:**
- Influencer (Primary Host): 40%
- Restaurant (Venue): 30%
- Oil Company (Product Sponsor): 15%
- Wine Company (Product Sponsor): 15%

**Distribution:**
```
Gross Revenue: $1,875
├─ Stripe Fee (2.9% + $0.30): ~$59
├─ SPOTS Platform Fee (10%): $187.50
└─ Net Revenue (87%): $1,628.50
    ├─ Influencer (40%): $651.40
    ├─ Restaurant (30%): $488.55
    ├─ Oil Company (15%): $244.28
    └─ Wine Company (15%): $244.27
```

#### **Scenario 2: Product Sales (Secondary Revenue)**

**Product Sold at Event:**
- 15 bottles of oil @ $25 = $375
- 10 bottles of wine @ $35 = $350
- Total: $725

**Oil Sales Distribution:**
```
Oil Sales: $375
├─ SPOTS Platform Fee (10%): $37.50
└─ Net: $337.50
    ├─ Oil Company (60%): $202.50 (they supplied it)
    ├─ Influencer (25%): $84.38 (they sold it)
    └─ Restaurant (15%): $50.62 (venue facilitation)
```

**Wine Sales Distribution:**
```
Wine Sales: $350
├─ SPOTS Platform Fee (10%): $35.00
└─ Net: $315.00
    ├─ Wine Company (60%): $189.00
    ├─ Influencer (25%): $78.75
    └─ Restaurant (15%): $47.25
```

#### **Total Event Revenue:**

```
TOTAL COLLECTED: $2,950
├─ Ticket Sales: $1,875
├─ Oil Sales: $375
└─ Wine Sales: $700

DISTRIBUTION:
├─ SPOTS Total Platform Fee: $260.00 (8.8% effective)
├─ Stripe Fees: ~$85
└─ Partners Total: $2,605
    ├─ Influencer: $814.53 (27.6%)
    ├─ Restaurant: $586.42 (19.9%)
    ├─ Oil Company: $446.78 (15.1%)
    └─ Wine Company: $433.27 (14.7%)
```

### **Revenue Split Configuration UI:**

```dart
class RevenueDistributionBuilder extends StatefulWidget {
  final List<EventPartner> partners;
  
  // Allows hosts to configure:
  // - Base revenue split (from ticket sales)
  // - Product sales splits (per product)
  // - Bonus allocations (performance-based)
}
```

**UI Flow:**
```
┌──────────────────────────────────────────────┐
│  Configure Revenue Distribution              │
├──────────────────────────────────────────────┤
│                                              │
│  Ticket Sales ($1,875 projected)             │
│                                              │
│  Influencer (You)     [40%] ───○─── [$750]  │
│  The Garden           [30%] ──○──── [$562]  │
│  Oil Co Sponsor       [15%] ─○───── [$281]  │
│  Wine Co Sponsor      [15%] ─○───── [$281]  │
│                       ────────────────────   │
│                       100% ✅      $1,874    │
│                                              │
│  ─────────────────────────────────────────   │
│                                              │
│  Product Sales (Oil - $375 projected)        │
│                                              │
│  Oil Company          [60%] ────○── [$225]  │
│  Influencer (You)     [25%] ──○──── [$94]   │
│  The Garden           [15%] ─○───── [$56]   │
│                       ────────────────────   │
│                       100% ✅      $375      │
│                                              │
│  [Save Configuration] [Send to Partners]    │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🔍 Sponsor Discovery Flow

### **Complete User Journey:**

#### **1. Brand Searches for Events**

```
Oil Company Dashboard:
├─ "Discover Events to Sponsor"
├─ Set filters (Food, Brooklyn, 20+ attendees)
├─ AI shows recommended events
└─ See influencer dinner event (98% match)
```

#### **2. Brand Reviews Event Details**

```
Event Detail Page:
├─ Event description
├─ Host profile (Influencer: 52K followers)
├─ Venue details (Restaurant)
├─ Audience demographics
├─ Sponsorship opportunities available
├─ Requested contribution ($500-1,000 or product)
└─ Expected ROI (exposure, sales, brand alignment)
```

#### **3. Brand Proposes Sponsorship**

```
Sponsorship Proposal Form:
├─ Contribution Type: [Financial / Product / Hybrid]
├─ If Financial: Amount [$_____]
├─ If Product:
│   ├─ Product: [Premium Olive Oil]
│   ├─ Quantity: [20 bottles]
│   ├─ Retail Value: [$400]
│   ├─ For Sale? [Yes ✓] [No]
│   └─ For Sampling? [Yes ✓] [No]
├─ Sponsorship Tier: [Gold Sponsor ▼]
├─ Desired Branding:
│   ├─ Logo on event page? [Yes ✓]
│   ├─ Mention in promotion? [Yes ✓]
│   ├─ Booth/table at event? [Yes ✓]
│   └─ Social media tag? [Yes ✓]
├─ Message to Hosts: [____________________]
└─ Proposed Revenue Split: [Auto-calculated ▼]
```

#### **4. Hosts Review Proposal**

```
Influencer receives notification:

┌────────────────────────────────────────┐
│  🎉 New Sponsorship Proposal!          │
├────────────────────────────────────────┤
│                                        │
│  Premium Olive Oil Co.                 │
│  wants to sponsor your event           │
│                                        │
│  Offering:                             │
│  💰 $300 cash                          │
│  📦 20 bottles premium oil ($400)      │
│                                        │
│  They want:                            │
│  ✓ Logo on event page                 │
│  ✓ Product sales at event              │
│  ✓ Social media mentions               │
│                                        │
│  Your Revenue Share:                   │
│  From tickets: +$120 (from their cash) │
│  From oil sales: +$94 (if sold)        │
│  Total potential: +$214                │
│                                        │
│  Brand Match: 98% ⭐                   │
│  - Product fits your content           │
│  - Quality brand alignment             │
│  - Fair terms                          │
│                                        │
│  [Accept] [Negotiate] [Decline]        │
│                                        │
└────────────────────────────────────────┘
```

#### **5. Multi-Party Agreement**

Once influencer accepts:

```
Restaurant (venue) receives notification:

┌────────────────────────────────────────┐
│  📢 Event Update                       │
├────────────────────────────────────────┤
│                                        │
│  New sponsor joined your event!        │
│                                        │
│  Premium Olive Oil Co.                 │
│  Contribution: $300 + 20 bottles       │
│                                        │
│  Your Updated Revenue Share:           │
│  From tickets: $488 (+$90 from sponsor)│
│  From oil sales: $51 (15% of sales)    │
│                                        │
│  Event Total Value: $2,575 (+$700)     │
│                                        │
│  Impact:                               │
│  ✓ Higher quality experience           │
│  ✓ Premium brand association           │
│  ✓ Additional revenue stream           │
│                                        │
│  [View Agreement] [Accept] [Questions?]│
│                                        │
└────────────────────────────────────────┘
```

---

## 📊 In-App Payment & Contribution Tracking

### **Comprehensive Tracking Dashboard**

**For Event Hosts (Influencer View):**

```
┌────────────────────────────────────────────────────┐
│  Event Financial Dashboard                         │
│  Farm-to-Table Dinner Experience                   │
├────────────────────────────────────────────────────┤
│                                                    │
│  💰 Revenue Summary                                │
│                                                    │
│  Ticket Sales                                      │
│  ├─ Sold: 25/25 tickets @ $75                     │
│  ├─ Gross: $1,875                                  │
│  ├─ SPOTS Fee: -$187.50                           │
│  ├─ Stripe Fee: -$58.68                           │
│  └─ Net: $1,628.82                                 │
│                                                    │
│  Product Sales                                     │
│  ├─ Oil: 15/20 sold @ $25 = $375                  │
│  ├─ Wine: 10/10 sold @ $35 = $350                 │
│  ├─ Total Gross: $725                             │
│  ├─ SPOTS Fee: -$72.50                            │
│  └─ Net: $652.50                                   │
│                                                    │
│  Sponsor Contributions                             │
│  ├─ Oil Co: $300 (cash) ✅ Paid                   │
│  ├─ Wine Co: $400 (product) ✅ Delivered          │
│  └─ Total: $700                                    │
│                                                    │
│  ══════════════════════════════════════════        │
│  TOTAL EVENT VALUE: $3,300                         │
│  ══════════════════════════════════════════        │
│                                                    │
│  📦 Your Earnings Breakdown                        │
│                                                    │
│  From Ticket Sales (40%):    $651.53              │
│  From Oil Sales (25%):       $93.75               │
│  From Wine Sales (25%):      $87.50               │
│  From Sponsor Cash (40%):    $120.00              │
│  ─────────────────────────────────────            │
│  TOTAL EARNINGS:             $952.78              │
│  Status: ⏳ Pending (pays 2 days post-event)      │
│                                                    │
│  ─────────────────────────────────────            │
│                                                    │
│  👥 Partner Contributions & Payments              │
│                                                    │
│  🏢 The Garden (Restaurant)                        │
│  Contribution: Venue + Service                     │
│  Earnings: $586.42                                 │
│  Status: ⏳ Pending payout                         │
│                                                    │
│  🫒 Premium Olive Oil Co.                          │
│  Cash: $300.00 ✅ Paid Nov 10                     │
│  Product: 20 bottles ($400 value) ✅ Delivered    │
│  Sales: 15 bottles sold ($375)                     │
│  Earnings: $446.78 (cash share + product sales)   │
│  Status: ⏳ Pending payout                         │
│                                                    │
│  🍷 Artisan Wines                                  │
│  Product: 10 bottles ($400 value) ✅ Delivered    │
│  Sales: 10 bottles sold ($350)                     │
│  Earnings: $433.27                                 │
│  Status: ⏳ Pending payout                         │
│                                                    │
│  ─────────────────────────────────────            │
│                                                    │
│  📈 Platform Fee to SPOTS: $260.00                │
│  💳 Payment Processing: $85.18                    │
│                                                    │
│  [Export Report] [View Receipts] [Tax Docs]       │
│                                                    │
└────────────────────────────────────────────────────┘
```

### **Product Inventory Tracking**

**For Sponsors (Oil Company View):**

```
┌────────────────────────────────────────────────────┐
│  Your Sponsorship: Farm-to-Table Dinner           │
├────────────────────────────────────────────────────┤
│                                                    │
│  📦 Product Contribution Status                    │
│                                                    │
│  Premium Olive Oil - 375ml                         │
│  ├─ Contributed: 20 bottles                        │
│  ├─ Retail Value: $25/bottle = $500 total         │
│  ├─ Cost Basis: $12/bottle = $240 total           │
│  └─ Delivery: ✅ Confirmed Nov 12                  │
│                                                    │
│  Usage Breakdown:                                  │
│  ├─ Used in Event: 3 bottles (cooking)            │
│  ├─ Given as Samples: 2 bottles (attendees)       │
│  └─ Available for Sale: 15 bottles                │
│                                                    │
│  💰 Sales Tracking (Live)                          │
│  ├─ Sold: 15/15 bottles ✅                         │
│  ├─ Revenue: $375.00                               │
│  ├─ Your Share (60%): $225.00                     │
│  ├─ ROI: +93% on cost basis                       │
│  └─ Status: ⏳ Payout in 2 days                    │
│                                                    │
│  📊 Brand Exposure Metrics                         │
│  ├─ Event Attendees: 25 people                    │
│  ├─ Social Reach: 52K (influencer followers)      │
│  ├─ Social Mentions: 12 posts                     │
│  ├─ Product Tastings: 25 samples                  │
│  └─ Direct Sales: 15 bottles                      │
│                                                    │
│  💵 Total Investment vs. Return                    │
│  Investment:                                       │
│  ├─ Cash Contribution: $300                        │
│  ├─ Product Cost: $240 (20 bottles @ $12)         │
│  └─ Total Cost: $540                               │
│                                                    │
│  Returns:                                          │
│  ├─ Cash Share: $120 (from ticket sales)          │
│  ├─ Product Sales: $225 (60% of $375)             │
│  ├─ Total Revenue: $345                            │
│  └─ Net: -$195 (but gained $2.6K in exposure!)    │
│                                                    │
│  🎯 Campaign Goals: ✅ 3/3 Met                     │
│  ├─ Brand Awareness: 52K reach ✅                  │
│  ├─ Product Sampling: 25 people ✅                 │
│  └─ Direct Sales: 15 bottles ✅                    │
│                                                    │
│  [View Analytics] [Export Report] [Rate Event]    │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## 🔐 Payment & Contribution Verification

### **Multi-Step Verification System:**

```dart
class ContributionVerificationService {
  /// Step 1: Sponsor commits to contribution
  Future<SponsorCommitment> commitContribution(
    String eventId,
    String sponsorId,
    SponsorContribution contribution,
  ) async {
    // Create commitment record
    // Generate payment link if cash
    // Generate delivery tracking if product
  }
  
  /// Step 2: Payment verification
  Future<void> verifyCashContribution(
    String commitmentId,
    String paymentIntentId,
  ) async {
    // Confirm Stripe payment received
    // Mark contribution as paid
    // Notify event hosts
  }
  
  /// Step 3: Product delivery verification
  Future<void> verifyProductDelivery(
    String commitmentId,
    String deliveryConfirmationCode,
    List<String> photos,
  ) async {
    // Host confirms product received
    // Verify quantity and condition
    // Update inventory tracking
  }
  
  /// Step 4: Sales tracking (real-time)
  Future<ProductSale> recordProductSale(
    String eventId,
    String productItemId,
    String buyerId,
    int quantity,
    String paymentIntentId,
  ) async {
    // Record individual sale
    // Calculate revenue splits
    // Update inventory
    // Queue for payout
  }
  
  /// Step 5: Post-event reconciliation
  Future<EventReconciliation> reconcileEvent(
    String eventId,
  ) async {
    // Final accounting:
    // - All ticket sales confirmed
    // - All product sales recorded
    // - All sponsor contributions verified
    // - Calculate final payouts
    // - Generate tax documents
  }
}
```

### **Status Tracking:**

```dart
enum ContributionStatus {
  proposed,       // Sponsor proposed, awaiting host approval
  accepted,       // Host accepted, awaiting payment/delivery
  paymentPending, // Cash payment initiated
  paymentConfirmed, // Cash received
  deliveryScheduled, // Product delivery arranged
  deliveryConfirmed, // Product received and verified
  active,         // Contribution active at event
  reconciled,     // Post-event, all sales counted
  payoutPending,  // Awaiting payout
  completed,      // Payout sent, all done
  disputed,       // Issue requiring resolution
}
```

---

## 🎨 Sponsor Branding & Visibility

### **Sponsor Display on Event Page:**

```
┌──────────────────────────────────────────┐
│  🍽️ Farm-to-Table Dinner Experience     │
│  by @foodie_sarah                        │
├──────────────────────────────────────────┤
│  📅 December 15, 2025                    │
│  📍 The Garden Restaurant, Brooklyn      │
│  💵 $75/person • 25 seats                │
│  ⏰ 7:00 PM - 10:00 PM                   │
│                                          │
│  [Description...]                        │
│                                          │
│  ─────────────────────────────────────── │
│                                          │
│  🤝 Event Partners                       │
│                                          │
│  Presented by:                           │
│  ┌─────────────────────────────────┐    │
│  │  [LOGO] Premium Olive Oil Co.   │    │
│  │  Title Sponsor                   │    │
│  └─────────────────────────────────┘    │
│                                          │
│  Venue Partner:                          │
│  🏢 The Garden Restaurant                │
│                                          │
│  Additional Sponsors:                    │
│  🍷 Artisan Wines (Beverage Partner)    │
│                                          │
│  ─────────────────────────────────────── │
│                                          │
│  🛒 Shop Event Products                  │
│                                          │
│  🫒 Premium Olive Oil - $25              │
│     Take home the oil from dinner!       │
│     [Add to Cart]                        │
│                                          │
│  🍷 Artisan Red Wine - $35               │
│     Featured wine pairing                │
│     [Add to Cart]                        │
│                                          │
│  [Buy Ticket] [Save Event] [Share]       │
│                                          │
└──────────────────────────────────────────┘
```

### **Sponsor Benefits Tiers:**

```dart
class SponsorBenefits {
  final SponsorshipTier tier;
  final Map<String, bool> benefits;
  
  static Map<SponsorshipTier, Map<String, bool>> defaultBenefits = {
    SponsorshipTier.title: {
      'logoOnEventPage': true,
      'prominentPlacement': true,
      'socialMediaMentions': true,
      'productSalesOpportunity': true,
      'boothAtEvent': true,
      'speakingOpportunity': true,
      'brandedMaterials': true,
      'exclusivity': true,  // Only title sponsor in category
    },
    SponsorshipTier.gold: {
      'logoOnEventPage': true,
      'socialMediaMentions': true,
      'productSalesOpportunity': true,
      'boothAtEvent': true,
      'brandedMaterials': true,
    },
    SponsorshipTier.silver: {
      'logoOnEventPage': true,
      'socialMediaMentions': false,
      'productSalesOpportunity': true,
      'boothAtEvent': false,
    },
    SponsorshipTier.inkind: {
      'logoOnEventPage': true,
      'productSalesOpportunity': false,  // Only for sampling
    },
  };
}
```

---

## 📊 Success Metrics

### **For Brands (Sponsors):**
- Clear ROI tracking
- Brand exposure metrics (reach, impressions, engagement)
- Product sampling data (if applicable)
- Direct sales data (if selling at event)
- Lead generation (attendee contacts if permitted)

### **For Event Hosts (Influencers):**
- Additional revenue from sponsors (+30-50%)
- Higher quality events (better products, more resources)
- Less financial risk (sponsors share costs)
- Stronger brand partnerships

### **For Venues:**
- Increased foot traffic
- Premium brand associations
- Additional revenue share
- Repeat partnership opportunities

### **For SPOTS:**
- Platform fee from all revenue streams
- More valuable events (higher quality)
- Stronger network effects
- Sustainable monetization

---

## 🏗️ Implementation Phases

### **Phase 1: Brand Discovery (2 weeks)**

**Week 1:**
- Event marketplace search interface
- Filter system for brands
- Event sponsorship flags
- Basic matching algorithm

**Week 2:**
- AI-powered recommendations
- Sponsorship opportunity templates
- Proposal submission system

**Deliverables:**
- ✅ Brand can search events
- ✅ Brand can view sponsorship opportunities
- ✅ Brand can submit proposals

---

### **Phase 2: Multi-Party Partnerships (2 weeks)**

**Week 1:**
- Multi-partner data models
- Revenue distribution calculator
- Partner role system
- Approval workflow (multi-party)

**Week 2:**
- UI for configuring revenue splits
- Partner notification system
- Agreement management
- Status tracking dashboard

**Deliverables:**
- ✅ Support 3+ partners per event
- ✅ Flexible revenue splits
- ✅ Multi-party approval workflow

---

### **Phase 3: Product Sponsorship & Tracking (2 weeks)**

**Week 1:**
- Product contribution model
- Inventory tracking system
- Product sales at events
- Sales revenue distribution

**Week 2:**
- Product verification flow
- Real-time inventory updates
- Sales tracking dashboard
- Post-event reconciliation

**Deliverables:**
- ✅ Product contribution system
- ✅ Inventory tracking
- ✅ Sales revenue splits
- ✅ Complete reconciliation

---

### **Phase 4: Payment & Verification (2 weeks)**

**Week 1:**
- Multi-party payment processing
- Contribution verification system
- Delivery confirmation
- Payment status tracking

**Week 2:**
- Automated reconciliation
- Payout distribution (N-way splits)
- Tax documentation
- Dispute resolution

**Deliverables:**
- ✅ Verified contributions
- ✅ Automated payouts
- ✅ Complete audit trail
- ✅ Tax compliance

---

### **Phase 5: Analytics & Reporting (1 week)**

**Week 1:**
- Sponsor ROI dashboard
- Brand exposure metrics
- Event performance analytics
- Export & reporting tools

**Deliverables:**
- ✅ Complete financial dashboards
- ✅ ROI tracking for brands
- ✅ Export capabilities
- ✅ Admin oversight tools

---

## 🎯 Timeline Summary

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| **Phase 1: Brand Discovery** | 2 weeks | Event Partnership Plan |
| **Phase 2: Multi-Party Partnerships** | 2 weeks | Phase 1 |
| **Phase 3: Product Tracking** | 2 weeks | Phase 2 |
| **Phase 4: Payment & Verification** | 2 weeks | Phase 3, Stripe Integration |
| **Phase 5: Analytics** | 1 week | Phases 1-4 |
| **Testing & QA** | 1 week | All phases |
| **TOTAL** | **10 weeks** | |

---

## 💰 Revenue Opportunity for SPOTS

### **Projected Revenue Growth:**

**Without Multi-Party Sponsorships:**
- 200 paid events/month
- Average ticket revenue: $500/event
- SPOTS platform fee (10%): $50/event
- **Monthly Revenue: $10,000**

**With Multi-Party Sponsorships:**
- Same 200 events
- +60% have sponsors (120 events)
- Average sponsor contribution: $700
- Average product sales at event: $300
- Total per sponsored event: $1,500
- SPOTS fee on sponsorships (10%): $150

**New Monthly Revenue:**
```
Base Events (80 events × $50):        $4,000
Sponsored Events - Tickets (120 × $50): $6,000
Sponsored Events - Sponsorships (120 × $70): $8,400
Sponsored Events - Product Sales (120 × $30): $3,600
                                      ────────
TOTAL MONTHLY:                        $22,000

Growth: +120% from base
```

**Year 1 Projection:** ~$180K (vs $80K without sponsorships)

---

## 🔒 Trust & Safety

### **Verification Requirements:**

**For Sponsors:**
- ✅ Business verification (same as venue businesses)
- ✅ Valid payment method on file
- ✅ Product authenticity verification (if product sponsor)
- ✅ Tax documentation

**For Product Contributions:**
- ✅ Photos of products before delivery
- ✅ Host confirms receipt and quality
- ✅ Quantity verification
- ✅ Condition check

**Fraud Prevention:**
- ✅ Escrow for sponsor payments (held until event complete)
- ✅ Product delivery confirmation required
- ✅ Sales tracking verification
- ✅ Dispute resolution system

---

## 🎉 Example Success Stories

### **Story 1: Local Olive Oil Brand**
```
Premium Olive Oil Co. (small artisan producer)
Sponsored 5 dinner events in Q1
Investment: $2,500 cash + $1,000 products
Returns:
├─ Direct Revenue: $1,800 (from revenue shares)
├─ Product Sales: 85 bottles ($2,125)
├─ Brand Reach: 250K impressions
├─ Email Signups: 140 interested customers
└─ ROI: 217% + significant brand awareness
```

### **Story 2: Instagram Food Influencer**
```
@foodie_sarah (52K followers)
Hosted 3 sponsored dinners per month
Before Sponsorships: $800/event average
After Sponsorships: $1,200/event average (+50%)
Benefits:
├─ Higher quality events (better ingredients)
├─ Less financial risk (sponsors share costs)
├─ Stronger brand partnerships
└─ More professional production
```

### **Story 3: Restaurant Venue**
```
The Garden Restaurant
Hosted 8 sponsored events in 3 months
Before: $300/event (venue fee only)
After: $600/event (venue + revenue share)
Additional Benefits:
├─ New customers discovering restaurant
├─ Premium brand associations
├─ Midweek traffic boost
└─ Ongoing catering opportunities
```

---

## ✅ Summary

**What This Plan Adds:**

1. ✅ **Brand Discovery** - Companies can search for events to sponsor
2. ✅ **Multi-Party Partnerships** - 3+ partners per event
3. ✅ **Product Sponsorships** - Not just cash, but products too
4. ✅ **Sales Tracking** - If products sell, revenue automatically splits
5. ✅ **Complete Transparency** - Everyone sees contributions & payments
6. ✅ **Automated Distribution** - N-way revenue splits handled automatically

**Your Oil Company Example: ✅ FULLY ADDRESSED**

**Status:** Ready for implementation after Event Partnership Plan (Phase 1-5)

**Timeline:** 10 weeks

**Dependencies:**
- Event Partnership & Monetization Plan (Phases 1-2)
- Stripe Connect integration
- Business verification system

---

**This transforms SPOTS from 2-party event partnerships into a full multi-party sponsorship marketplace where brands discover, propose, and participate in authentic community events—with complete financial transparency and automatic revenue distribution.** 🚪✨💰🤝

---

**Plan Status:** ✅ Ready for Review & Approval  
**Next Step:** Review, approve, add to Master Plan Tracker  
**Last Updated:** November 21, 2025

