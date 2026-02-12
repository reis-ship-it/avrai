// Matching Input Model
//
// Input data for quantum matching controller
// Part of Phase 19 Section 19.5: Quantum Matching Controller

import 'package:equatable/equatable.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/business/business_account.dart';

/// Input data for multi-entity quantum matching
///
/// Contains user and entities to match against
class MatchingInput extends Equatable {
  /// User to match
  final UnifiedUser user;

  /// Event to match against (optional)
  final ExpertiseEvent? event;

  /// Spot to match against (optional)
  final Spot? spot;

  /// Business to match against (optional)
  final BusinessAccount? business;

  /// Additional entities (experts, brands, sponsors, etc.)
  /// Stored as dynamic to support any entity type
  final List<dynamic>? additionalEntities;

  const MatchingInput({
    required this.user,
    this.event,
    this.spot,
    this.business,
    this.additionalEntities,
  });

  /// Get all entities as a list
  List<dynamic> get allEntities {
    final entities = <dynamic>[];
    if (event != null) entities.add(event!);
    if (spot != null) entities.add(spot!);
    if (business != null) entities.add(business!);
    if (additionalEntities != null) entities.addAll(additionalEntities!);
    return entities;
  }

  /// Check if input is valid (has at least one entity)
  bool get isValid => allEntities.isNotEmpty;

  @override
  List<Object?> get props => [user, event, spot, business, additionalEntities];
}
