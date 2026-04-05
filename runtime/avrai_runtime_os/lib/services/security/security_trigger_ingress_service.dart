import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';

class SecurityQueuedCampaignTrigger {
  const SecurityQueuedCampaignTrigger({
    required this.id,
    required this.campaignId,
    required this.trigger,
    required this.actorAlias,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String campaignId;
  final SecurityCampaignTrigger trigger;
  final String actorAlias;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'campaignId': campaignId,
        'trigger': trigger.name,
        'actorAlias': actorAlias,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'metadata': metadata,
      };

  factory SecurityQueuedCampaignTrigger.fromJson(Map<String, dynamic> json) {
    return SecurityQueuedCampaignTrigger(
      id: json['id']?.toString() ?? '',
      campaignId: json['campaignId']?.toString() ?? '',
      trigger: SecurityCampaignTrigger.values.firstWhere(
        (entry) => entry.name == json['trigger'],
        orElse: () => SecurityCampaignTrigger.manual,
      ),
      actorAlias: json['actorAlias']?.toString() ?? 'security_kernel',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SecurityTriggerIngressService {
  SecurityTriggerIngressService({
    required SecurityCampaignRegistry campaignRegistry,
    SharedPreferencesCompat? prefs,
    DateTime Function()? nowProvider,
  })  : _campaignRegistry = campaignRegistry,
        _prefs = prefs,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  static const String _pendingTriggersKey = 'security.trigger_ingress.v1';
  static const int _maxPendingTriggers = 128;

  final SecurityCampaignRegistry _campaignRegistry;
  final SharedPreferencesCompat? _prefs;
  final DateTime Function() _nowProvider;

  Future<void> notifyCodeChange({
    required List<String> changedPaths,
    required String commitRef,
    String actorAlias = 'security_kernel',
  }) async {
    final normalizedPaths = changedPaths
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    await _enqueueMatching(
      trigger: SecurityCampaignTrigger.codeChange,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'changed_paths': normalizedPaths,
        'commit_ref': commitRef,
      },
      matcher: (definition) {
        if (normalizedPaths.isEmpty || definition.pathPrefixes.isEmpty) {
          return false;
        }
        return normalizedPaths.any(
          (path) => definition.pathPrefixes.any(path.startsWith),
        );
      },
    );
  }

  Future<void> notifyModelPromotion({
    required String surfaceId,
    required String version,
    String actorAlias = 'security_kernel',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _enqueueMatching(
      trigger: SecurityCampaignTrigger.modelPromotion,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'surface_id': surfaceId,
        'version': version,
        ...metadata,
      },
      matcher: (definition) => _matchesPromotion(
        definition: definition,
        selectorSource: <String>[surfaceId, version],
      ),
    );
  }

  Future<void> notifyPolicyPromotion({
    required String policyId,
    required TruthScopeDescriptor scope,
    String actorAlias = 'security_kernel',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _enqueueMatching(
      trigger: SecurityCampaignTrigger.policyPromotion,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'policy_id': policyId,
        'truth_scope': scope.toJson(),
        ...metadata,
      },
      matcher: (definition) =>
          _matchesPromotion(
            definition: definition,
            selectorSource: <String>[
              policyId,
              scope.scopeKey,
              scope.sphereId,
              scope.familyId,
            ],
          ) &&
          _scopesIntersect(definition.truthScope, scope),
    );
  }

  Future<void> notifyReplayedIncident({
    required String incidentId,
    required List<String> tags,
    required TruthScopeDescriptor truthScope,
    String actorAlias = 'security_kernel',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final normalizedTags = tags
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    await _enqueueMatching(
      trigger: SecurityCampaignTrigger.replayedIncident,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'incident_id': incidentId,
        'incident_tags': normalizedTags.toList(growable: false),
        'truth_scope': truthScope.toJson(),
        ...metadata,
      },
      matcher: (definition) {
        if (!_scopesIntersect(definition.truthScope, truthScope)) {
          return false;
        }
        if (definition.incidentTags.isEmpty) {
          return false;
        }
        return definition.incidentTags.any(
          (entry) => normalizedTags.contains(entry.toLowerCase()),
        );
      },
    );
  }

  Future<List<SecurityQueuedCampaignTrigger>> flushPendingTriggers() async {
    final pending = _readPending().toList(growable: false);
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(_pendingTriggersKey);
    }
    return pending;
  }

  List<SecurityQueuedCampaignTrigger> pendingTriggers({int limit = 32}) {
    final pending = _readPending();
    final normalizedLimit = limit.clamp(0, pending.length);
    if (normalizedLimit == 0) {
      return const <SecurityQueuedCampaignTrigger>[];
    }
    return pending.take(normalizedLimit).toList(growable: false);
  }

  Future<void> _enqueueMatching({
    required SecurityCampaignTrigger trigger,
    required String actorAlias,
    required Map<String, dynamic> metadata,
    required bool Function(SecurityCampaignDefinition definition) matcher,
  }) async {
    final matchedDefinitions = _campaignRegistry.definitions().where((entry) {
      return entry.triggers.contains(trigger) && matcher(entry);
    }).toList(growable: false);
    if (matchedDefinitions.isEmpty) {
      return;
    }
    final existing = _readPending().toList(growable: true);
    final now = _nowProvider();
    for (final definition in matchedDefinitions) {
      final identity = '${definition.id}:${trigger.name}';
      existing.removeWhere(
        (entry) =>
            entry.campaignId == definition.id && entry.trigger == trigger,
      );
      existing.insert(
        0,
        SecurityQueuedCampaignTrigger(
          id: 'trigger_${identity}_${now.microsecondsSinceEpoch}',
          campaignId: definition.id,
          trigger: trigger,
          actorAlias: actorAlias,
          createdAt: now,
          metadata: <String, dynamic>{
            'identity': identity,
            ...metadata,
          },
        ),
      );
    }
    if (existing.length > _maxPendingTriggers) {
      existing.removeRange(_maxPendingTriggers, existing.length);
    }
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      _pendingTriggersKey,
      jsonEncode(existing.map((entry) => entry.toJson()).toList()),
    );
  }

  List<SecurityQueuedCampaignTrigger> _readPending() {
    final prefs = _prefs;
    if (prefs == null) {
      return const <SecurityQueuedCampaignTrigger>[];
    }
    final raw = prefs.getString(_pendingTriggersKey);
    if (raw == null || raw.isEmpty) {
      return const <SecurityQueuedCampaignTrigger>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <SecurityQueuedCampaignTrigger>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) => SecurityQueuedCampaignTrigger.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  bool _matchesPromotion({
    required SecurityCampaignDefinition definition,
    required List<String> selectorSource,
  }) {
    if (definition.promotionSelectors.isEmpty) {
      return false;
    }
    final normalized = selectorSource
        .map((entry) => entry.toLowerCase())
        .toList(growable: false);
    return definition.promotionSelectors.any((selector) {
      final token = selector.toLowerCase();
      return normalized.any((entry) => entry.contains(token));
    });
  }

  bool _scopesIntersect(
    TruthScopeDescriptor left,
    TruthScopeDescriptor right,
  ) {
    if (left.tenantScope != right.tenantScope) {
      return false;
    }
    if ((left.tenantId ?? '') != (right.tenantId ?? '')) {
      return false;
    }
    return left.sphereId == right.sphereId ||
        left.familyId == right.familyId ||
        left.governanceStratum == right.governanceStratum;
  }
}
