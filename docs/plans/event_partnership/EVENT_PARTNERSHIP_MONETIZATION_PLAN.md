# Event Partnership & Monetization System - Implementation Plan

**Created:** November 21, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** HIGH  
**Context:** Extension of Easy Event Hosting + Platform Monetization  
**Philosophy Alignment:** "The key opens doors" + "Always Learning With You" + "Business With Integrity"
**Core Principles:** Authentic connections, transparent fees, fair value exchange, vibe-based matching (ai2ai)

---

## 🎯 Executive Summary

This plan extends the Easy Event Hosting system to enable:
1. **User-Business Partnerships** - Qualified users and verified businesses co-host events
2. **Platform Monetization** - SPOTS earns a fair percentage of paid event revenue
3. **Payment Processing** - Integrated payment system with automatic revenue splits
4. **Financial Transparency** - Clear reporting for all parties

**Key Principle:** SPOTS facilitates authentic connections and earns a transparent fee for providing the platform—never compromising on "No Pay-to-Play" principles for discovery.

---

## 💰 Monetization Strategy

### **Revenue Model: Transparent Fee Structure**

**For Paid Events Only:**
- **10% platform fee to SPOTS** (infrastructure, matching, discovery, support)
- **+ Payment processor fees** (Stripe: ~2.9% + $0.30 per transaction)
- **Total effective fee: ~13%** (10% + 3%)
- Split remaining ~87% between partnership parties based on their agreement

**For Free Events:**
- No platform fee (builds community, drives engagement)
- SPOTS benefits from increased user engagement and network effects

### **Example Revenue Splits:**

#### **Scenario 1: Solo Expert Event**
```
Event Price: $25/ticket × 20 attendees = $500
├─ Stripe Fee (2.9% + $0.30): $14.50 + $6.00 = $20.50
├─ SPOTS Platform Fee (10%): $50.00
└─ Expert Payout (87%): $429.50
```

#### **Scenario 2: User-Business Partnership (50/50 split)**
```
Event Price: $30/ticket × 15 attendees = $450
├─ Stripe Fee (2.9% + $0.30): $13.05 + $4.50 = $17.55
├─ SPOTS Platform Fee (10%): $45.00
└─ Remaining Revenue (87%): $387.45
    ├─ Expert Share (50%): $193.73
    └─ Business Share (50%): $193.72
```

#### **Scenario 3: Business-Hosted Event (Solo)**
```
Event Price: $35/ticket × 25 attendees = $875
├─ Stripe Fee (2.9% + $0.30): $25.38 + $7.50 = $32.88
├─ SPOTS Platform Fee (10%): $87.50
└─ Business Payout (87%): $754.62
```

#### **Scenario 4: User-Business Partnership (Custom 70/30 split)**
```
Event Price: $40/ticket × 18 attendees = $720
├─ Stripe Fee (2.9% + $0.30): $20.88 + $5.40 = $26.28
├─ SPOTS Platform Fee (10%): $72.00
└─ Remaining Revenue (87%): $621.72
    ├─ Business Share (70%): $435.20
    └─ Expert Share (30%): $186.52
```

**Why This Structure?**
- **Transparent:** Users see exactly where money goes
  - 10% → SPOTS (platform, matching, infrastructure)
  - ~3% → Stripe (payment processing, security, compliance)
  - ~87% → Event hosts
- **Fair:** Lower than competitors (Eventbrite ~7-10% + processing, Ticketmaster 10-30%)
- **Honest:** Pass-through pricing on payment processing
- **Industry standard:** Separating platform fee from processing fee is common practice
- **Competitive:** Total ~13% is very competitive for full-service platform

---

## 🏗️ System Architecture

### **Core Components:**

```
┌─────────────────────────────────────────────────┐
│          Event Partnership System               │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────┐      │
│  │   Partnership Management Layer       │      │
│  │   - Partnership matching             │      │
│  │   - Qualification verification       │      │
│  │   - Agreement creation               │      │
│  └──────────────────────────────────────┘      │
│                    ↓                            │
│  ┌──────────────────────────────────────┐      │
│  │   Event Creation Layer               │      │
│  │   - Co-hosted event creation         │      │
│  │   - Partnership event templates      │      │
│  │   - Revenue split configuration      │      │
│  └──────────────────────────────────────┘      │
│                    ↓                            │
│  ┌──────────────────────────────────────┐      │
│  │   Payment Processing Layer           │      │
│  │   - Stripe integration               │      │
│  │   - Ticket sales                     │      │
│  │   - Platform fee calculation         │      │
│  │   - Automatic revenue splits         │      │
│  └──────────────────────────────────────┘      │
│                    ↓                            │
│  ┌──────────────────────────────────────┐      │
│  │   Payout Management Layer            │      │
│  │   - Earnings tracking                │      │
│  │   - Payout scheduling                │      │
│  │   - Financial reporting              │      │
│  └──────────────────────────────────────┘      │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 📋 Implementation Phases

### **PHASE 1: Partnership Foundation** (Week 1-2, 10 days)

#### **1.1 Partnership Data Models** (2 days)

**File: `lib/core/models/event_partnership.dart`**

```dart
enum PartnershipType {
  coHost,           // Equal partners in event hosting
  venueProvider,    // Business provides venue, expert hosts
  sponsorship,      // Business sponsors expert's event
  collaboration,    // Custom collaboration arrangement
}

enum PartnershipStatus {
  proposed,         // Partnership proposed, awaiting acceptance
  negotiating,      // Discussing terms
  active,           // Active partnership
  completed,        // Event completed successfully
  cancelled,        // Partnership cancelled
  disputed,         // Issue requiring resolution
}

class EventPartnership {
  final String id;
  final String businessId;
  final String expertId;
  final BusinessAccount business;
  final UnifiedUser expert;
  
  // Partnership details
  final PartnershipType type;
  final PartnershipStatus status;
  final String? customArrangementDetails;
  
  // Revenue split (if paid event)
  final RevenueSplit? revenueSplit;
  
  // Partnership scope
  final List<String> sharedResponsibilities;
  final String? venueLocation;
  final int? expectedEventCount; // For ongoing partnerships
  
  // Events
  final List<String> eventIds; // Events under this partnership
  
  // Terms and agreement
  final DateTime? termsAgreedAt;
  final String? termsVersion;
  final bool expertApproved;
  final bool businessApproved;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? endDate; // For term-limited partnerships
}

class RevenueSplit {
  final double spotsPlatformFeePercentage;  // Default 10%
  final double paymentProcessorFeePercentage; // Stripe ~2.9%
  final double fixedProcessorFee;           // Stripe $0.30 per transaction
  final double expertPercentage;            // e.g., 50%
  final double businessPercentage;          // e.g., 50%
  
  // Total fees (platform + processor)
  double get totalFeePercentage => 
    spotsPlatformFeePercentage + paymentProcessorFeePercentage;
  
  // Validation: expertPercentage + businessPercentage must equal 100
  bool get isValid => 
    (expertPercentage + businessPercentage - 100.0).abs() < 0.01;
}
```

**File: `lib/core/models/partnership_event.dart`**

```dart
class PartnershipEvent extends ExpertiseEvent {
  final EventPartnership partnership;
  final bool isCoHosted;
  
  // Revenue tracking (for paid events)
  final EventRevenue? revenue;
  
  // Co-hosting details
  final String primaryHostId; // Who leads the event
  final List<String> coHostIds;
  final Map<String, String> hostResponsibilities; // hostId -> responsibility
  
  // Venue details (if business provides venue)
  final bool isAtBusinessLocation;
  final String? businessVenueId;
}

class EventRevenue {
  final String eventId;
  final double ticketPrice;
  final int ticketsSold;
  final double grossRevenue; // ticketPrice × ticketsSold
  
  // Fee breakdown
  final double spotsPlatformFee;      // SPOTS fee (10% default)
  final double paymentProcessorFee;   // Stripe fee (~2.9% + $0.30/ticket)
  final double totalFees;             // spotsPlatformFee + paymentProcessorFee
  final double expertPayout;          // Expert's share
  final double businessPayout;        // Business's share
  
  // Payment processing
  final String? stripePaymentIntentId;
  final String? stripeTransferId;
  final PaymentStatus paymentStatus;
  
  // Payout tracking
  final DateTime? expertPayoutDate;
  final DateTime? businessPayoutDate;
  final String? expertPayoutMethod;
  final String? businessPayoutMethod;
}

enum PaymentStatus {
  pending,        // Payment not yet processed
  processing,     // Payment in progress
  completed,      // Payment successful
  partialRefund,  // Partial refund issued
  refunded,       // Full refund issued
  failed,         // Payment failed
  disputed,       // Payment disputed
}
```

**Deliverables:**
- ✅ Complete partnership data models
- ✅ Revenue split model with validation
- ✅ Event revenue tracking model
- ✅ Payment status tracking

---

#### **1.2 Partnership Matching Service** (3 days)

**File: `lib/core/services/event_partnership_matching_service.dart`**

```dart
class EventPartnershipMatchingService {
  /// Find qualified businesses for expert to partner with
  Future<List<PartnershipMatch>> findBusinessPartnersForExpert(
    UnifiedUser expert,
    String eventCategory,
    {
      String? location,
      PartnershipType? preferredType,
      int maxResults = 20,
    }
  ) async {
    // 1. Verify expert qualifications
    if (!expert.canHostEvents()) {
      throw Exception('Expert must have City-level expertise');
    }
    
    // 2. Find businesses matching category
    final businesses = await _findBusinessesByCategory(eventCategory);
    
    // 3. Filter by location if specified
    final localBusinesses = location != null
      ? _filterByLocation(businesses, location)
      : businesses;
    
    // 4. Filter by verification status
    final verifiedBusinesses = localBusinesses
      .where((b) => b.verification?.status == VerificationStatus.approved)
      .toList();
    
    // 5. Check business partnership preferences
    final interestedBusinesses = verifiedBusinesses
      .where((b) => _isBusinessInterestedInPartnerships(b))
      .toList();
    
    // 6. Calculate match scores
    final matches = await _calculatePartnershipMatches(
      expert: expert,
      businesses: interestedBusinesses,
      eventCategory: eventCategory,
      preferredType: preferredType,
    );
    
    // 7. Sort by match score
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    return matches.take(maxResults).toList();
  }
  
  /// Find qualified experts for business to partner with
  Future<List<PartnershipMatch>> findExpertPartnersForBusiness(
    BusinessAccount business,
    String eventCategory,
    {
      String? location,
      PartnershipType? preferredType,
      int maxResults = 20,
    }
  ) async {
    // 1. Verify business qualifications
    if (business.verification?.status != VerificationStatus.approved) {
      throw Exception('Business must be verified');
    }
    
    // 2. Find experts with required expertise
    final experts = await _findExpertsByCategory(eventCategory);
    
    // 3. Filter by location
    final localExperts = location != null
      ? _filterExpertsByLocation(experts, location)
      : experts;
    
    // 4. Filter by City-level or higher
    final qualifiedExperts = localExperts
      .where((e) => e.canHostEvents())
      .toList();
    
    // 5. Apply business's expert preferences
    final preferredExperts = _applyExpertPreferences(
      business: business,
      experts: qualifiedExperts,
    );
    
    // 6. Calculate match scores
    final matches = await _calculatePartnershipMatches(
      business: business,
      experts: preferredExperts,
      eventCategory: eventCategory,
      preferredType: preferredType,
    );
    
    // 7. Sort by match score
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    return matches.take(maxResults).toList();
  }
  
  /// Calculate partnership compatibility
  Future<double> calculatePartnershipCompatibility(
    UnifiedUser expert,
    BusinessAccount business,
    String eventCategory,
  ) async {
    double score = 0.0;
    
    // Category match (40%)
    if (business.categories.contains(eventCategory)) {
      score += 0.4;
    }
    
    // Location match (20%)
    if (_isLocationCompatible(expert, business)) {
      score += 0.2;
    }
    
    // Expertise level match (15%)
    final expertiseLevel = expert.getExpertiseLevel(eventCategory);
    if (expertiseLevel >= ExpertiseLevel.city) {
      score += 0.15;
    }
    
    // Preference alignment (15%)
    score += _calculatePreferenceAlignment(expert, business);
    
    // Past partnership success (10%)
    score += await _calculatePartnershipHistoryBonus(expert, business);
    
    return score.clamp(0.0, 1.0);
  }
}

class PartnershipMatch {
  final dynamic partner; // BusinessAccount or UnifiedUser
  final double matchScore;
  final String matchReason;
  final List<String> matchedCategories;
  final List<String> suggestedPartnershipTypes;
  final RevenueProjection? revenueProjection;
}

class RevenueProjection {
  final double estimatedTicketPrice;
  final int estimatedAttendees;
  final double estimatedGrossRevenue;
  final double estimatedPlatformFee;
  final double estimatedExpertPayout;
  final double estimatedBusinessPayout;
}
```

**Deliverables:**
- ✅ Partnership matching for experts
- ✅ Partnership matching for businesses
- ✅ Compatibility scoring algorithm
- ✅ Revenue projections for matches

---

#### **1.3 Partnership Management Service** (3 days)

**File: `lib/core/services/event_partnership_service.dart`**

```dart
class EventPartnershipService {
  /// Create partnership proposal
  Future<EventPartnership> proposePartnership({
    required String proposerId, // Expert or business ID
    required String partnerId,  // Other party ID
    required bool proposerIsBusiness,
    required PartnershipType type,
    required String category,
    RevenueSplit? revenueSplit,
    Map<String, dynamic>? customTerms,
  }) async {
    // 1. Verify qualifications
    await _verifyQualifications(proposerId, partnerId, proposerIsBusiness);
    
    // 2. Create partnership proposal
    final partnership = EventPartnership(
      id: _generatePartnershipId(),
      businessId: proposerIsBusiness ? proposerId : partnerId,
      expertId: proposerIsBusiness ? partnerId : proposerId,
      type: type,
      status: PartnershipStatus.proposed,
      revenueSplit: revenueSplit ?? _defaultRevenueSplit(),
      expertApproved: !proposerIsBusiness,
      businessApproved: proposerIsBusiness,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // ... other fields
    );
    
    // 3. Save to database
    await _savePartnership(partnership);
    
    // 4. Notify other party
    await _notifyPartnershipProposal(partnership);
    
    return partnership;
  }
  
  /// Accept partnership proposal
  Future<EventPartnership> acceptPartnership(
    String partnershipId,
    String acceptorId,
  ) async {
    final partnership = await getPartnership(partnershipId);
    
    // Verify acceptor is the partner
    _verifyIsPartner(partnership, acceptorId);
    
    // Update approval status
    final isExpert = partnership.expertId == acceptorId;
    final updated = partnership.copyWith(
      expertApproved: isExpert ? true : partnership.expertApproved,
      businessApproved: !isExpert ? true : partnership.businessApproved,
      status: PartnershipStatus.active,
      termsAgreedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _updatePartnership(updated);
    
    // Notify proposal acceptor
    await _notifyPartnershipAccepted(updated);
    
    return updated;
  }
  
  /// Negotiate partnership terms
  Future<EventPartnership> negotiateTerms(
    String partnershipId,
    String negotiatorId,
    {
      RevenueSplit? newRevenueSplit,
      Map<String, dynamic>? counterTerms,
    }
  ) async {
    final partnership = await getPartnership(partnershipId);
    _verifyIsPartner(partnership, negotiatorId);
    
    final updated = partnership.copyWith(
      status: PartnershipStatus.negotiating,
      revenueSplit: newRevenueSplit ?? partnership.revenueSplit,
      updatedAt: DateTime.now(),
      // Reset approvals when terms change
      expertApproved: false,
      businessApproved: false,
    );
    
    await _updatePartnership(updated);
    await _notifyTermsNegotiation(updated);
    
    return updated;
  }
  
  /// Get active partnerships for user
  Future<List<EventPartnership>> getActivePartnerships(String userId) async {
    final partnerships = await _getAllPartnershipsForUser(userId);
    return partnerships
      .where((p) => p.status == PartnershipStatus.active)
      .toList();
  }
  
  /// Get partnership history
  Future<List<EventPartnership>> getPartnershipHistory(String userId) async {
    return await _getAllPartnershipsForUser(userId);
  }
  
  /// Calculate partnership earnings
  Future<PartnershipEarnings> calculateEarnings(
    String partnershipId,
    {DateTime? startDate, DateTime? endDate}
  ) async {
    final partnership = await getPartnership(partnershipId);
    final events = await _getPartnershipEvents(
      partnershipId,
      startDate: startDate,
      endDate: endDate,
    );
    
    double totalGrossRevenue = 0;
    double totalPlatformFee = 0;
    double totalExpertPayout = 0;
    double totalBusinessPayout = 0;
    
    for (final event in events) {
      if (event.revenue != null) {
        totalGrossRevenue += event.revenue!.grossRevenue;
        totalPlatformFee += event.revenue!.spotsPlatformFee;
        totalExpertPayout += event.revenue!.expertPayout;
        totalBusinessPayout += event.revenue!.businessPayout;
      }
    }
    
    return PartnershipEarnings(
      partnershipId: partnershipId,
      eventCount: events.length,
      totalGrossRevenue: totalGrossRevenue,
      totalPlatformFee: totalPlatformFee,
      totalExpertPayout: totalExpertPayout,
      totalBusinessPayout: totalBusinessPayout,
      period: DateTimeRange(
        start: startDate ?? events.first.createdAt,
        end: endDate ?? DateTime.now(),
      ),
    );
  }
}
```

**Deliverables:**
- ✅ Partnership proposal system
- ✅ Partnership acceptance/rejection
- ✅ Terms negotiation
- ✅ Partnership history tracking
- ✅ Earnings calculation

---

#### **1.4 Partnership UI Components** (2 days)

**File: `lib/presentation/widgets/partnerships/partnership_discovery_widget.dart`**
- Show potential partners for users
- Display match scores and compatibility
- Show projected revenue splits
- "Propose Partnership" button

**File: `lib/presentation/widgets/partnerships/partnership_proposal_dialog.dart`**
- Partnership type selection
- Revenue split configuration
- Custom terms input
- Preview partnership agreement

**File: `lib/presentation/widgets/partnerships/partnership_card_widget.dart`**
- Display active partnerships
- Show partnership details
- View co-hosted events
- Partnership earnings summary

**File: `lib/presentation/pages/partnerships/partnerships_page.dart`**
- Active partnerships tab
- Partnership discovery tab
- Pending proposals tab
- Partnership history tab

**Deliverables:**
- ✅ Partnership discovery UI
- ✅ Proposal creation UI
- ✅ Partnership management UI
- ✅ Partnership history UI

---

### **PHASE 2: Payment Processing Integration** (Week 3-4, 10 days)

#### **2.1 Stripe Integration** (4 days)

**File: `lib/core/services/payment_service.dart`**

```dart
class PaymentService {
  final StripeService _stripe;
  
  /// Initialize Stripe Connect for partners
  /// Both experts and businesses need Stripe Connect accounts
  Future<StripeConnectAccount> createConnectAccount({
    required String userId,
    required bool isBusiness,
    required Map<String, dynamic> accountInfo,
  }) async {
    // Create Stripe Connect account
    final account = await _stripe.createConnectAccount(
      type: 'express', // Simplified onboarding
      email: accountInfo['email'],
      businessType: isBusiness ? 'company' : 'individual',
      capabilities: ['transfers'], // Enable payouts
    );
    
    // Save account ID to user/business profile
    await _saveStripeAccountId(userId, account.id);
    
    // Generate onboarding link
    final onboardingUrl = await _stripe.createAccountLink(
      accountId: account.id,
      returnUrl: 'spots://payment/onboarding/complete',
      refreshUrl: 'spots://payment/onboarding/refresh',
    );
    
    return StripeConnectAccount(
      accountId: account.id,
      onboardingUrl: onboardingUrl,
      onboardingComplete: false,
    );
  }
  
  /// Process event ticket purchase
  Future<PaymentResult> purchaseEventTicket({
    required String eventId,
    required String buyerId,
    required int quantity,
    required double ticketPrice,
  }) async {
    final event = await _getEvent(eventId);
    final partnership = event.partnership;
    
    final amount = (ticketPrice * quantity * 100).toInt(); // Convert to cents
    
    // Create payment intent
    final paymentIntent = await _stripe.createPaymentIntent(
      amount: amount,
      currency: 'usd',
      metadata: {
        'eventId': eventId,
        'buyerId': buyerId,
        'quantity': quantity.toString(),
        'partnershipId': partnership?.id ?? '',
      },
      // Application fee (SPOTS platform fee only - Stripe fee is automatic)
      applicationFeeAmount: (amount * 0.10).toInt(), // 10% platform fee
    );
    
    return PaymentResult(
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.clientSecret,
      amount: amount / 100,
      status: PaymentStatus.pending,
    );
  }
  
  /// Distribute event revenue to partners
  Future<void> distributeEventRevenue({
    required String eventId,
    required String paymentIntentId,
  }) async {
    final event = await _getEvent(eventId) as PartnershipEvent;
    final partnership = event.partnership;
    
    // Get payment details
    final payment = await _stripe.retrievePaymentIntent(paymentIntentId);
    if (payment.status != 'succeeded') {
      throw PaymentException('Payment not completed');
    }
    
    // Calculate splits
    final grossRevenue = payment.amount / 100;
    
    // Calculate fees
    final stripePercentageFee = grossRevenue * 0.029; // 2.9%
    final stripeFixedFee = event.revenue!.ticketsSold * 0.30; // $0.30 per ticket
    final paymentProcessorFee = stripePercentageFee + stripeFixedFee;
    final spotsPlatformFee = grossRevenue * 0.10; // 10%
    final totalFees = paymentProcessorFee + spotsPlatformFee;
    
    // Net revenue after all fees
    final netRevenue = grossRevenue - totalFees;
    
    final revenueSplit = partnership.revenueSplit!;
    final expertPayout = netRevenue * (revenueSplit.expertPercentage / 100);
    final businessPayout = netRevenue * (revenueSplit.businessPercentage / 100);
    
    // Transfer to expert's Connect account
    await _stripe.createTransfer(
      amount: (expertPayout * 100).toInt(),
      currency: 'usd',
      destination: await _getStripeAccountId(partnership.expertId),
      metadata: {
        'eventId': eventId,
        'partnershipId': partnership.id,
        'recipientType': 'expert',
      },
    );
    
    // Transfer to business's Connect account
    await _stripe.createTransfer(
      amount: (businessPayout * 100).toInt(),
      currency: 'usd',
      destination: await _getStripeAccountId(partnership.businessId),
      metadata: {
        'eventId': eventId,
        'partnershipId': partnership.id,
        'recipientType': 'business',
      },
    );
    
    // Record revenue distribution
    await _recordEventRevenue(
      eventId: eventId,
      revenue: EventRevenue(
        eventId: eventId,
        ticketPrice: event.price!,
        ticketsSold: event.attendeeCount,
        grossRevenue: grossRevenue,
        spotsPlatformFee: spotsPlatformFee,
        paymentProcessorFee: paymentProcessorFee,
        totalFees: totalFees,
        expertPayout: expertPayout,
        businessPayout: businessPayout,
        stripePaymentIntentId: paymentIntentId,
        paymentStatus: PaymentStatus.completed,
        expertPayoutDate: DateTime.now(),
        businessPayoutDate: DateTime.now(),
      ),
    );
  }
  
  /// Handle refunds
  Future<void> refundEventTicket({
    required String paymentIntentId,
    required String reason,
    bool partial = false,
    double? partialAmount,
  }) async {
    await _stripe.refundPayment(
      paymentIntentId: paymentIntentId,
      amount: partial ? (partialAmount! * 100).toInt() : null,
      reason: reason,
    );
    
    // Update event revenue record
    await _updatePaymentStatus(
      paymentIntentId,
      partial ? PaymentStatus.partialRefund : PaymentStatus.refunded,
    );
  }
}
```

**File: `lib/core/services/stripe_service.dart`**
- Wrapper for Stripe API
- Connect account management
- Payment intent creation
- Transfer handling
- Webhook processing

**Deliverables:**
- ✅ Stripe Connect integration
- ✅ Payment processing
- ✅ Automatic revenue splits
- ✅ Refund handling
- ✅ Platform fee collection

---

#### **2.2 Payout Management** (3 days)

**File: `lib/core/services/payout_service.dart`**

```dart
class PayoutService {
  /// Get earnings summary for user
  Future<EarningsSummary> getEarningsSummary(
    String userId,
    {DateTime? startDate, DateTime? endDate}
  ) async {
    final events = await _getUserEvents(userId, startDate, endDate);
    
    double totalEarnings = 0;
    double totalPlatformFees = 0;
    int totalEventCount = 0;
    int totalAttendeesServed = 0;
    
    for (final event in events) {
      if (event is PartnershipEvent && event.revenue != null) {
        final revenue = event.revenue!;
        
        // Determine user's share
        final isExpert = event.partnership.expertId == userId;
        final userEarnings = isExpert
          ? revenue.expertPayout
          : revenue.businessPayout;
        
        totalEarnings += userEarnings;
        totalPlatformFees += revenue.platformFee * 
          (isExpert 
            ? event.partnership.revenueSplit!.expertPercentage / 100
            : event.partnership.revenueSplit!.businessPercentage / 100);
        totalEventCount++;
        totalAttendeesServed += revenue.ticketsSold;
      }
    }
    
    return EarningsSummary(
      userId: userId,
      totalEarnings: totalEarnings,
      totalPlatformFees: totalPlatformFees,
      eventCount: totalEventCount,
      attendeesServed: totalAttendeesServed,
      period: DateTimeRange(
        start: startDate ?? events.first.createdAt,
        end: endDate ?? DateTime.now(),
      ),
    );
  }
  
  /// Get payout history
  Future<List<Payout>> getPayoutHistory(String userId) async {
    // Query Stripe for transfer history
    final transfers = await _stripe.listTransfers(
      destination: await _getStripeAccountId(userId),
    );
    
    return transfers.map((t) => Payout.fromStripeTransfer(t)).toList();
  }
  
  /// Get pending payouts
  Future<List<PendingPayout>> getPendingPayouts(String userId) async {
    final events = await _getUserCompletedEvents(userId);
    
    final pending = <PendingPayout>[];
    for (final event in events) {
      if (event is PartnershipEvent && event.revenue != null) {
        final revenue = event.revenue!;
        final isExpert = event.partnership.expertId == userId;
        
        final payoutDate = isExpert 
          ? revenue.expertPayoutDate 
          : revenue.businessPayoutDate;
        
        if (payoutDate == null || payoutDate.isAfter(DateTime.now())) {
          pending.add(PendingPayout(
            eventId: event.id,
            eventTitle: event.title,
            amount: isExpert 
              ? revenue.expertPayout 
              : revenue.businessPayout,
            estimatedPayoutDate: payoutDate ?? 
              event.endTime.add(Duration(days: 2)), // 2 days after event
          ));
        }
      }
    }
    
    return pending;
  }
}

class EarningsSummary {
  final String userId;
  final double totalEarnings;
  final double totalPlatformFees;
  final int eventCount;
  final int attendeesServed;
  final DateTimeRange period;
  
  double get averageEarningsPerEvent => 
    eventCount > 0 ? totalEarnings / eventCount : 0;
  
  double get averageEarningsPerAttendee => 
    attendeesServed > 0 ? totalEarnings / attendeesServed : 0;
}
```

**Deliverables:**
- ✅ Earnings summary calculation
- ✅ Payout history tracking
- ✅ Pending payouts display
- ✅ Financial analytics

---

#### **2.3 Payment UI Components** (3 days)

**File: `lib/presentation/widgets/payments/ticket_purchase_widget.dart`**
- Ticket quantity selector
- Price display with fee breakdown
- Stripe payment element
- Purchase confirmation

**File: `lib/presentation/widgets/payments/earnings_dashboard_widget.dart`**
- Total earnings display
- Earnings breakdown (by event, by partnership)
- Platform fees paid
- Interactive charts

**File: `lib/presentation/widgets/payments/payout_history_widget.dart`**
- List of past payouts
- Payout details (amount, date, event)
- Download statements

**File: `lib/presentation/pages/payments/stripe_onboarding_page.dart`**
- Stripe Connect onboarding flow
- Account verification status
- Required documents upload

**Deliverables:**
- ✅ Ticket purchase UI
- ✅ Earnings dashboard
- ✅ Payout history UI
- ✅ Stripe onboarding UI

---

### **PHASE 3: Partnership Event Creation** (Week 5, 5 days)

#### **3.1 Partnership Event Templates** (2 days)

**File: `lib/core/services/partnership_event_template_service.dart`**

Extend existing `EventTemplateService` with partnership-specific templates:

```dart
class PartnershipEventTemplate extends EventTemplate {
  final PartnershipType suggestedPartnershipType;
  final RevenueSplit suggestedRevenueSplit;
  final Map<String, String> partnerResponsibilities; // Role -> Responsibility
  final bool requiresBusinessVenue;
  final String businessRole;  // e.g., "Venue Provider", "Co-Host"
  final String expertRole;    // e.g., "Event Leader", "Content Expert"
}

// Example templates:
final templates = [
  PartnershipEventTemplate(
    name: 'Coffee Tasting Workshop',
    category: 'Coffee',
    eventType: ExpertiseEventType.workshop,
    suggestedPartnershipType: PartnershipType.coHost,
    suggestedRevenueSplit: RevenueSplit(
      spotsPlatformFeePercentage: 10,
      paymentProcessorFeePercentage: 2.9,
      fixedProcessorFee: 0.30,
      expertPercentage: 50,
      businessPercentage: 50,
    ),
    requiresBusinessVenue: true,
    businessRole: 'Venue Provider + Materials',
    expertRole: 'Workshop Leader',
    partnerResponsibilities: {
      'business': 'Provide space, coffee equipment, beans',
      'expert': 'Lead tasting, teach techniques, answer questions',
    },
  ),
  
  PartnershipEventTemplate(
    name: 'Bookstore Author Reading',
    category: 'Books',
    eventType: ExpertiseEventType.meetup,
    suggestedPartnershipType: PartnershipType.venueProvider,
    suggestedRevenueSplit: RevenueSplit(
      spotsPlatformFeePercentage: 10,
      paymentProcessorFeePercentage: 2.9,
      fixedProcessorFee: 0.30,
      expertPercentage: 70,
      businessPercentage: 30,
    ),
    requiresBusinessVenue: true,
    businessRole: 'Venue + Book Sales',
    expertRole: 'Event Host + Author Coordination',
    partnerResponsibilities: {
      'business': 'Provide venue, sell books, refreshments',
      'expert': 'Coordinate author, moderate Q&A, promote event',
    },
  ),
];
```

**Deliverables:**
- ✅ 15 partnership event templates
- ✅ Pre-configured revenue splits
- ✅ Responsibility breakdowns
- ✅ Template recommendations

---

#### **3.2 Co-Hosted Event Creation Flow** (3 days)

**File: `lib/core/services/partnership_event_service.dart`**

```dart
class PartnershipEventService extends ExpertiseEventService {
  /// Create event from partnership
  Future<PartnershipEvent> createPartnershipEvent({
    required EventPartnership partnership,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required List<Spot> spots,
    required int maxAttendees,
    double? price,
    EventTemplate? template,
  }) async {
    // 1. Verify partnership is active
    if (partnership.status != PartnershipStatus.active) {
      throw Exception('Partnership must be active');
    }
    
    // 2. Create partnership event
    final event = PartnershipEvent(
      id: _generateEventId(),
      title: title,
      description: description,
      category: template?.category ?? 'General',
      eventType: template?.eventType ?? ExpertiseEventType.meetup,
      host: partnership.expert,
      partnership: partnership,
      isCoHosted: true,
      primaryHostId: partnership.expertId,
      coHostIds: [partnership.businessId],
      startTime: startTime,
      endTime: endTime,
      spots: spots,
      maxAttendees: maxAttendees,
      price: price,
      isPaid: price != null && price > 0,
      isAtBusinessLocation: partnership.type == PartnershipType.venueProvider,
      businessVenueId: partnership.business.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: EventStatus.upcoming,
    );
    
    // 3. If paid event, set up revenue tracking
    if (event.isPaid) {
      await _setupRevenueTracking(event, partnership);
    }
    
    // 4. Save event
    await _saveEvent(event);
    
    // 5. Link event to partnership
    await _addEventToPartnership(partnership.id, event.id);
    
    // 6. Notify both partners
    await _notifyPartnershipEventCreated(event);
    
    return event;
  }
  
  /// Quick create from template
  Future<PartnershipEvent> createFromTemplate({
    required EventPartnership partnership,
    required PartnershipEventTemplate template,
    required DateTime startTime,
    Map<String, dynamic>? customizations,
  }) async {
    // Auto-fill from template
    return createPartnershipEvent(
      partnership: partnership,
      title: customizations?['title'] ?? template.name,
      description: customizations?['description'] ?? 
        template.descriptionTemplate,
      startTime: startTime,
      endTime: startTime.add(template.defaultDuration),
      spots: customizations?['spots'] ?? [],
      maxAttendees: customizations?['maxAttendees'] ?? 
        template.defaultMaxAttendees,
      price: customizations?['price'] ?? template.suggestedPrice,
      template: template,
    );
  }
}
```

**File: `lib/presentation/pages/events/partnership_event_creation_page.dart`**
- Partnership selection
- Template selection (partnership-specific)
- Quick builder with partnership context
- Revenue split preview
- Responsibility checklist for both parties

**Deliverables:**
- ✅ Partnership event creation service
- ✅ Template-based creation
- ✅ Event creation UI
- ✅ Revenue preview

---

### **PHASE 4: Financial Reporting & Analytics** (Week 6, 5 days)

#### **4.1 Financial Dashboard** (3 days)

**File: `lib/presentation/pages/financials/financial_dashboard_page.dart`**

Comprehensive financial dashboard showing:

**For Experts:**
- Total earnings (all-time, this month, this year)
- Earnings by partnership
- Earnings by event type
- Platform fees paid
- Pending payouts
- Top-earning events
- Revenue trends over time

**For Businesses:**
- Total earnings from events
- Earnings by partnership
- ROI on events (compared to venue rental value)
- Customer acquisition cost per event
- Repeat attendee rate
- Platform fees paid
- Pending payouts

**For SPOTS (Admin):**
- Total platform fees collected
- Revenue by category
- Active partnerships count
- Events by partnership type
- Average ticket price
- Total attendees served
- Partnership success rate

**Deliverables:**
- ✅ Multi-role financial dashboard
- ✅ Interactive charts and graphs
- ✅ Exportable reports
- ✅ Tax documentation download

---

#### **4.2 Analytics & Insights** (2 days)

**File: `lib/core/services/partnership_analytics_service.dart`**

```dart
class PartnershipAnalyticsService {
  /// Get partnership performance metrics
  Future<PartnershipPerformance> getPartnershipPerformance(
    String partnershipId,
  ) async {
    final partnership = await _getPartnership(partnershipId);
    final events = await _getPartnershipEvents(partnershipId);
    
    return PartnershipPerformance(
      partnershipId: partnershipId,
      totalEvents: events.length,
      totalRevenue: _calculateTotalRevenue(events),
      totalAttendees: _calculateTotalAttendees(events),
      averageTicketPrice: _calculateAverageTicketPrice(events),
      averageAttendance: _calculateAverageAttendance(events),
      eventSuccessRate: _calculateSuccessRate(events),
      partnershipDuration: DateTime.now().difference(partnership.createdAt),
      recommendContinuation: _shouldContinuePartnership(partnership, events),
    );
  }
  
  /// Get insights for improving partnerships
  Future<List<PartnershipInsight>> getPartnershipInsights(
    String userId,
  ) async {
    final insights = <PartnershipInsight>[];
    
    // Analyze user's partnerships
    final partnerships = await _getUserPartnerships(userId);
    
    for (final partnership in partnerships) {
      final performance = await getPartnershipPerformance(partnership.id);
      
      // Generate insights
      if (performance.averageAttendance < 50) {
        insights.add(PartnershipInsight(
          type: InsightType.lowAttendance,
          message: 'Consider increasing marketing efforts or adjusting event timing',
          partnership: partnership,
          actionable: true,
        ));
      }
      
      if (performance.totalEvents >= 5 && performance.eventSuccessRate > 0.8) {
        insights.add(PartnershipInsight(
          type: InsightType.successfulPartnership,
          message: 'This partnership is thriving! Consider creating recurring events',
          partnership: partnership,
          actionable: true,
        ));
      }
      
      // Revenue opportunity insights
      if (_hasRevenueOpportunity(performance)) {
        insights.add(PartnershipInsight(
          type: InsightType.revenueOpportunity,
          message: 'Events are consistently full - consider raising ticket prices',
          partnership: partnership,
          actionable: true,
        ));
      }
    }
    
    return insights;
  }
}

class PartnershipPerformance {
  final String partnershipId;
  final int totalEvents;
  final double totalRevenue;
  final int totalAttendees;
  final double averageTicketPrice;
  final double averageAttendance; // Percentage of capacity filled
  final double eventSuccessRate; // Percentage of events that met goals
  final Duration partnershipDuration;
  final bool recommendContinuation;
}
```

**Deliverables:**
- ✅ Partnership performance metrics
- ✅ Actionable insights generation
- ✅ Success rate calculation
- ✅ Optimization recommendations

---

### **PHASE 5: Admin Tools & Platform Management** (Week 7, 5 days)

#### **5.1 Admin Partnership Management** (3 days)

**File: `lib/presentation/pages/admin/partnership_admin_dashboard.dart`**

Admin dashboard for monitoring the partnership ecosystem:

**Partnership Oversight:**
- All active partnerships
- Partnership success rates
- Dispute resolution queue
- Partnership approval (if required)
- Partnership statistics

**Revenue Monitoring:**
- Platform fees collected (real-time)
- Revenue by category
- Revenue by partnership type
- Revenue trends over time
- Top-earning partnerships

**Quality Assurance:**
- Event quality scores
- Partnership compatibility scores
- User feedback on partnered events
- Fraud detection alerts
- Refund rate monitoring

**Deliverables:**
- ✅ Admin partnership dashboard
- ✅ Revenue monitoring
- ✅ Quality metrics
- ✅ Dispute resolution tools

---

#### **5.2 Platform Fee Configuration** (1 day)

**File: `lib/core/services/platform_config_service.dart`**

```dart
class PlatformConfigService {
  /// Get current platform fee configuration
  Future<PlatformFeeConfig> getPlatformFeeConfig() async {
    return PlatformFeeConfig(
      defaultFeePercentage: 10.0, // SPOTS platform fee (excludes payment processing)
      minimumFee: 1.0, // Minimum $1 SPOTS fee even for low-priced events
      categoryMultipliers: {
        'Coffee': 1.0,      // Standard 10%
        'Food': 1.0,
        'Books': 0.85,      // Lower fee (8.5%) to encourage literary events
        'Art': 1.0,
        'Music': 1.1,       // Slightly higher (11%) for premium events
      },
      partnershipTypeMultipliers: {
        PartnershipType.coHost: 1.0,
        PartnershipType.venueProvider: 0.9,  // Lower fee when business provides venue
        PartnershipType.sponsorship: 1.0,
        PartnershipType.collaboration: 1.0,
      },
      loyaltyDiscounts: {
        '5_events': 0.95,   // 5% discount after 5 successful events
        '10_events': 0.90,  // 10% discount after 10 successful events
        '25_events': 0.85,  // 15% discount after 25 successful events
      },
    );
  }
  
  /// Calculate actual platform fee for event
  Future<double> calculatePlatformFee({
    required String category,
    required PartnershipType? partnershipType,
    required double ticketPrice,
    required String hostId,
  }) async {
    final config = await getPlatformFeeConfig();
    double feePercentage = config.defaultFeePercentage;
    
    // Apply category multiplier
    if (config.categoryMultipliers.containsKey(category)) {
      feePercentage *= config.categoryMultipliers[category]!;
    }
    
    // Apply partnership type multiplier
    if (partnershipType != null && 
        config.partnershipTypeMultipliers.containsKey(partnershipType)) {
      feePercentage *= config.partnershipTypeMultipliers[partnershipType]!;
    }
    
    // Apply loyalty discount
    final eventCount = await _getHostEventCount(hostId);
    if (eventCount >= 25) {
      feePercentage *= config.loyaltyDiscounts['25_events']!;
    } else if (eventCount >= 10) {
      feePercentage *= config.loyaltyDiscounts['10_events']!;
    } else if (eventCount >= 5) {
      feePercentage *= config.loyaltyDiscounts['5_events']!;
    }
    
    final calculatedFee = ticketPrice * (feePercentage / 100);
    
    // Ensure minimum fee
    return max(calculatedFee, config.minimumFee);
  }
}
```

**Deliverables:**
- ✅ Configurable platform fees
- ✅ Category-specific fees
- ✅ Loyalty discounts
- ✅ Partnership type multipliers

---

#### **5.3 Dispute Resolution System** (1 day)

**File: `lib/core/models/partnership_dispute.dart`**

```dart
enum DisputeType {
  revenueDisagreement,
  responsibilityBreach,
  qualityIssue,
  cancellation,
  refundRequest,
  other,
}

class PartnershipDispute {
  final String id;
  final String partnershipId;
  final String eventId;
  final String reporterId;
  final String reportedId;
  final DisputeType type;
  final String description;
  final List<String> evidence; // URLs to screenshots, etc.
  final DisputeStatus status;
  final String? adminNotes;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}
```

**File: `lib/core/services/dispute_resolution_service.dart`**
- Submit dispute
- Admin review queue
- Evidence collection
- Resolution tracking
- Automated mediation suggestions

**Deliverables:**
- ✅ Dispute submission system
- ✅ Admin resolution tools
- ✅ Evidence tracking
- ✅ Resolution documentation

---

## 📊 Success Metrics

### **Partnership Success:**
- 20%+ of events are co-hosted partnerships within 6 months
- 80%+ partnership satisfaction rating
- 60%+ of partnerships result in multiple events
- Average 3+ events per partnership

### **Monetization Success:**
- $10K+ monthly platform fee revenue (SPOTS portion) within 12 months
- 10% average platform fee (after discounts and multipliers)
- ~13% total customer cost (10% SPOTS + ~3% payment processing)
- <5% refund rate
- 95%+ successful payment processing rate

### **User Success:**
- Experts earn average $300+/event
- Businesses see 3x ROI on venue provision
- 85%+ of participants rate events 4+ stars
- 40%+ repeat attendance rate

---

## 🔒 Security & Compliance

### **Payment Security:**
- PCI DSS compliant (handled by Stripe)
- Secure token handling
- No storing of payment credentials
- End-to-end encryption

### **Financial Compliance:**
- 1099 tax form generation for earners >$600/year
- Transaction logging for audits
- GDPR/CCPA compliant financial data handling
- Refund policy enforcement

### **Fraud Prevention:**
- Stripe Radar for fraud detection
- Manual review for high-value transactions
- Partnership verification requirements
- Dispute resolution process

---

## 🎯 Timeline Summary

| Phase | Duration | Effort | Dependencies |
|-------|----------|--------|--------------|
| **Phase 1: Partnership Foundation** | 2 weeks | 10 days | Easy Event Hosting (Phase 4) |
| **Phase 2: Payment Processing** | 2 weeks | 10 days | Phase 1 |
| **Phase 3: Partnership Event Creation** | 1 week | 5 days | Phase 1, Easy Event Hosting |
| **Phase 4: Financial Reporting** | 1 week | 5 days | Phase 2 |
| **Phase 5: Admin Tools** | 1 week | 5 days | Phases 1-4 |
| **Testing & QA** | 1 week | 5 days | All phases |
| **Documentation** | 3 days | 3 days | All phases |
| **TOTAL** | **7-8 weeks** | **43 days** | |

---

## 💡 Philosophy Alignment: "Business With Integrity"

### **How This Honors OUR_GUTS.md:**

✅ **"No Pay-to-Play" Maintained**
- Platform fee is for transaction services, NOT for discovery visibility
- Events are discovered based on user preferences, not who pays more
- Revenue model is transparent service fee, not hidden agenda

✅ **"Authenticity Over Algorithms"**
- Partnerships formed on real compatibility, not artificial boosting
- Success measured by authentic user satisfaction
- No inflating metrics for higher fees

✅ **"Privacy and Control Are Non-Negotiable"**
- Financial data encrypted and protected
- Users control their payment methods and payout preferences
- Full transparency on fees and revenue splits

✅ **"Business With Integrity"**
- Transparent fee structure (10% + processor pass-through)
- Users see exactly where money goes
- Loyalty discounts reward consistent quality
- Clear terms, no hidden fees
- Dispute resolution protects all parties

✅ **"Community, Not Just Places"**
- Partnerships enable community-building events
- Revenue sharing supports sustainable community spaces
- Businesses and experts grow together

---

## 🚀 Getting Started

### **Prerequisites:**
1. Easy Event Hosting system complete (Phase 4)
2. Business verification system active
3. Expertise pin system functional
4. Stripe business account created

### **Phase 1 Kickoff Checklist:**
- [ ] Review Easy Event Hosting implementation
- [ ] Set up Stripe Connect test environment
- [ ] Design partnership data schema
- [ ] Create database migrations
- [ ] Begin partnership matching service

---

## 📝 Open Questions & Decisions Needed

1. **Platform Fee Rate:**
   - ✅ CONFIRMED: 10% SPOTS platform fee + payment processor pass-through (~3%)
   - Total: ~13% combined
   - More transparent than bundled 15%
   - Industry competitive

2. **Payout Timing:**
   - Proposed: 2 business days after event completion
   - Stripe standard: 2-7 days
   - Need to set user expectations

3. **Minimum Event Price:**
   - Should there be a minimum ticket price for paid events?
   - Suggested: $5 minimum to ensure meaningful revenue

4. **Partnership Approval:**
   - Should all partnerships be admin-approved?
   - Or only auto-approve for verified parties?
   - Suggested: Auto-approve for verified, flag unusual terms

5. **Refund Policy:**
   - Full refund if >24 hours before event?
   - Partial refund if <24 hours?
   - No refund if event already started?

6. **Revenue Split Limits:**
   - Should there be limits on split percentages?
   - Suggested: Each partner must get at least 20%
   - Prevents exploitation

---

## 🎉 Expected Outcomes

### **For Users (Experts):**
- New monetization opportunities through events
- Access to quality venue partnerships
- Sustainable income from expertise
- Community leadership recognition

### **For Businesses:**
- Increased foot traffic from events
- Expert credibility for their venue
- Revenue sharing without full hosting burden
- Community building at their location

### **For SPOTS Platform:**
- Sustainable revenue model
- Deeper user engagement
- Competitive differentiation
- Network effects from partnerships

### **For Community:**
- More diverse events available
- Higher quality events (vetted partnerships)
- Accessible events (experts + venues)
- Thriving local communities

---

**This is how SPOTS opens doors—not just to experiences, but to sustainable community building and authentic partnerships that benefit everyone.** 🚪✨💰

---

**Plan Status:** ✅ Ready for Review & Approval  
**Next Step:** Review with stakeholders, confirm platform fee rate, proceed to Phase 1 implementation  
**Last Updated:** November 21, 2025

