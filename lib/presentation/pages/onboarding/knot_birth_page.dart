import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/config/design_feature_flags.dart';
import 'package:avrai/core/services/telemetry/design_journey_telemetry.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/onboarding/knot_birth_experience_widget.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

enum KnotBirthTransitionOutcome {
  completed,
  skipped,
  fallback,
  timeout,
  unavailable,
}

class KnotBirthPage extends StatefulWidget {
  final String? userId;

  const KnotBirthPage({
    super.key,
    this.userId,
  });

  @override
  State<KnotBirthPage> createState() => _KnotBirthPageState();
}

class _KnotBirthPageState extends State<KnotBirthPage> {
  static const String _logName = 'KnotBirthPage';
  static const Duration _loadTimeout = Duration(seconds: 12);

  final PersonalityLearning _personalityLearning =
      GetIt.instance<PersonalityLearning>();
  final KnotStorageService _knotStorageService =
      GetIt.instance<KnotStorageService>();
  final PersonalityKnotService _personalityKnotService =
      GetIt.instance<PersonalityKnotService>();

  bool _isLoading = true;
  String? _error;
  PersonalityKnot? _knot;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _prepareKnotBirth();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepareKnotBirth() async {
    if (!DesignFeatureFlags.enableKnotBirthExperience) {
      _finish(KnotBirthTransitionOutcome.unavailable, 'flag_disabled');
      return;
    }

    final userId = widget.userId;
    if (userId == null || userId.isEmpty) {
      _finish(KnotBirthTransitionOutcome.fallback, 'missing_user_id');
      return;
    }

    _timeoutTimer = Timer(_loadTimeout, () {
      if (mounted && _isLoading) {
        _finish(KnotBirthTransitionOutcome.timeout, 'load_timeout');
      }
    });

    try {
      await DesignJourneyTelemetry.log(
        'knot_birth_start',
        params: {'user_id_present': true},
      );

      final profile = await _personalityLearning.getCurrentPersonality(userId);
      if (profile == null) {
        _finish(KnotBirthTransitionOutcome.fallback, 'missing_profile');
        return;
      }

      var knot = await _knotStorageService.loadKnot(profile.agentId);
      knot ??= await _personalityKnotService.generateKnot(profile);

      await _knotStorageService.saveKnot(profile.agentId, knot);

      if (!mounted) return;
      setState(() {
        _knot = knot;
        _isLoading = false;
      });
    } catch (e, st) {
      developer.log(
        'Knot birth preparation failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = 'We could not start knot birth right now.';
        _isLoading = false;
      });
      _finish(KnotBirthTransitionOutcome.fallback, 'exception');
    } finally {
      _timeoutTimer?.cancel();
    }
  }

  void _finish(KnotBirthTransitionOutcome outcome, String reason) {
    DesignJourneyTelemetry.log(
      'knot_birth_exit',
      params: {
        'outcome': outcome.name,
        'reason': reason,
      },
    );
    if (!mounted) return;
    context.go('/knot-discovery', extra: {
      'userId': widget.userId,
      'knotBirthOutcome': outcome.name,
      'knotBirthReason': reason,
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return AdaptivePlatformPageScaffold(
        title: 'Knot Birth',
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.electricGreen),
              SizedBox(height: spacing.md),
              Text(
                'Preparing your knot birth...',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.white),
              ),
              SizedBox(height: spacing.md + spacing.xs),
              TextButton(
                onPressed: () => _finish(
                    KnotBirthTransitionOutcome.skipped, 'user_skip_loading'),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      );
    }

    if (_knot == null) {
      return AdaptivePlatformPageScaffold(
        title: 'Knot Birth',
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.white, size: 56),
                SizedBox(height: spacing.sm),
                Text(
                  _error ?? 'Knot birth is unavailable right now.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.white),
                ),
                SizedBox(height: spacing.lg),
                ElevatedButton(
                  onPressed: () => _finish(
                      KnotBirthTransitionOutcome.fallback, 'missing_knot'),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        KnotBirthExperienceWidget(
          knot: _knot!,
          onComplete: () {
            _finish(
                KnotBirthTransitionOutcome.completed, 'experience_complete');
          },
          autoDismiss: false,
        ),
        Positioned(
          top: 48,
          right: 16,
          child: TextButton.icon(
            onPressed: () => _finish(
                KnotBirthTransitionOutcome.skipped, 'user_skip_experience'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.black.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
            ),
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip'),
          ),
        ),
      ],
    );
  }
}
