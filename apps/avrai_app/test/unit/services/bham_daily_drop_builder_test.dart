import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_core/models/feed/daily_serendipity_drop.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/onboarding/bham_daily_drop_builder.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('BhamDailyDropBuilder', () {
    late SharedPreferencesCompat prefs;
    late BhamDailyDropBuilder builder;

    setUp(() async {
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'bham_daily_drop_builder'),
      );
      builder = BhamDailyDropBuilder(prefs: prefs);
    });

    test('buildInitialDrop returns the canonical 5-category BHAM contract',
        () async {
      final result = await builder.buildInitialDrop(
        userId: 'user-1',
        onboardingData: _validBhamOnboardingData(),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.schemaVersion,
          DailySerendipityDropStorage.schemaVersion);
      expect(result.data!.cityName, 'Birmingham');
      expect(result.data!.spot.title, isNotEmpty);
      expect(result.data!.list.title, isNotEmpty);
      expect(result.data!.event.title, isNotEmpty);
      expect(result.data!.club.title, isNotEmpty);
      expect(result.data!.community.title, isNotEmpty);
    });

    test('buildInitialDrop fails when BHAM consent is missing', () async {
      final result = await builder.buildInitialDrop(
        userId: 'user-1',
        onboardingData: _validBhamOnboardingData().copyWith(
          betaConsentAccepted: false,
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'BHAM_CONSENT_REQUIRED');
    });

    test(
        'buildInitialDrop fails when required questionnaire responses are missing',
        () async {
      final result = await builder.buildInitialDrop(
        userId: 'user-1',
        onboardingData: _validBhamOnboardingData().copyWith(
          openResponses: <String, String>{
            'more_of': 'more peace',
          },
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'BHAM_QUESTIONNAIRE_INCOMPLETE');
    });

    test('persists the BHAM v2 drop and clears the legacy v1 cache', () async {
      await prefs.setString(
        'latest_daily_serendipity_drop',
        jsonEncode(<String, dynamic>{
          'event': <String, dynamic>{'title': 'legacy'},
          'spot': <String, dynamic>{'title': 'legacy'},
          'community': <String, dynamic>{'title': 'legacy'},
          'club': <String, dynamic>{'title': 'legacy'},
        }),
      );

      final result = await builder.buildInitialDrop(
        userId: 'user-1',
        onboardingData: _validBhamOnboardingData(),
      );

      expect(result.isSuccess, isTrue);
      expect(
        prefs.containsKey(DailySerendipityDropStorage.latestDropKey),
        isTrue,
      );
      expect(prefs.containsKey('latest_daily_serendipity_drop'), isFalse);

      final loaded = await builder.loadLatestDrop();
      expect(loaded, isNotNull);
      expect(loaded!.schemaVersion, DailySerendipityDropStorage.schemaVersion);
    });
  });
}

OnboardingData _validBhamOnboardingData() {
  return OnboardingData(
    agentId: 'agent_test123456789012345678901234567890',
    homebase: BhamBetaDefaults.defaultHomebase,
    openResponses: <String, String>{
      'more_of': 'more calm',
      'less_of': 'less drift',
      'values': 'honesty and growth',
      'interests': 'music, coffee, walking',
      'fun': 'live music and neighborhood hangs',
      'favorite_places': 'Avondale, Highland Park, parks',
      'goals': 'better routines and local signal',
      'transportation': 'driving and walking',
      'spending': 'moderate and intentional',
      'social_energy': 'Somewhere in the middle',
      'bio': 'I want better Birmingham doors and more real-world rhythm.',
    },
    completedAt: DateTime.utc(2026, 3, 8),
    tosAccepted: true,
    privacyAccepted: true,
    betaConsentAccepted: true,
    betaConsentVersion: BhamBetaDefaults.betaConsentVersion,
    questionnaireVersion: BhamBetaDefaults.questionnaireVersion,
  );
}
