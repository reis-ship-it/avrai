import 'dart:convert';

import 'package:avrai_core/models/user/language_profile.dart';
import 'package:avrai_core/models/user/language_profile_diagnostics.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_conversation_style_hydration_service.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/platform_channel_helper.dart';

class _FakeLanguageProfileDiagnosticsService
    implements LanguageProfileDiagnosticsService {
  const _FakeLanguageProfileDiagnosticsService(this.snapshot);

  final LanguageProfileDiagnosticsSnapshot? snapshot;

  @override
  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForProfileRef(
    String profileRef, {
    int recentEventLimit = 6,
  }) async {
    return snapshot;
  }

  @override
  Future<LanguageProfileDiagnosticsSnapshot?> getDiagnosticsForUser(
    String userId, {
    int recentEventLimit = 6,
  }) async {
    return snapshot;
  }
}

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  test('hydrates admin conversation style snapshot from current session',
      () async {
    final prefs = await SharedPreferencesCompat.getInstance(
      storage: getTestStorage(
        boxName: 'admin_conversation_style_hydration_prefs',
      ),
    );
    final session = AdminSession(
      username: 'reis',
      loginTime: DateTime.utc(2026, 4, 4, 12),
      expiresAt: DateTime.utc(2026, 4, 4, 20),
      accessLevel: AdminAccessLevel.godMode,
      permissions: AdminPermissions.all(),
      sessionTokenId: 'session_123',
      issuedBy: 'test_control_plane',
      requiresPrivateControlPlane: true,
    );
    await prefs.setString('admin_session', jsonEncode(session.toJson()));
    final authService = AdminAuthService(
      prefs,
      gateway: AdminControlPlaneGatewayFactory.createForTesting(prefs: prefs),
    );
    final diagnosticsService = _FakeLanguageProfileDiagnosticsService(
      LanguageProfileDiagnosticsSnapshot(
        profileRef: 'governance_operator_admin_reis',
        displayRef: 'admin:reis',
        profile: LanguageProfile(
          agentId: 'governance_operator_admin_reis',
          userId: 'admin:reis',
          vocabulary: const <String, double>{
            'bounded': 0.8,
            'evidence': 0.74,
          },
          phrases: const <String, double>{
            'keep it bounded': 0.88,
          },
          tone: const <String, double>{
            'formality': 0.44,
            'enthusiasm': 0.32,
            'directness': 0.73,
          },
          metadata: const <String, dynamic>{
            'messageCount': 64,
            'learningConfidence': 0.67,
          },
          createdAt: DateTime.utc(2026, 4, 1, 8),
          lastUpdated: DateTime.utc(2026, 4, 4, 12),
        ),
        recentEvents: <LanguageLearningEvent>[
          LanguageLearningEvent(
            profileRef: 'governance_operator_admin_reis',
            displayRef: 'admin:reis',
            learningScope: 'governance_feedback_acceptance',
            surface: 'admin',
            source: 'sanitized_artifact',
            summary: 'Approved response learned.',
            vocabularySample: <String>['bounded'],
            phraseSample: <String>['keep it bounded'],
            toneSnapshot: <String, double>{'directness': 0.73},
            messageCountAfter: 64,
            confidenceAfter: 0.67,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              1775304000000,
              isUtc: true,
            ),
          ),
        ],
      ),
    );
    final service = AdminConversationStyleHydrationService(
      prefs: prefs,
      adminAuthService: authService,
      languageDiagnosticsService: diagnosticsService,
    );

    final snapshot = await service.hydrateForCurrentSession();
    final persisted = service.getCurrentSnapshot();

    expect(snapshot, isNotNull);
    expect(snapshot!.operatorToken, 'admin:reis');
    expect(snapshot.profileRef, 'governance_operator_admin_reis');
    expect(snapshot.status, 'session_hydrated_with_adaptive_operator_style');
    expect(snapshot.readyForAdaptation, isTrue);
    expect(snapshot.messageCount, 64);
    expect(snapshot.learningConfidence, 0.67);
    expect(snapshot.topVocabulary, contains('bounded'));
    expect(snapshot.topPhrases, contains('keep it bounded'));
    expect(snapshot.recentLearningScopes,
        contains('governance_feedback_acceptance'));
    expect(
      snapshot.mouthGuidance,
      contains('prefer direct answers'),
    );
    expect(persisted?.operatorToken, 'admin:reis');
  });
}
