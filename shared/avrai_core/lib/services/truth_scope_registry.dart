import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class TruthScopeRegistry {
  const TruthScopeRegistry();

  TruthScopeDescriptor normalizeForecastScope({
    TruthScopeDescriptor? scope,
    required Map<String, dynamic> metadata,
    required String familyId,
  }) {
    final resolved = scope ??
        _scopeFromMetadata(metadata) ??
        TruthScopeDescriptor.defaultForecast(
          governanceStratum: _governanceStratumFromRaw(
            metadata['governance_stratum']?.toString(),
            fallback: GovernanceStratum.personal,
          ),
          tenantScope: _tenantScopeFromRaw(
            metadata['tenant_scope']?.toString(),
            fallback: TruthTenantScope.avraiNative,
          ),
          tenantId: metadata['tenant_id']?.toString(),
          agentClass: _agentClassFromMetadata(
            metadata,
            fallback: TruthAgentClass.system,
          ),
          sphereId: metadata['forecast_sphere_id']?.toString() ??
              metadata['sphere_id']?.toString() ??
              'forecast',
          familyId: metadata['truth_family_id']?.toString() ?? familyId,
        );
    return validate(
      resolved.copyWith(
        truthSurfaceKind: TruthSurfaceKind.forecast,
        familyId: resolved.familyId.isEmpty ? familyId : resolved.familyId,
      ),
      expectedSurfaceKind: TruthSurfaceKind.forecast,
    );
  }

  TruthScopeDescriptor normalizeSecurityScope({
    TruthScopeDescriptor? scope,
    String? governanceScope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final resolved = scope ??
        _scopeFromMetadata(metadata) ??
        TruthScopeDescriptor.defaultSecurity(
          governanceStratum: _stratumFromGovernanceScope(governanceScope),
          tenantScope: _tenantScopeFromRaw(
            metadata['tenant_scope']?.toString(),
            fallback: TruthTenantScope.avraiNative,
          ),
          tenantId: metadata['tenant_id']?.toString(),
          agentClass: _agentClassFromMetadata(
            metadata,
            fallback: TruthAgentClass.security,
          ),
          sphereId: metadata['security_sphere_id']?.toString() ??
              metadata['sphere_id']?.toString() ??
              'security',
          familyId: metadata['family_id']?.toString() ??
              metadata['countermeasure_family_id']?.toString() ??
              'security_kernel',
        );
    return validate(
      resolved.copyWith(truthSurfaceKind: TruthSurfaceKind.security),
      expectedSurfaceKind: TruthSurfaceKind.security,
    );
  }

  TruthScopeDescriptor normalizePlanningScope({
    TruthScopeDescriptor? scope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String familyId = 'event_prep',
  }) {
    final resolved = scope ??
        _scopeFromMetadata(metadata) ??
        TruthScopeDescriptor.defaultPlanning(
          governanceStratum: _governanceStratumFromRaw(
            metadata['governance_stratum']?.toString(),
            fallback: GovernanceStratum.personal,
          ),
          tenantScope: _tenantScopeFromRaw(
            metadata['tenant_scope']?.toString(),
            fallback: TruthTenantScope.avraiNative,
          ),
          tenantId: metadata['tenant_id']?.toString(),
          agentClass: _agentClassFromMetadata(
            metadata,
            fallback: TruthAgentClass.organizer,
          ),
          sphereId: metadata['planning_sphere_id']?.toString() ??
              metadata['sphere_id']?.toString() ??
              'event_planning',
          familyId: metadata['planning_family_id']?.toString() ??
              metadata['truth_family_id']?.toString() ??
              familyId,
        );
    return validate(
      resolved.copyWith(
        truthSurfaceKind: TruthSurfaceKind.planning,
        familyId: resolved.familyId.isEmpty ? familyId : resolved.familyId,
      ),
      expectedSurfaceKind: TruthSurfaceKind.planning,
    );
  }

  TruthScopeDescriptor normalizeResearchScope({
    TruthScopeDescriptor? scope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String familyId = 'governed_autoresearch',
  }) {
    final resolved = scope ??
        _scopeFromMetadata(metadata) ??
        TruthScopeDescriptor.defaultResearch(
          governanceStratum: _governanceStratumFromRaw(
            metadata['governance_stratum']?.toString(),
            fallback: GovernanceStratum.world,
          ),
          tenantScope: _tenantScopeFromRaw(
            metadata['tenant_scope']?.toString(),
            fallback: TruthTenantScope.avraiNative,
          ),
          tenantId: metadata['tenant_id']?.toString(),
          agentClass: _agentClassFromMetadata(
            metadata,
            fallback: TruthAgentClass.system,
          ),
          sphereId: metadata['research_sphere_id']?.toString() ??
              metadata['sphere_id']?.toString() ??
              'autoresearch',
          familyId: metadata['research_family_id']?.toString() ??
              metadata['truth_family_id']?.toString() ??
              familyId,
        );
    return validate(
      resolved.copyWith(
        truthSurfaceKind: TruthSurfaceKind.research,
        familyId: resolved.familyId.isEmpty ? familyId : resolved.familyId,
      ),
      expectedSurfaceKind: TruthSurfaceKind.research,
    );
  }

  TruthScopeDescriptor normalizeHealingScope({
    TruthScopeDescriptor? scope,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String familyId = 'self_heal_kernel',
  }) {
    final resolved = scope ??
        _scopeFromMetadata(metadata) ??
        TruthScopeDescriptor.defaultHealing(
          governanceStratum: _governanceStratumFromRaw(
            metadata['governance_stratum']?.toString(),
            fallback: GovernanceStratum.world,
          ),
          tenantScope: _tenantScopeFromRaw(
            metadata['tenant_scope']?.toString(),
            fallback: TruthTenantScope.avraiNative,
          ),
          tenantId: metadata['tenant_id']?.toString(),
          agentClass: _agentClassFromMetadata(
            metadata,
            fallback: TruthAgentClass.system,
          ),
          sphereId: metadata['healing_sphere_id']?.toString() ??
              metadata['sphere_id']?.toString() ??
              'self_healing',
          familyId: metadata['healing_family_id']?.toString() ??
              metadata['truth_family_id']?.toString() ??
              familyId,
        );
    return validate(
      resolved.copyWith(
        truthSurfaceKind: TruthSurfaceKind.healing,
        familyId: resolved.familyId.isEmpty ? familyId : resolved.familyId,
      ),
      expectedSurfaceKind: TruthSurfaceKind.healing,
    );
  }

  TruthScopeDescriptor validate(
    TruthScopeDescriptor scope, {
    TruthSurfaceKind? expectedSurfaceKind,
  }) {
    final validated = scope.copyWith(
      sphereId: scope.sphereId.trim().isEmpty ? 'unspecified' : scope.sphereId,
      familyId:
          scope.familyId.trim().isEmpty ? 'default_family' : scope.familyId,
    );
    if (expectedSurfaceKind != null &&
        validated.truthSurfaceKind != expectedSurfaceKind) {
      return validated.copyWith(truthSurfaceKind: expectedSurfaceKind);
    }
    return validated;
  }

  bool allowsHigherStratumRawDetail({
    required GovernanceStratum source,
    required GovernanceStratum target,
  }) {
    return source == target;
  }

  TruthScopeDescriptor? _scopeFromMetadata(Map<String, dynamic> metadata) {
    final raw = metadata['truth_scope'] ??
        metadata['planning_truth_scope'] ??
        metadata['research_truth_scope'] ??
        metadata['healing_truth_scope'];
    if (raw is Map) {
      return TruthScopeDescriptor.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  GovernanceStratum _stratumFromGovernanceScope(String? raw) {
    switch (raw) {
      case 'personal':
        return GovernanceStratum.personal;
      case 'geographic:locality':
      case 'locality':
        return GovernanceStratum.locality;
      case 'geographic:district':
      case 'geographic:city':
      case 'geographic:region':
      case 'world':
        return GovernanceStratum.world;
      case 'geographic:country':
      case 'geographic:global':
      case 'universal':
        return GovernanceStratum.universal;
      default:
        return GovernanceStratum.personal;
    }
  }

  GovernanceStratum _governanceStratumFromRaw(
    String? raw, {
    required GovernanceStratum fallback,
  }) {
    return GovernanceStratum.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => fallback,
    );
  }

  TruthTenantScope _tenantScopeFromRaw(
    String? raw, {
    required TruthTenantScope fallback,
  }) {
    return TruthTenantScope.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => fallback,
    );
  }

  TruthAgentClass _agentClassFromMetadata(
    Map<String, dynamic> metadata, {
    required TruthAgentClass fallback,
  }) {
    final rawAgentClass = metadata['agent_class']?.toString();
    final directMatch = TruthAgentClass.values.where(
      (value) => value.name == rawAgentClass,
    );
    if (directMatch.isNotEmpty) {
      return directMatch.first;
    }
    final entityType = metadata['entity_type']?.toString().toLowerCase();
    return switch (entityType) {
      'venue' ||
      'business' ||
      'business_account' ||
      'spot' =>
        TruthAgentClass.business,
      'organizer' || 'event_host' => TruthAgentClass.organizer,
      'community' || 'club' || 'locality' => TruthAgentClass.locality,
      'partner' => TruthAgentClass.partner,
      'consumer' || 'user' || 'person' => TruthAgentClass.consumer,
      _ => fallback,
    };
  }
}
