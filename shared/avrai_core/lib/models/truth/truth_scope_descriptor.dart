enum GovernanceStratum {
  personal,
  locality,
  world,
  universal,
}

enum TruthSurfaceKind {
  forecast,
  security,
  planning,
  research,
  healing,
  apiInsight,
}

enum TruthTenantScope {
  avraiNative,
  trustedPartnerPrivate,
  outsideBuyerAggregate,
}

enum TruthAgentClass {
  consumer,
  business,
  organizer,
  locality,
  planner,
  security,
  partner,
  system,
}

class TruthScopeDescriptor {
  const TruthScopeDescriptor({
    required this.governanceStratum,
    required this.truthSurfaceKind,
    required this.tenantScope,
    required this.agentClass,
    required this.sphereId,
    required this.familyId,
    this.tenantId,
  }) : assert(
          tenantScope != TruthTenantScope.trustedPartnerPrivate ||
              (tenantId != null && tenantId != ''),
          'tenantId is required for trusted partner private scope.',
        );

  const TruthScopeDescriptor.defaultForecast({
    this.governanceStratum = GovernanceStratum.personal,
    this.tenantScope = TruthTenantScope.avraiNative,
    this.agentClass = TruthAgentClass.system,
    this.sphereId = 'forecast',
    this.familyId = 'default_forecast_family',
    this.tenantId,
  }) : truthSurfaceKind = TruthSurfaceKind.forecast;

  const TruthScopeDescriptor.defaultSecurity({
    this.governanceStratum = GovernanceStratum.personal,
    this.tenantScope = TruthTenantScope.avraiNative,
    this.agentClass = TruthAgentClass.security,
    this.sphereId = 'security',
    this.familyId = 'security_kernel',
    this.tenantId,
  }) : truthSurfaceKind = TruthSurfaceKind.security;

  const TruthScopeDescriptor.defaultPlanning({
    this.governanceStratum = GovernanceStratum.personal,
    this.tenantScope = TruthTenantScope.avraiNative,
    this.agentClass = TruthAgentClass.organizer,
    this.sphereId = 'event_planning',
    this.familyId = 'event_prep',
    this.tenantId,
  }) : truthSurfaceKind = TruthSurfaceKind.planning;

  const TruthScopeDescriptor.defaultResearch({
    this.governanceStratum = GovernanceStratum.world,
    this.tenantScope = TruthTenantScope.avraiNative,
    this.agentClass = TruthAgentClass.system,
    this.sphereId = 'autoresearch',
    this.familyId = 'governed_autoresearch',
    this.tenantId,
  }) : truthSurfaceKind = TruthSurfaceKind.research;

  const TruthScopeDescriptor.defaultHealing({
    this.governanceStratum = GovernanceStratum.world,
    this.tenantScope = TruthTenantScope.avraiNative,
    this.agentClass = TruthAgentClass.system,
    this.sphereId = 'self_healing',
    this.familyId = 'self_heal_kernel',
    this.tenantId,
  }) : truthSurfaceKind = TruthSurfaceKind.healing;

  final GovernanceStratum governanceStratum;
  final TruthSurfaceKind truthSurfaceKind;
  final TruthTenantScope tenantScope;
  final String? tenantId;
  final TruthAgentClass agentClass;
  final String sphereId;
  final String familyId;

  String get tenantKey => _normalizedSegment(tenantId ?? 'global');

  String get scopeKey => <String>[
        governanceStratum.name,
        truthSurfaceKind.name,
        tenantScope.name,
        tenantKey,
        agentClass.name,
        _normalizedSegment(sphereId),
        _normalizedSegment(familyId),
      ].join('|');

  TruthScopeDescriptor copyWith({
    GovernanceStratum? governanceStratum,
    TruthSurfaceKind? truthSurfaceKind,
    TruthTenantScope? tenantScope,
    String? tenantId,
    bool clearTenantId = false,
    TruthAgentClass? agentClass,
    String? sphereId,
    String? familyId,
  }) {
    return TruthScopeDescriptor(
      governanceStratum: governanceStratum ?? this.governanceStratum,
      truthSurfaceKind: truthSurfaceKind ?? this.truthSurfaceKind,
      tenantScope: tenantScope ?? this.tenantScope,
      tenantId: clearTenantId ? null : (tenantId ?? this.tenantId),
      agentClass: agentClass ?? this.agentClass,
      sphereId: sphereId ?? this.sphereId,
      familyId: familyId ?? this.familyId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'governanceStratum': governanceStratum.name,
      'truthSurfaceKind': truthSurfaceKind.name,
      'tenantScope': tenantScope.name,
      'tenantId': tenantId,
      'agentClass': agentClass.name,
      'sphereId': sphereId,
      'familyId': familyId,
      'scopeKey': scopeKey,
    };
  }

  factory TruthScopeDescriptor.fromJson(Map<String, dynamic> json) {
    return TruthScopeDescriptor(
      governanceStratum: GovernanceStratum.values.firstWhere(
        (value) => value.name == json['governanceStratum'],
        orElse: () => GovernanceStratum.personal,
      ),
      truthSurfaceKind: TruthSurfaceKind.values.firstWhere(
        (value) => value.name == json['truthSurfaceKind'],
        orElse: () => TruthSurfaceKind.forecast,
      ),
      tenantScope: TruthTenantScope.values.firstWhere(
        (value) => value.name == json['tenantScope'],
        orElse: () => TruthTenantScope.avraiNative,
      ),
      tenantId: json['tenantId'] as String?,
      agentClass: TruthAgentClass.values.firstWhere(
        (value) => value.name == json['agentClass'],
        orElse: () => TruthAgentClass.system,
      ),
      sphereId: json['sphereId'] as String? ?? 'forecast',
      familyId: json['familyId'] as String? ?? 'default_forecast_family',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TruthScopeDescriptor &&
        other.governanceStratum == governanceStratum &&
        other.truthSurfaceKind == truthSurfaceKind &&
        other.tenantScope == tenantScope &&
        other.tenantId == tenantId &&
        other.agentClass == agentClass &&
        other.sphereId == sphereId &&
        other.familyId == familyId;
  }

  @override
  int get hashCode => Object.hash(
        governanceStratum,
        truthSurfaceKind,
        tenantScope,
        tenantId,
        agentClass,
        sphereId,
        familyId,
      );

  static String _normalizedSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'unspecified';
    }
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9:_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
