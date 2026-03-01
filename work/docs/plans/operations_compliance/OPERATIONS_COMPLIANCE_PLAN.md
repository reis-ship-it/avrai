# Operations & Compliance - P0 Critical Gaps Implementation

**Created:** November 21, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** CRITICAL (P0)  
**Timeline:** 4 weeks  
**Purpose:** Complete the operational and compliance layer for MVP launch

---

## 🎯 Overview

**What This Plan Addresses:**

This 4-week plan fills the critical gaps identified in the gap analysis:
1. ✅ Post-Event System (Week 2)
2. ✅ Refund & Cancellation Policy (Week 1)
3. ✅ Tax & Legal Compliance (Week 3)
4. ✅ Fraud Prevention & Security (Week 4)

**Goal:** Transform the system from 75% → 95% complete, ready for MVP launch.

---

## 📅 Week 1: Refund Policy & Safety Guidelines

### **Day 1-2: Refund & Cancellation Policy**

#### **Data Models:**

```dart
enum CancellationInitiator {
  attendee,           // Attendee cancels their ticket
  host,               // Host cancels entire event
  venue,              // Venue unavailable
  weather,            // Emergency weather
  platform,           // SPOTS technical issue
}

enum RefundStatus {
  pending,            // Refund initiated
  processing,         // Being processed
  completed,          // Refund sent
  failed,             // Refund failed
  disputed,           // User disputes refund amount
}

class RefundPolicy {
  /// Time-based refund windows for attendee cancellations
  static double getRefundPercentage(Duration timeUntilEvent) {
    if (timeUntilEvent >= Duration(days: 7)) {
      return 1.0;  // 100% refund (7+ days before)
    } else if (timeUntilEvent >= Duration(days: 3)) {
      return 0.75; // 75% refund (3-7 days before)
    } else if (timeUntilEvent >= Duration(days: 1)) {
      return 0.50; // 50% refund (1-3 days before)
    } else {
      return 0.0;  // No refund (day of event)
    }
  }
  
  /// Platform fee handling on refunds
  static bool platformFeeRefunded(CancellationInitiator initiator) {
    return initiator == CancellationInitiator.host ||
           initiator == CancellationInitiator.venue ||
           initiator == CancellationInitiator.weather ||
           initiator == CancellationInitiator.platform;
  }
  
  /// Full refund guarantees (force majeure)
  static bool guaranteesFullRefund(CancellationInitiator initiator) {
    return initiator != CancellationInitiator.attendee;
  }
}

class Cancellation {
  final String id;
  final String eventId;
  final CancellationInitiator initiator;
  final String initiatorUserId;
  final String reason;
  final DateTime cancelledAt;
  final DateTime eventStartTime;
  
  // Financial impact
  final double originalAmount;
  final double refundAmount;
  final double platformFeeRefund;
  final bool hostPenalty;
  final double? penaltyAmount;
  
  // Processing
  final RefundStatus status;
  final DateTime? processedAt;
  final List<RefundDistribution> distributions;
}

class RefundDistribution {
  final String userId;           // Who gets refund
  final String role;             // attendee, host, venue, sponsor
  final double amount;           // Amount to refund
  final String? stripeRefundId;
  final DateTime? completedAt;
}
```

#### **Cancellation Service:**

```dart
class CancellationService {
  /// Attendee cancels their ticket
  Future<Cancellation> attendeeCancelTicket(
    String eventId,
    String attendeeId,
  ) async {
    final event = await _getEvent(eventId);
    final ticket = await _getTicket(attendeeId, eventId);
    final timeUntilEvent = event.startTime.difference(DateTime.now());
    
    // Calculate refund based on time
    final refundPercentage = RefundPolicy.getRefundPercentage(timeUntilEvent);
    final refundAmount = ticket.price * refundPercentage;
    
    // Platform fee NOT refunded for attendee cancellations
    final platformFeeRefund = 0.0;
    
    // Create cancellation record
    final cancellation = Cancellation(
      id: _generateId(),
      eventId: eventId,
      initiator: CancellationInitiator.attendee,
      initiatorUserId: attendeeId,
      reason: 'Attendee cancelled',
      cancelledAt: DateTime.now(),
      eventStartTime: event.startTime,
      originalAmount: ticket.price,
      refundAmount: refundAmount,
      platformFeeRefund: platformFeeRefund,
      hostPenalty: false,
      status: RefundStatus.pending,
      distributions: [
        RefundDistribution(
          userId: attendeeId,
          role: 'attendee',
          amount: refundAmount,
        ),
      ],
    );
    
    // Process refund through Stripe
    await _processRefund(cancellation);
    
    // Notify host (spot reopened)
    await _notifyHostOfCancellation(event.hostId, eventId);
    
    return cancellation;
  }
  
  /// Host cancels entire event
  Future<Cancellation> hostCancelEvent(
    String eventId,
    String hostId,
    String reason,
  ) async {
    final event = await _getEvent(eventId);
    final tickets = await _getAllTickets(eventId);
    final timeUntilEvent = event.startTime.difference(DateTime.now());
    
    // Full refund for all attendees
    final totalRefunds = tickets.fold(0.0, (sum, t) => sum + t.price);
    
    // Platform fee refunded
    final platformFeeRefund = totalRefunds * 0.10;
    
    // Host penalty if cancellation is last-minute (<48 hours)
    final hostPenalty = timeUntilEvent < Duration(hours: 48);
    final penaltyAmount = hostPenalty ? totalRefunds * 0.10 : 0.0;
    
    // Create cancellation
    final cancellation = Cancellation(
      id: _generateId(),
      eventId: eventId,
      initiator: CancellationInitiator.host,
      initiatorUserId: hostId,
      reason: reason,
      cancelledAt: DateTime.now(),
      eventStartTime: event.startTime,
      originalAmount: totalRefunds,
      refundAmount: totalRefunds,
      platformFeeRefund: platformFeeRefund,
      hostPenalty: hostPenalty,
      penaltyAmount: penaltyAmount,
      status: RefundStatus.pending,
      distributions: tickets.map((t) => RefundDistribution(
        userId: t.attendeeId,
        role: 'attendee',
        amount: t.price,
      )).toList(),
    );
    
    // Process all refunds
    await _processBatchRefunds(cancellation);
    
    // Notify all attendees
    await _notifyAttendeesOfCancellation(tickets, reason);
    
    // If penalty, deduct from host's next payout
    if (hostPenalty) {
      await _applyHostPenalty(hostId, penaltyAmount);
    }
    
    return cancellation;
  }
  
  /// Weather/emergency cancellation
  Future<Cancellation> emergencyCancelEvent(
    String eventId,
    String reason,
    {required bool weatherRelated}
  ) async {
    // Full refunds, no penalties
    // Similar to host cancel but no penalty
  }
}
```

#### **Refund UI Components:**

**File:** `lib/presentation/pages/events/cancellation_flow_page.dart`

```dart
class CancellationFlowPage extends StatefulWidget {
  final Event event;
  final bool isHost;
}

// Shows:
// - Cancellation reason selection
// - Refund amount preview
// - Policy explanation
// - Confirmation step
// - Processing status
```

---

### **Day 3-4: Safety Guidelines**

#### **Safety Data Models:**

```dart
class EventSafetyGuidelines {
  final String eventId;
  final EventType type;
  
  // Required safety measures
  final List<SafetyRequirement> requirements;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  
  // Emergency info
  final EmergencyInformation emergencyInfo;
  
  // Insurance
  final InsuranceRecommendation insurance;
}

enum SafetyRequirement {
  capacityLimit,          // Don't exceed venue capacity
  emergencyExits,         // Know where exits are
  firstAidKit,            // Have kit available
  emergencyContacts,      // List of contacts
  weatherPlan,            // If outdoor event
  alcoholPolicy,          // If serving alcohol
  minorPolicy,            // If children attending
  foodSafety,             // If serving food
  accessibilityPlan,      // Accessibility considerations
  covidProtocol,          // Current health protocols
}

class EmergencyInformation {
  final String eventId;
  final List<EmergencyContact> contacts;
  final String nearestHospital;
  final String nearestHospitalAddress;
  final String nearestHospitalPhone;
  final String evacuationPlan;
  final String meetingPoint;
}

class EmergencyContact {
  final String name;
  final String phone;
  final String role;  // "Host", "Venue Manager", "Security"
}

class InsuranceRecommendation {
  final EventType eventType;
  final int attendeeCount;
  final bool recommended;
  final bool required;
  final String explanation;
  final double suggestedCoverageAmount;
  final List<String> insuranceProviders;
}
```

#### **Safety Service:**

```dart
class EventSafetyService {
  /// Generate safety guidelines for event type
  Future<EventSafetyGuidelines> generateGuidelines(
    String eventId,
  ) async {
    final event = await _getEvent(eventId);
    
    // Determine requirements based on event type
    final requirements = _getRequirementsForType(event.type, event);
    
    // Emergency information
    final emergencyInfo = await _getEmergencyInfo(event.location);
    
    // Insurance recommendation
    final insurance = _getInsuranceRecommendation(event);
    
    return EventSafetyGuidelines(
      eventId: eventId,
      type: event.type,
      requirements: requirements,
      acknowledged: false,
      emergencyInfo: emergencyInfo,
      insurance: insurance,
    );
  }
  
  /// Determine safety requirements
  List<SafetyRequirement> _getRequirementsForType(
    EventType type,
    Event event,
  ) {
    final requirements = <SafetyRequirement>[
      SafetyRequirement.capacityLimit,      // Always required
      SafetyRequirement.emergencyExits,     // Always required
      SafetyRequirement.emergencyContacts,  // Always required
    ];
    
    // Event-specific requirements
    if (event.isOutdoor) {
      requirements.add(SafetyRequirement.weatherPlan);
    }
    
    if (event.servesAlcohol) {
      requirements.add(SafetyRequirement.alcoholPolicy);
    }
    
    if (event.allowsMinors) {
      requirements.add(SafetyRequirement.minorPolicy);
    }
    
    if (event.servesFood) {
      requirements.add(SafetyRequirement.foodSafety);
      requirements.add(SafetyRequirement.firstAidKit);
    }
    
    if (event.maxAttendees > 50) {
      requirements.add(SafetyRequirement.accessibilityPlan);
    }
    
    requirements.add(SafetyRequirement.covidProtocol);
    
    return requirements;
  }
  
  /// Insurance recommendation logic
  InsuranceRecommendation _getInsuranceRecommendation(Event event) {
    bool required = false;
    bool recommended = false;
    double coverage = 1000000; // $1M default
    
    // High-risk events require insurance
    if (event.type == EventType.physicalActivity ||
        event.type == EventType.adventure ||
        event.maxAttendees > 100) {
      required = true;
      coverage = 2000000; // $2M
    }
    
    // Medium-risk events recommend insurance
    if (event.servesAlcohol || event.servesFood || event.maxAttendees > 25) {
      recommended = true;
    }
    
    return InsuranceRecommendation(
      eventType: event.type,
      attendeeCount: event.maxAttendees,
      recommended: recommended,
      required: required,
      explanation: _getInsuranceExplanation(event),
      suggestedCoverageAmount: coverage,
      insuranceProviders: ['EventInsure', 'Cover Genius', 'Allianz Events'],
    );
  }
}
```

#### **Safety Checklist UI:**

**File:** `lib/presentation/widgets/events/safety_checklist_widget.dart`

```dart
class SafetyChecklistWidget extends StatefulWidget {
  final EventSafetyGuidelines guidelines;
  
  // Shows:
  // - Checklist of requirements
  // - Emergency contact form
  // - Insurance recommendation
  // - Acknowledgment checkbox
  // - Educational tooltips
}
```

---

### **Day 5: Dispute Escalation Process**

#### **Dispute Models:**

```dart
enum DisputeType {
  refundDisagreement,     // Disagree on refund amount
  eventQuality,           // Event wasn't as described
  noShow,                 // Host/venue no-showed
  paymentIssue,           // Payment not received
  partnershipBreach,      // Partner didn't fulfill obligations
  safetyConcern,          // Safety issue at event
  other,
}

enum DisputeStatus {
  submitted,              // User submitted dispute
  reviewing,              // Admin reviewing
  investigationg,         // Gathering info from both parties
  mediation,              // Attempting resolution
  resolved,               // Resolved
  escalated,              // Escalated to legal/management
  closed,                 // Closed without resolution
}

class Dispute {
  final String id;
  final String eventId;
  final String reporterId;
  final String reportedId;
  final DisputeType type;
  final String description;
  final List<String> evidenceUrls;  // Photos, screenshots, etc.
  final DateTime createdAt;
  
  // Status tracking
  final DisputeStatus status;
  final String? assignedAdminId;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  
  // Resolution
  final String? resolution;
  final String? adminNotes;
  final double? refundAmount;
  final Map<String, dynamic>? resolutionDetails;
  
  // Communication
  final List<DisputeMessage> messages;
}

class DisputeMessage {
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isAdminMessage;
  final List<String>? attachments;
}
```

#### **Dispute Service:**

```dart
class DisputeResolutionService {
  /// Submit a dispute
  Future<Dispute> submitDispute({
    required String eventId,
    required String reporterId,
    required String reportedId,
    required DisputeType type,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    final dispute = Dispute(
      id: _generateId(),
      eventId: eventId,
      reporterId: reporterId,
      reportedId: reportedId,
      type: type,
      description: description,
      evidenceUrls: evidenceUrls ?? [],
      createdAt: DateTime.now(),
      status: DisputeStatus.submitted,
      messages: [],
    );
    
    // Save dispute
    await _saveDispute(dispute);
    
    // Auto-assign to admin based on type
    await _autoAssignDispute(dispute);
    
    // Notify both parties
    await _notifyDisputeSubmitted(dispute);
    
    return dispute;
  }
  
  /// Admin reviews dispute
  Future<void> reviewDispute(
    String disputeId,
    String adminId,
  ) async {
    final dispute = await _getDispute(disputeId);
    
    // Update status
    await _updateDisputeStatus(
      disputeId,
      DisputeStatus.reviewing,
      assignedAdminId: adminId,
    );
    
    // Request information from both parties
    await _requestDisputeInformation(dispute);
  }
  
  /// Attempt automated resolution
  Future<Dispute?> attemptAutomatedResolution(
    String disputeId,
  ) async {
    final dispute = await _getDispute(disputeId);
    
    // Simple cases can be auto-resolved
    if (dispute.type == DisputeType.refundDisagreement) {
      final event = await _getEvent(dispute.eventId);
      final cancelPolicy = RefundPolicy.getRefundPercentage(
        event.startTime.difference(DateTime.now()),
      );
      
      // If dispute aligns with policy, auto-resolve
      return await _autoResolveRefund(dispute, cancelPolicy);
    }
    
    return null; // Needs manual review
  }
  
  /// Manual resolution by admin
  Future<Dispute> resolveDispute({
    required String disputeId,
    required String adminId,
    required String resolution,
    double? refundAmount,
    Map<String, dynamic>? resolutionDetails,
  }) async {
    final dispute = await _getDispute(disputeId);
    
    // Update dispute
    final resolved = dispute.copyWith(
      status: DisputeStatus.resolved,
      resolution: resolution,
      adminNotes: 'Resolved by $adminId',
      refundAmount: refundAmount,
      resolutionDetails: resolutionDetails,
      resolvedAt: DateTime.now(),
    );
    
    await _updateDispute(resolved);
    
    // Execute resolution (refund if needed)
    if (refundAmount != null) {
      await _executeRefund(dispute.reporterId, refundAmount);
    }
    
    // Notify both parties
    await _notifyDisputeResolved(resolved);
    
    return resolved;
  }
}
```

#### **Dispute UI:**

**File:** `lib/presentation/pages/disputes/dispute_submission_page.dart`

```dart
class DisputeSubmissionPage extends StatefulWidget {
  final Event event;
  
  // Shows:
  // - Dispute type selection
  // - Description field
  // - Evidence upload (photos, screenshots)
  // - Timeline of what happened
  // - Submit button
}
```

**File:** `lib/presentation/pages/admin/dispute_review_page.dart`

```dart
class DisputeReviewPage extends StatefulWidget {
  final Dispute dispute;
  
  // Admin view shows:
  // - Dispute details
  // - Both parties' perspectives
  // - Evidence
  // - Message thread
  // - Resolution actions
  // - Refund controls
}
```

---

## 📅 Week 2: Post-Event System

### **Day 1-2: Feedback Collection**

#### **Feedback Models:**

```dart
class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final String userRole;  // attendee, host, partner
  
  // Overall rating
  final double overallRating;  // 1-5 stars
  
  // Detailed ratings
  final Map<String, double> categoryRatings;
  // Examples:
  // - "organization": 4.5
  // - "content_quality": 5.0
  // - "venue": 4.0
  // - "value_for_money": 4.5
  
  // Free text
  final String? comments;
  final List<String>? highlights;  // What was great
  final List<String>? improvements; // What could be better
  
  // Additional info
  final DateTime submittedAt;
  final bool wouldAttendAgain;
  final bool wouldRecommend;
}

class PartnerRating {
  final String id;
  final String eventId;
  final String raterId;        // Who is rating
  final String ratedId;         // Who is being rated
  final String partnershipRole; // "host", "venue", "sponsor"
  
  // Ratings
  final double overallRating;
  final double professionalism;
  final double communication;
  final double reliability;
  final double wouldPartnerAgain; // 1-5 scale
  
  // Comments
  final String? positives;
  final String? improvements;
  final DateTime submittedAt;
}
```

#### **Feedback Service:**

```dart
class PostEventFeedbackService {
  /// Automatically trigger feedback collection after event
  Future<void> scheduleFeedbackCollection(String eventId) async {
    final event = await _getEvent(eventId);
    
    // Schedule for 2 hours after event ends
    final feedbackTime = event.endTime.add(Duration(hours: 2));
    
    await _scheduleNotification(
      eventId: eventId,
      scheduledFor: feedbackTime,
      type: NotificationType.feedbackRequest,
    );
  }
  
  /// Send feedback requests
  Future<void> sendFeedbackRequests(String eventId) async {
    final event = await _getEvent(eventId);
    final attendees = await _getAttendees(eventId);
    final partners = await _getEventPartners(eventId);
    
    // Request attendee feedback
    for (final attendee in attendees) {
      await _sendFeedbackRequest(
        userId: attendee.id,
        eventId: eventId,
        type: FeedbackType.attendee,
      );
    }
    
    // Request partner mutual ratings
    for (final partner in partners) {
      await _sendPartnerRatingRequest(
        partnerId: partner.id,
        eventId: eventId,
        otherPartners: partners.where((p) => p.id != partner.id).toList(),
      );
    }
  }
  
  /// Submit attendee feedback
  Future<EventFeedback> submitFeedback({
    required String eventId,
    required String userId,
    required double overallRating,
    required Map<String, double> categoryRatings,
    String? comments,
    List<String>? highlights,
    List<String>? improvements,
    required bool wouldAttendAgain,
    required bool wouldRecommend,
  }) async {
    final feedback = EventFeedback(
      id: _generateId(),
      eventId: eventId,
      userId: userId,
      userRole: 'attendee',
      overallRating: overallRating,
      categoryRatings: categoryRatings,
      comments: comments,
      highlights: highlights,
      improvements: improvements,
      submittedAt: DateTime.now(),
      wouldAttendAgain: wouldAttendAgain,
      wouldRecommend: wouldRecommend,
    );
    
    await _saveFeedback(feedback);
    
    // Update event aggregate ratings
    await _updateEventRatings(eventId);
    
    // Update host/partner ratings
    await _updateHostRating(eventId);
    
    return feedback;
  }
  
  /// Submit partner rating
  Future<PartnerRating> submitPartnerRating({
    required String eventId,
    required String raterId,
    required String ratedId,
    required String partnershipRole,
    required double overallRating,
    required double professionalism,
    required double communication,
    required double reliability,
    required double wouldPartnerAgain,
    String? positives,
    String? improvements,
  }) async {
    final rating = PartnerRating(
      id: _generateId(),
      eventId: eventId,
      raterId: raterId,
      ratedId: ratedId,
      partnershipRole: partnershipRole,
      overallRating: overallRating,
      professionalism: professionalism,
      communication: communication,
      reliability: reliability,
      wouldPartnerAgain: wouldPartnerAgain,
      positives: positives,
      improvements: improvements,
      submittedAt: DateTime.now(),
    );
    
    await _savePartnerRating(rating);
    
    // Update partner's overall rating
    await _updatePartnerReputation(ratedId);
    
    // Feed into vibe matching algorithm
    await _updateVibeCompatibility(raterId, ratedId, rating);
    
    return rating;
  }
}
```

#### **Feedback UI:**

**File:** `lib/presentation/pages/feedback/event_feedback_page.dart`

```dart
class EventFeedbackPage extends StatefulWidget {
  final Event event;
  
  // Shows:
  // - Overall star rating
  // - Category ratings (sliders)
  // - Highlight selection (chips)
  // - Improvement suggestions
  // - Would attend again? (toggle)
  // - Would recommend? (toggle)
  // - Optional comments
  // - Submit button
}
```

**File:** `lib/presentation/pages/feedback/partner_rating_page.dart`

```dart
class PartnerRatingPage extends StatefulWidget {
  final Event event;
  final List<Partner> partners;
  
  // Shows:
  // - Rate each partner individually
  // - Professionalism, communication, reliability
  // - Would partner again?
  // - Positive feedback
  // - Improvement suggestions
}
```

---

### **Day 3-4: Success Analysis**

#### **Success Metrics:**

```dart
class EventSuccessMetrics {
  final String eventId;
  
  // Attendance
  final int ticketsSold;
  final int actualAttendance;
  final double attendanceRate;  // actual / sold
  
  // Financial
  final double grossRevenue;
  final double netRevenue;
  final double revenueVsProjected;
  final double profitMargin;
  
  // Quality
  final double averageRating;
  final double nps;  // Net Promoter Score
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  
  // Engagement
  final double feedbackResponseRate;
  final int attendeesWhoWouldReturn;
  final int attendeesWhoWouldRecommend;
  
  // Partnership
  final Map<String, double> partnerSatisfaction;
  final bool partnersWouldCollaborateAgain;
  
  // Calculated
  final EventSuccessLevel successLevel;
  final List<String> successFactors;
  final List<String> improvementAreas;
}

enum EventSuccessLevel {
  exceptional,   // 4.8+ rating, 95%+ attendance, high NPS
  successful,    // 4.0+ rating, 80%+ attendance
  moderate,      // 3.5+ rating, 60%+ attendance
  belowExpectations, // <3.5 rating or <60% attendance
  failure,       // <3.0 rating or <40% attendance
}
```

#### **Success Analysis Service:**

```dart
class EventSuccessAnalysisService {
  /// Analyze event success after feedback collected
  Future<EventSuccessMetrics> analyzeEventSuccess(
    String eventId,
  ) async {
    final event = await _getEvent(eventId);
    final feedback = await _getAllFeedback(eventId);
    final partnerRatings = await _getPartnerRatings(eventId);
    
    // Calculate metrics
    final metrics = EventSuccessMetrics(
      eventId: eventId,
      ticketsSold: event.ticketsSold,
      actualAttendance: await _getActualAttendance(eventId),
      attendanceRate: _calculateAttendanceRate(event),
      grossRevenue: event.revenue?.grossRevenue ?? 0,
      netRevenue: event.revenue?.netRevenue ?? 0,
      revenueVsProjected: _compareToProjected(event),
      profitMargin: _calculateProfitMargin(event),
      averageRating: _calculateAverageRating(feedback),
      nps: _calculateNPS(feedback),
      fiveStarCount: feedback.where((f) => f.overallRating >= 4.5).length,
      feedbackResponseRate: feedback.length / event.ticketsSold,
      attendeesWhoWouldReturn: feedback.where((f) => f.wouldAttendAgain).length,
      attendeesWhoWouldRecommend: feedback.where((f) => f.wouldRecommend).length,
      partnerSatisfaction: _aggregatePartnerSatisfaction(partnerRatings),
      partnersWouldCollaborateAgain: _checkPartnerInterest(partnerRatings),
      successLevel: _determineSuccessLevel(feedback, event),
      successFactors: _identifySuccessFactors(feedback, event),
      improvementAreas: _identifyImprovementAreas(feedback, event),
    );
    
    await _saveSuccessMetrics(metrics);
    
    // Update expertise/reputation based on success
    await _updateHostReputation(event.hostId, metrics);
    
    // Feed into recommendation algorithm
    await _updateRecommendationModel(event, metrics);
    
    return metrics;
  }
  
  /// Determine success level
  EventSuccessLevel _determineSuccessLevel(
    List<EventFeedback> feedback,
    Event event,
  ) {
    final avgRating = _calculateAverageRating(feedback);
    final attendanceRate = _calculateAttendanceRate(event);
    
    if (avgRating >= 4.8 && attendanceRate >= 0.95) {
      return EventSuccessLevel.exceptional;
    } else if (avgRating >= 4.0 && attendanceRate >= 0.80) {
      return EventSuccessLevel.successful;
    } else if (avgRating >= 3.5 && attendanceRate >= 0.60) {
      return EventSuccessLevel.moderate;
    } else if (avgRating >= 3.0 && attendanceRate >= 0.40) {
      return EventSuccessLevel.belowExpectations;
    } else {
      return EventSuccessLevel.failure;
    }
  }
  
  /// Identify what made event successful
  List<String> _identifySuccessFactors(
    List<EventFeedback> feedback,
    Event event,
  ) {
    final factors = <String>[];
    
    // Analyze category ratings
    final avgCategoryRatings = _aggregateCategoryRatings(feedback);
    
    for (final category in avgCategoryRatings.keys) {
      if (avgCategoryRatings[category]! >= 4.5) {
        factors.add('Excellent $category');
      }
    }
    
    // Analyze highlights
    final allHighlights = feedback
      .expand((f) => f.highlights ?? [])
      .toList();
    
    final highlightFrequency = _calculateFrequency(allHighlights);
    final topHighlights = highlightFrequency.entries
      .where((e) => e.value >= 3)
      .map((e) => e.key)
      .toList();
    
    factors.addAll(topHighlights);
    
    return factors;
  }
  
  /// Identify areas for improvement
  List<String> _identifyImprovementAreas(
    List<EventFeedback> feedback,
    Event event,
  ) {
    final improvements = <String>[];
    
    // Low-rated categories
    final avgCategoryRatings = _aggregateCategoryRatings(feedback);
    
    for (final category in avgCategoryRatings.keys) {
      if (avgCategoryRatings[category]! < 3.5) {
        improvements.add('Improve $category');
      }
    }
    
    // Common improvement suggestions
    final allImprovements = feedback
      .expand((f) => f.improvements ?? [])
      .toList();
    
    final improvementFrequency = _calculateFrequency(allImprovements);
    final topImprovements = improvementFrequency.entries
      .where((e) => e.value >= 3)
      .map((e) => e.key)
      .toList();
    
    improvements.addAll(topImprovements);
    
    return improvements;
  }
}
```

#### **Success Dashboard UI:**

**File:** `lib/presentation/pages/events/event_success_dashboard.dart`

```dart
class EventSuccessDashboard extends StatelessWidget {
  final EventSuccessMetrics metrics;
  
  // Shows:
  // - Success level badge (Exceptional/Successful/etc)
  // - Key metrics (attendance, revenue, rating)
  // - NPS score
  // - What went well (success factors)
  // - What to improve (improvement areas)
  // - Partner satisfaction scores
  // - Comparison to similar events
  // - Actionable recommendations
}
```

---

## 📅 Week 3: Tax & Legal Compliance

### **Day 1-2: 1099 Generation (US)**

#### **Tax Models:**

```dart
class TaxDocument {
  final String id;
  final String userId;
  final int taxYear;
  final TaxFormType formType;
  final double totalEarnings;
  final TaxStatus status;
  final DateTime generatedAt;
  final String? documentUrl;
  final DateTime? filedWithIRSAt;
}

enum TaxFormType {
  form1099K,   // Payment card and third party network transactions
  form1099NEC, // Nonemployee compensation
  formW9,      // Request for taxpayer identification
}

enum TaxStatus {
  notRequired,     // Earnings < $600
  pending,         // Needs generation
  generated,       // Document created
  sent,            // Sent to user
  filed,           // Filed with IRS
}

class TaxProfile {
  final String userId;
  final String? ssn;           // Encrypted
  final String? ein;           // Employer ID Number
  final String? businessName;
  final TaxClassification classification;
  final bool w9Submitted;
  final DateTime? w9SubmittedAt;
}

enum TaxClassification {
  individual,
  soleProprietor,
  partnership,
  corporation,
  llc,
}
```

#### **Tax Compliance Service:**

```dart
class TaxComplianceService {
  /// Check if user needs tax documents
  Future<bool> needsTaxDocuments(String userId, int year) async {
    final earnings = await _getUserEarnings(userId, year);
    return earnings >= 600; // IRS threshold
  }
  
  /// Generate 1099 forms
  Future<TaxDocument> generate1099(String userId, int year) async {
    final earnings = await _getUserEarnings(userId, year);
    
    if (earnings < 600) {
      return TaxDocument(
        id: _generateId(),
        userId: userId,
        taxYear: year,
        formType: TaxFormType.form1099K,
        totalEarnings: earnings,
        status: TaxStatus.notRequired,
        generatedAt: DateTime.now(),
      );
    }
    
    // Get tax profile
    final taxProfile = await _getTaxProfile(userId);
    
    if (!taxProfile.w9Submitted) {
      throw Exception('W-9 required before generating 1099');
    }
    
    // Generate form (use PDF generation library)
    final pdf = await _generate1099PDF(
      userId: userId,
      taxYear: year,
      earnings: earnings,
      taxProfile: taxProfile,
    );
    
    // Upload to secure storage
    final documentUrl = await _uploadSecureDocument(pdf);
    
    // Create record
    final taxDoc = TaxDocument(
      id: _generateId(),
      userId: userId,
      taxYear: year,
      formType: TaxFormType.form1099K,
      totalEarnings: earnings,
      status: TaxStatus.generated,
      generatedAt: DateTime.now(),
      documentUrl: documentUrl,
    );
    
    await _saveTaxDocument(taxDoc);
    
    // Send to user
    await _sendTaxDocument(userId, taxDoc);
    
    // File with IRS (if required)
    await _fileWithIRS(taxDoc);
    
    return taxDoc;
  }
  
  /// Batch generate all 1099s for year
  Future<void> generateAll1099sForYear(int year) async {
    // Run in January for previous year
    final usersNeedingForms = await _getUsersWithEarningsAbove600(year);
    
    for (final userId in usersNeedingForms) {
      try {
        await generate1099(userId, year);
      } catch (e) {
        await _logTaxGenerationError(userId, year, e);
      }
    }
  }
  
  /// Request W-9 from user
  Future<void> requestW9(String userId) async {
    await _sendW9Request(userId);
  }
  
  /// Process submitted W-9
  Future<TaxProfile> submitW9({
    required String userId,
    required String ssn,
    required TaxClassification classification,
    String? ein,
    String? businessName,
  }) async {
    // Encrypt SSN
    final encryptedSSN = await _encryptSSN(ssn);
    
    // Create/update tax profile
    final profile = TaxProfile(
      userId: userId,
      ssn: encryptedSSN,
      ein: ein,
      businessName: businessName,
      classification: classification,
      w9Submitted: true,
      w9SubmittedAt: DateTime.now(),
    );
    
    await _saveTaxProfile(profile);
    
    return profile;
  }
}
```

---

### **Day 3: Sales Tax**

#### **Sales Tax Service:**

```dart
class SalesTaxService {
  /// Calculate sales tax for event
  Future<double> calculateSalesTax(
    String eventId,
    String location,
  ) async {
    final event = await _getEvent(eventId);
    
    // Check if event type is taxable
    if (!_isTaxableEventType(event.type)) {
      return 0.0;
    }
    
    // Get tax rate for location
    final taxRate = await _getTaxRate(location);
    
    // Calculate tax on ticket price
    final taxAmount = event.price * taxRate;
    
    return taxAmount;
  }
  
  /// Determine if event type is taxable
  bool _isTaxableEventType(EventType type) {
    // Educational events often tax-exempt
    // Entertainment events usually taxable
    // Varies by state
    
    const taxableTypes = [
      EventType.entertainment,
      EventType.concert,
      EventType.festival,
      EventType.tour,
    ];
    
    return taxableTypes.contains(type);
  }
  
  /// Get tax rate for location
  Future<double> _getTaxRate(String location) async {
    // Use tax rate API (Avalara, TaxJar, etc.)
    // Returns combined state + local rate
    
    // Example rates:
    // NYC: 8.875%
    // Chicago: 10.25%
    // SF: 8.5%
  }
  
  /// File sales tax return
  Future<void> fileSalesTaxReturn(
    String state,
    int month,
    int year,
  ) async {
    // Aggregate all taxable sales in state for month
    // File with state tax authority
    // Usually monthly or quarterly
  }
}
```

---

### **Day 4-5: Terms of Service & Liability**

#### **Legal Documents:**

**File:** `lib/core/legal/terms_of_service.dart`

```dart
class TermsOfService {
  static const String VERSION = '1.0.0';
  static const DateTime EFFECTIVE_DATE = DateTime(2025, 12, 1);
  
  static const String TERMS = '''
SPOTS Terms of Service

1. ACCEPTANCE OF TERMS
By using SPOTS, you agree to these Terms of Service...

2. PLATFORM FEES
SPOTS charges a 10% platform fee on all paid transactions...

3. REFUND POLICY
[Full refund policy text]

4. LIABILITY LIMITATIONS
SPOTS is a platform connecting hosts and attendees.
SPOTS is not responsible for:
- Event quality or safety
- Injuries or damages at events
- Disputes between parties
- Acts of God, weather, emergencies

Maximum liability limited to amount paid for event ticket.

5. INDEMNIFICATION
Hosts agree to indemnify SPOTS against claims arising from events...

6. INSURANCE REQUIREMENTS
Hosts must maintain appropriate insurance for high-risk events...

7. COMPLIANCE
Users must comply with all local laws, permits, licenses...

8. DISPUTE RESOLUTION
Disputes resolved through binding arbitration...

9. INTELLECTUAL PROPERTY
Users retain rights to their content...

10. TERMINATION
SPOTS may terminate accounts for violations...
  ''';
}

class UserAgreement {
  final String userId;
  final String documentType;  // 'terms', 'host_agreement', 'privacy'
  final String version;
  final DateTime agreedAt;
  final String ipAddress;
}
```

#### **Liability Waiver:**

**File:** `lib/core/legal/event_waiver.dart`

```dart
class EventWaiver {
  /// Generate waiver for event
  static String generateWaiver(Event event) {
    return '''
EVENT PARTICIPATION WAIVER AND RELEASE

Event: ${event.title}
Date: ${event.startTime}
Location: ${event.location}

I understand that participation in this event involves risks.

I AGREE TO:
1. Assume all risks of participation
2. Release SPOTS and event organizers from liability
3. Not hold SPOTS responsible for injuries or damages
4. Follow all safety guidelines and instructions
5. Leave if asked by organizers

I UNDERSTAND:
- SPOTS is a platform only
- Event is organized by independent hosts
- Emergency services: Call 911 if needed
- Photo/video consent: May be photographed

ACKNOWLEDGMENT:
By clicking "I Agree" I confirm I have read and understand
this waiver and voluntarily assume all risks.

[I Agree Button]
    ''';
  }
}
```

---

## 📅 Week 4: Fraud Prevention & Security

### **Day 1-2: Fake Event Detection**

#### **Fraud Detection Models:**

```dart
class FraudDetection {
  /// Analyze event for fraud signals
  Future<FraudScore> analyzeEvent(String eventId) async {
    final event = await _getEvent(eventId);
    final host = await _getUser(event.hostId);
    
    final signals = <FraudSignal>[];
    double riskScore = 0.0;
    
    // Check 1: New host with expensive event
    if (host.eventsHosted == 0 && event.price > 100) {
      signals.add(FraudSignal.newHostExpensiveEvent);
      riskScore += 0.3;
    }
    
    // Check 2: Location doesn't exist
    final locationValid = await _validateLocation(event.location);
    if (!locationValid) {
      signals.add(FraudSignal.invalidLocation);
      riskScore += 0.4;
    }
    
    // Check 3: Stock photos
    final imagesAreStock = await _checkForStockPhotos(event.imageUrls);
    if (imagesAreStock) {
      signals.add(FraudSignal.stockPhotos);
      riskScore += 0.2;
    }
    
    // Check 4: Duplicate of real event
    final isDuplicate = await _checkForDuplicate(event);
    if (isDuplicate) {
      signals.add(FraudSignal.duplicateEvent);
      riskScore += 0.5;
    }
    
    // Check 5: Price too good to be true
    final similarEvents = await _findSimilarEvents(event);
    final avgPrice = _calculateAveragePrice(similarEvents);
    if (event.price < avgPrice * 0.5) {
      signals.add(FraudSignal.suspiciouslyLowPrice);
      riskScore += 0.3;
    }
    
    // Check 6: Generic description
    if (_isGenericDescription(event.description)) {
      signals.add(FraudSignal.genericDescription);
      riskScore += 0.1;
    }
    
    return FraudScore(
      eventId: eventId,
      riskScore: riskScore.clamp(0.0, 1.0),
      signals: signals,
      recommendation: _getFraudRecommendation(riskScore),
    );
  }
}

enum FraudSignal {
  newHostExpensiveEvent,
  invalidLocation,
  stockPhotos,
  duplicateEvent,
  suspiciouslyLowPrice,
  genericDescription,
  rapidEventCreation,
  fakeProfessionalCreds,
  coordinatedFakeReviews,
}

class FraudScore {
  final String eventId;
  final double riskScore;  // 0.0-1.0
  final List<FraudSignal> signals;
  final FraudRecommendation recommendation;
}

enum FraudRecommendation {
  approve,              // Risk < 0.3
  reviewManually,       // Risk 0.3-0.6
  requireVerification,  // Risk 0.6-0.8
  reject,               // Risk > 0.8
}
```

---

### **Day 3: Review Authenticity**

#### **Review Fraud Detection:**

```dart
class ReviewFraudDetection {
  /// Detect fake reviews
  Future<ReviewFraudScore> analyzeReviews(String userId) async {
    final reviews = await _getUserReviews(userId);
    
    final signals = <FraudSignal>[];
    double riskScore = 0.0;
    
    // Check 1: All 5-star reviews
    final allFiveStar = reviews.every((r) => r.rating == 5.0);
    if (allFiveStar && reviews.length > 5) {
      signals.add(FraudSignal.allPerfectRatings);
      riskScore += 0.3;
    }
    
    // Check 2: All reviews on same day
    final dates = reviews.map((r) => r.createdAt.day).toSet();
    if (dates.length == 1 && reviews.length > 3) {
      signals.add(FraudSignal.sameDay Clustering);
      riskScore += 0.4;
    }
    
    // Check 3: Generic text
    final genericCount = reviews.where(_isGenericReview).length;
    if (genericCount > reviews.length * 0.5) {
      signals.add(FraudSignal.genericReviews);
      riskScore += 0.2;
    }
    
    // Check 4: Similar language patterns
    if (_haveSimilarLanguage(reviews)) {
      signals.add(FraudSignal.similarLanguage);
      riskScore += 0.3;
    }
    
    return ReviewFraudScore(
      userId: userId,
      riskScore: riskScore,
      signals: signals,
    );
  }
}
```

---

### **Day 4-5: Identity Verification**

#### **Identity Verification Service:**

```dart
class IdentityVerificationService {
  /// Determine if user needs verification
  Future<bool> requiresVerification(String userId) async {
    final earnings = await _getUserLifetimeEarnings(userId);
    final monthlyEarnings = await _getUserMonthlyEarnings(userId);
    
    // High earners require verification
    return monthlyEarnings > 5000 || earnings > 20000;
  }
  
  /// Initiate verification
  Future<VerificationSession> initiateVerification(
    String userId,
  ) async {
    // Use third-party service (Stripe Identity, Persona, Jumio)
    final session = await _stripeIdentity.createVerificationSession(
      userId: userId,
      options: {
        'type': 'document',
        'require_live_capture': true,
        'require_matching_selfie': true,
      },
    );
    
    return VerificationSession(
      id: session.id,
      userId: userId,
      status: VerificationStatus.pending,
      verificationUrl: session.url,
      createdAt: DateTime.now(),
    );
  }
  
  /// Check verification status
  Future<VerificationResult> checkVerificationStatus(
    String sessionId,
  ) async {
    final session = await _stripeIdentity.retrieveSession(sessionId);
    
    return VerificationResult(
      sessionId: sessionId,
      status: _mapStatus(session.status),
      verified: session.status == 'verified',
      verifiedAt: session.verified ? DateTime.now() : null,
    );
  }
}
```

---

## 📊 Implementation Summary

### **Week 1 Deliverables:**
- ✅ Refund policy (time-based windows)
- ✅ Cancellation service (host, attendee, emergency)
- ✅ Safety guidelines per event type
- ✅ Emergency info requirements
- ✅ Insurance recommendations
- ✅ Dispute submission system
- ✅ Dispute escalation workflow

### **Week 2 Deliverables:**
- ✅ Attendee feedback forms
- ✅ Partner mutual rating system
- ✅ Success metrics calculation
- ✅ Success dashboard
- ✅ Learning algorithm integration
- ✅ Reputation updates

### **Week 3 Deliverables:**
- ✅ 1099 generation (automated)
- ✅ W-9 collection system
- ✅ Sales tax calculation
- ✅ Terms of Service
- ✅ Liability waivers
- ✅ User agreement tracking

### **Week 4 Deliverables:**
- ✅ Fake event detection
- ✅ Review fraud detection
- ✅ Identity verification (high earners)
- ✅ Fraud scoring system
- ✅ Admin fraud review tools

---

## ✅ Final System Completeness

**After This Plan:**
- Core monetization: ✅ 95%
- Expertise system: ✅ 100%
- **Operations & safety: ✅ 95%** (was 40%)
- **Compliance & legal: ✅ 90%** (was 30%)
- International readiness: ⚠️ 10% (future)

**Overall: 95% Complete → MVP Ready**

---

**Status:** 🟢 Complete 4-week plan ready  
**Next Step:** Begin Week 1 implementation  
**Timeline:** 4 weeks to MVP-ready system  
**Dependencies:** Existing monetization & expertise systems

---

**Last Updated:** November 21, 2025  
**Related Plans:** All monetization, expertise, and partnership plans

