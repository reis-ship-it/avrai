import 'dart:convert';

import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:get_it/get_it.dart';

class AdminConversationStyleSessionSnapshot {
  const AdminConversationStyleSessionSnapshot({
    required this.operatorToken,
    required this.profileRef,
    required this.displayRef,
    required this.hydratedAtUtc,
    required this.loginTimeUtc,
    required this.expiresAtUtc,
    required this.status,
    required this.readyForAdaptation,
    required this.messageCount,
    required this.learningConfidence,
    this.sessionTokenId,
    this.issuedBy,
    this.topVocabulary = const <String>[],
    this.topPhrases = const <String>[],
    this.tone = const <String, double>{},
    this.recentLearningScopes = const <String>[],
    this.mouthGuidance = '',
  });

  final String operatorToken;
  final String profileRef;
  final String displayRef;
  final DateTime hydratedAtUtc;
  final DateTime loginTimeUtc;
  final DateTime expiresAtUtc;
  final String status;
  final bool readyForAdaptation;
  final int messageCount;
  final double learningConfidence;
  final String? sessionTokenId;
  final String? issuedBy;
  final List<String> topVocabulary;
  final List<String> topPhrases;
  final Map<String, double> tone;
  final List<String> recentLearningScopes;
  final String mouthGuidance;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'operatorToken': operatorToken,
      'profileRef': profileRef,
      'displayRef': displayRef,
      'hydratedAtUtc': hydratedAtUtc.toUtc().toIso8601String(),
      'loginTimeUtc': loginTimeUtc.toUtc().toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
      'status': status,
      'readyForAdaptation': readyForAdaptation,
      'messageCount': messageCount,
      'learningConfidence': learningConfidence,
      'sessionTokenId': sessionTokenId,
      'issuedBy': issuedBy,
      'topVocabulary': topVocabulary,
      'topPhrases': topPhrases,
      'tone': tone,
      'recentLearningScopes': recentLearningScopes,
      'mouthGuidance': mouthGuidance,
    };
  }

  factory AdminConversationStyleSessionSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminConversationStyleSessionSnapshot(
      operatorToken: json['operatorToken'] as String? ?? '',
      profileRef: json['profileRef'] as String? ?? '',
      displayRef: json['displayRef'] as String? ?? '',
      hydratedAtUtc:
          DateTime.tryParse(json['hydratedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      loginTimeUtc:
          DateTime.tryParse(json['loginTimeUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: json['status'] as String? ?? 'unknown',
      readyForAdaptation: json['readyForAdaptation'] as bool? ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      learningConfidence:
          (json['learningConfidence'] as num?)?.toDouble() ?? 0.0,
      sessionTokenId: json['sessionTokenId'] as String?,
      issuedBy: json['issuedBy'] as String?,
      topVocabulary:
          (json['topVocabulary'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      topPhrases: (json['topPhrases'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      tone: Map<String, double>.from(
        (json['tone'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            ) ??
            const <String, double>{},
      ),
      recentLearningScopes:
          (json['recentLearningScopes'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      mouthGuidance: json['mouthGuidance'] as String? ?? '',
    );
  }
}

class AdminConversationStyleHydrationService {
  static const String _currentSnapshotKey =
      'admin_conversation_style_session_current_v1';
  static const String _snapshotKeyPrefix =
      'admin_conversation_style_session_snapshot_v1:';

  final SharedPreferencesCompat? _prefs;
  final AdminAuthService? _adminAuthService;
  final LanguageProfileDiagnosticsService _languageDiagnosticsService;

  AdminConversationStyleHydrationService({
    SharedPreferencesCompat? prefs,
    AdminAuthService? adminAuthService,
    LanguageProfileDiagnosticsService? languageDiagnosticsService,
  })  : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null),
        _adminAuthService = adminAuthService ??
            (GetIt.instance.isRegistered<AdminAuthService>()
                ? GetIt.instance<AdminAuthService>()
                : null),
        _languageDiagnosticsService = languageDiagnosticsService ??
            (GetIt.instance.isRegistered<LanguageProfileDiagnosticsService>()
                ? GetIt.instance<LanguageProfileDiagnosticsService>()
                : LanguageProfileDiagnosticsService());

  Future<AdminConversationStyleSessionSnapshot?>
      hydrateForCurrentSession() async {
    final session = _adminAuthService?.getCurrentSession();
    final username = session?.username.trim();
    if (session == null || username == null || username.isEmpty) {
      return null;
    }

    final operatorToken = 'admin:$username';
    final normalized = _normalizeProfileToken(operatorToken);
    final profileRef = 'governance_operator_$normalized';
    final diagnostics = await _languageDiagnosticsService
        .getDiagnosticsForProfileRef(profileRef, recentEventLimit: 6);
    final snapshot = AdminConversationStyleSessionSnapshot(
      operatorToken: operatorToken,
      profileRef: profileRef,
      displayRef: diagnostics?.displayRef ?? operatorToken,
      hydratedAtUtc: DateTime.now().toUtc(),
      loginTimeUtc: session.loginTime.toUtc(),
      expiresAtUtc: session.expiresAt.toUtc(),
      status: diagnostics == null
          ? 'session_hydrated_waiting_for_governed_learning'
          : diagnostics.profile.isReadyForAdaptation
              ? 'session_hydrated_with_adaptive_operator_style'
              : 'session_hydrated_with_learning_in_progress',
      readyForAdaptation: diagnostics?.profile.isReadyForAdaptation ?? false,
      messageCount: diagnostics?.profile.messageCount ?? 0,
      learningConfidence: diagnostics?.profile.learningConfidence ?? 0.0,
      sessionTokenId: session.sessionTokenId,
      issuedBy: session.issuedBy,
      topVocabulary: diagnostics
              ?.topVocabulary(limit: 4)
              .map((entry) => entry.key)
              .toList(growable: false) ??
          const <String>[],
      topPhrases: diagnostics
              ?.topPhrases(limit: 3)
              .map((entry) => entry.key)
              .toList(growable: false) ??
          const <String>[],
      tone: diagnostics?.profile.tone ?? const <String, double>{},
      recentLearningScopes: diagnostics?.recentEvents
              .map((event) => event.learningScope)
              .toSet()
              .toList(growable: false) ??
          const <String>[],
      mouthGuidance: _buildMouthGuidance(diagnostics),
    );

    await _persistSnapshot(snapshot);
    return snapshot;
  }

  AdminConversationStyleSessionSnapshot? getCurrentSnapshot() {
    final activeKey = _prefs?.getString(_currentSnapshotKey);
    if (activeKey == null || activeKey.isEmpty) {
      return null;
    }
    return _readSnapshot(activeKey);
  }

  Future<void> clearCurrentSessionSnapshot() async {
    final activeKey = _prefs?.getString(_currentSnapshotKey);
    if (activeKey != null && activeKey.isNotEmpty) {
      await _prefs?.remove(activeKey);
    }
    await _prefs?.remove(_currentSnapshotKey);
  }

  Future<void> _persistSnapshot(
    AdminConversationStyleSessionSnapshot snapshot,
  ) async {
    final key =
        '$_snapshotKeyPrefix${_normalizeProfileToken(snapshot.operatorToken)}';
    await _prefs?.setString(key, jsonEncode(snapshot.toJson()));
    await _prefs?.setString(_currentSnapshotKey, key);
  }

  AdminConversationStyleSessionSnapshot? _readSnapshot(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AdminConversationStyleSessionSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  String _buildMouthGuidance(
    dynamic diagnostics,
  ) {
    if (diagnostics == null) {
      return 'No governed operator language profile yet. Start with neutral, explicit, bounded explanations until local admin learning matures.';
    }
    final profile = diagnostics.profile;
    final tone = profile.tone;
    final directness = (tone['directness'] ?? 0.5);
    final formality = (tone['formality'] ?? 0.5);
    final enthusiasm = (tone['enthusiasm'] ?? 0.5);
    final toneBits = <String>[
      directness >= 0.6 ? 'prefer direct answers' : 'keep answers measured',
      formality >= 0.6 ? 'use a formal register' : 'keep the register plain',
      enthusiasm >= 0.6
          ? 'allow higher energy emphasis'
          : 'keep emphasis restrained',
    ];
    return 'Hydrated from governed operator language learning: ${toneBits.join(', ')}.';
  }

  String _normalizeProfileToken(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        );
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
