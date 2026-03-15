import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/onboarding/social_media_connection_page.dart';
import 'package:avrai/presentation/widgets/common/app_button_primary.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/controllers/onboarding_flow_controller.dart';
import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';

enum _BhamOnboardingStep {
  questionnaire,
  consent,
  permissions,
  bridges,
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const Map<String, String> _questionPrompts = <String, String>{
    'more_of': 'What do you want more of right now?',
    'less_of': 'What do you want less of right now?',
    'values': 'What matters most to you these days?',
    'interests': 'What are you naturally drawn to?',
    'fun': 'What do you do for fun, or wish you did more often?',
    'favorite_places':
        'Name a few places, kinds of places, or vibes you already enjoy.',
    'goals': 'What are you working toward right now?',
    'transportation': 'How do you usually get around?',
    'spending': 'What kind of spending feels right for a normal plan?',
    'bio': 'Tell AVRAI anything you want it to know about you.',
  };

  static const Map<String, String> _questionHelpers = <String, String>{
    'more_of':
        'Examples: better routines, more time outside, more friends, more fun, more creativity, more peace, more movement, more good food, more events.',
    'less_of':
        'Examples: boredom, isolation, wasted time, stress, bad nights out, expensive plans, feeling stuck.',
    'values': 'Pick or describe your values in your own words.',
    'interests':
        'Think in terms of interests, scenes, hobbies, environments, communities, and experiences.',
    'fun': 'This can be specific or broad.',
    'favorite_places':
        'They can be restaurants, cafes, parks, venues, neighborhoods, events, clubs, communities, or anything else.',
    'goals':
        'Personal, social, creative, health, career, spiritual, or anything else.',
    'transportation':
        'Examples: walking, driving, biking, rideshare, transit, mixed.',
    'spending': 'This is about spending preference, not exact finances.',
    'bio':
        'Where you spend time, what you care about, what you like doing, who you like being around, what you want life to feel like. Share only what you want to share.',
  };

  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _permissionStates = <String, bool>{
    'location': false,
    'background_location': false,
    'bluetooth': false,
    'notifications': false,
  };

  _BhamOnboardingStep _currentStep = _BhamOnboardingStep.questionnaire;
  String? _socialEnergy;
  bool _betaConsentAccepted = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isCompleting = false;
  bool _checkingDevice = true;
  bool _deviceApproved = true;
  List<String> _deviceGateReasons = const <String>[];
  Map<String, bool> _connectedSocialPlatforms = <String, bool>{
    'Spotify': false,
    'Instagram': false,
    'Facebook': false,
    'Google': false,
    'Apple': false,
    'Strava': false,
  };

  @override
  void initState() {
    super.initState();
    for (final key in _questionPrompts.keys) {
      _controllers[key] = TextEditingController();
    }
    _checkDeviceEligibility();
    _refreshPermissionSnapshot();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkDeviceEligibility() async {
    final caps = await DeviceCapabilityService().getCapabilities();
    final evaluation = BhamBetaDefaults.evaluateApprovedDevice(caps);
    if (!mounted) return;
    setState(() {
      _checkingDevice = false;
      _deviceApproved = evaluation.approved;
      _deviceGateReasons = evaluation.reasons;
    });
  }

  Future<void> _refreshPermissionSnapshot() async {
    final permissions = <String, Permission>{
      'location': Permission.locationWhenInUse,
      'background_location': Permission.locationAlways,
      'bluetooth': Permission.bluetooth,
      'notifications': Permission.notification,
    };
    final statuses = <String, bool>{};
    for (final entry in permissions.entries) {
      final status = await entry.value.status;
      statuses[entry.key] = status.isGranted || status.isLimited;
    }

    if (!mounted) return;
    setState(() {
      _permissionStates
        ..clear()
        ..addAll(statuses);
    });
  }

  Future<void> _requestRecommendedPermissions() async {
    await <Permission>[
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();
    await _refreshPermissionSnapshot();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }

    setState(() => _isCompleting = true);

    try {
      if (_termsAccepted) {
        await GetIt.instance<LegalDocumentService>()
            .acceptTermsOfService(userId: authState.user.id);
      }
      if (_privacyAccepted) {
        await GetIt.instance<LegalDocumentService>()
            .acceptPrivacyPolicy(userId: authState.user.id);
      }

      final onboardingData = OnboardingData(
        agentId: '',
        homebase: BhamBetaDefaults.defaultHomebase,
        openResponses: _collectResponses(),
        socialMediaConnected: _connectedSocialPlatforms,
        completedAt: DateTime.now().toUtc(),
        tosAccepted: _termsAccepted,
        privacyAccepted: _privacyAccepted,
        betaConsentAccepted: _betaConsentAccepted,
        betaConsentVersion: BhamBetaDefaults.betaConsentVersion,
        questionnaireVersion: BhamBetaDefaults.questionnaireVersion,
        permissionStates: Map<String, bool>.from(_permissionStates),
      );

      final result = await di.sl<OnboardingFlowController>().completeOnboarding(
            data: onboardingData,
            userId: authState.user.id,
          );

      if (!mounted) return;

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Could not save onboarding'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isCompleting = false);
        return;
      }

      context.go(
        '/ai-loading',
        extra: <String, dynamic>{
          'userName': authState.user.name,
          'homebase': BhamBetaDefaults.defaultHomebase,
          'openResponses': _collectResponses(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('We could not finish BHAM onboarding: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Map<String, String> _collectResponses() {
    return <String, String>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      'social_energy': _socialEnergy ?? '',
    };
  }

  bool _canProceed() {
    switch (_currentStep) {
      case _BhamOnboardingStep.questionnaire:
        return BhamBetaDefaults.mandatoryQuestionKeys.every(
          (key) => _collectResponses()[key]?.trim().isNotEmpty ?? false,
        );
      case _BhamOnboardingStep.consent:
        return _betaConsentAccepted && _termsAccepted && _privacyAccepted;
      case _BhamOnboardingStep.permissions:
        return true;
      case _BhamOnboardingStep.bridges:
        return true;
    }
  }

  void _goNext() {
    if (!_canProceed() || _isCompleting) return;
    switch (_currentStep) {
      case _BhamOnboardingStep.questionnaire:
        setState(() => _currentStep = _BhamOnboardingStep.consent);
        break;
      case _BhamOnboardingStep.consent:
        setState(() => _currentStep = _BhamOnboardingStep.permissions);
        break;
      case _BhamOnboardingStep.permissions:
        setState(() => _currentStep = _BhamOnboardingStep.bridges);
        break;
      case _BhamOnboardingStep.bridges:
        _completeOnboarding();
        break;
    }
  }

  void _goBack() {
    if (_isCompleting) return;
    switch (_currentStep) {
      case _BhamOnboardingStep.questionnaire:
        context.go('/login');
        break;
      case _BhamOnboardingStep.consent:
        setState(() => _currentStep = _BhamOnboardingStep.questionnaire);
        break;
      case _BhamOnboardingStep.permissions:
        setState(() => _currentStep = _BhamOnboardingStep.consent);
        break;
      case _BhamOnboardingStep.bridges:
        setState(() => _currentStep = _BhamOnboardingStep.permissions);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingDevice) {
      return const AppFlowScaffold(
        title: '',
        showNavigationBar: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_deviceApproved) {
      return AppFlowScaffold(
        title: '',
        showNavigationBar: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppSurface(
              borderColor: AppColors.borderSubtle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This device is not approved for the Birmingham beta yet.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  for (final reason in _deviceGateReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $reason',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppFlowScaffold(
      title: '',
      showNavigationBar: false,
      constrainBody: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      _titleForStep(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: (_currentStep.index + 1) /
                    _BhamOnboardingStep.values.length,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepBody(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButtonPrimary(
                onPressed: _canProceed() && !_isCompleting ? _goNext : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _currentStep == _BhamOnboardingStep.bridges
                        ? (_isCompleting
                            ? 'Building your knot...'
                            : 'Build your knot')
                        : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForStep() {
    switch (_currentStep) {
      case _BhamOnboardingStep.questionnaire:
        return 'Birmingham beta questionnaire';
      case _BhamOnboardingStep.consent:
        return 'Birmingham beta consent';
      case _BhamOnboardingStep.permissions:
        return 'Help AVRAI work the way it was built to';
      case _BhamOnboardingStep.bridges:
        return 'Optional bridges';
    }
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_currentStep) {
      case _BhamOnboardingStep.questionnaire:
        return _QuestionnaireStep(
          controllers: _controllers,
          socialEnergy: _socialEnergy,
          onSocialEnergyChanged: (value) =>
              setState(() => _socialEnergy = value),
        );
      case _BhamOnboardingStep.consent:
        return _ConsentStep(
          betaConsentAccepted: _betaConsentAccepted,
          termsAccepted: _termsAccepted,
          privacyAccepted: _privacyAccepted,
          onBetaConsentChanged: (value) =>
              setState(() => _betaConsentAccepted = value),
          onTermsChanged: (value) => setState(() => _termsAccepted = value),
          onPrivacyChanged: (value) => setState(() => _privacyAccepted = value),
        );
      case _BhamOnboardingStep.permissions:
        return _PermissionsStep(
          permissionStates: _permissionStates,
          onRequestPermissions: _requestRecommendedPermissions,
        );
      case _BhamOnboardingStep.bridges:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional bridges are explicit skip-or-connect steps in the BHAM beta. Skipping does not block onboarding.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            SocialMediaConnectionPage(
              connectedPlatforms: _connectedSocialPlatforms,
              isOnboarding: true,
              onConnectionsChanged: (connections) {
                setState(() {
                  _connectedSocialPlatforms = connections;
                });
              },
            ),
          ],
        );
    }
  }
}

class _QuestionnaireStep extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final String? socialEnergy;
  final ValueChanged<String?> onSocialEnergyChanged;

  const _QuestionnaireStep({
    required this.controllers,
    required this.socialEnergy,
    required this.onSocialEnergyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer the 11 direct BHAM prompts exactly once. This is the full questionnaire for the first slice.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 24),
        for (final entry in _OnboardingPageState._questionPrompts.entries) ...[
          _QuestionField(
            prompt: entry.value,
            helperText: _OnboardingPageState._questionHelpers[entry.key]!,
            controller: controllers[entry.key]!,
            maxLines: entry.key == 'bio' ? 5 : 3,
          ),
          const SizedBox(height: 16),
        ],
        AppSurface(
          borderColor: AppColors.borderSubtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which feels most like you?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you more introverted, more extroverted, or somewhere in the middle?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'More introverted',
                    label: Text('More introverted'),
                  ),
                  ButtonSegment<String>(
                    value: 'Somewhere in the middle',
                    label: Text('In the middle'),
                  ),
                  ButtonSegment<String>(
                    value: 'More extroverted',
                    label: Text('More extroverted'),
                  ),
                ],
                selected: socialEnergy == null
                    ? const <String>{}
                    : <String>{socialEnergy!},
                emptySelectionAllowed: true,
                onSelectionChanged: (selection) {
                  onSocialEnergyChanged(
                    selection.isEmpty ? null : selection.first,
                  );
                },
                multiSelectionEnabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  final bool betaConsentAccepted;
  final bool termsAccepted;
  final bool privacyAccepted;
  final ValueChanged<bool> onBetaConsentChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;

  const _ConsentStep({
    required this.betaConsentAccepted,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.onBetaConsentChanged,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ConsentSection(
          title: 'What AVRAI is doing in beta',
          body:
              'AVRAI is learning from your real-world behavior, your app behavior, your saved choices, your optional connected data, and agent-to-agent exchange through the AI2AI network. The goal is to help you find better spots, lists, events, clubs, and communities in real life.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'What stays private',
          body:
              'Your direct human identity is not shown to admin by default. Names, phone numbers, addresses, social handles, and linked account identity are protected and are not supposed to appear in normal admin views.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'What admin can see',
          body:
              'Because this is a supervised beta, the secure admin app can see agent-level learning, kernel state, tuples, recommendation behavior, locality flow, AI2AI activity, and safety/governance information. This is how the system is kept safe and improved during beta.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Air gap',
          body:
              'Anything that moves between devices or into oversight surfaces is supposed to move through AVRAI’s privacy filters and air-gap boundaries. You will be able to tune some privacy strength settings later, but beta supervision remains part of the system.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Break-glass cases',
          body:
              'If AVRAI detects dangerous, malicious, illegal, trust-breaking, or hacking behavior, a human admin may use break-glass review to investigate and protect the system and the people in it. AI cannot break glass by itself.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Offline-first meaning',
          body:
              'Offline-first does not only mean single-device mode. AVRAI can still learn and exchange through on-device intelligence and AI2AI local transport even without internet service. Internet is a secondary aid, not the only path.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Your controls',
          body:
              'You will be able to adjust permissions, bridges, notification settings, matching settings, and privacy strength settings later. Some supervision and sharing behavior remain necessary for this beta to function and improve safely.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Work-in-progress truth',
          body:
              'This beta is not promising perfection. Recommendations, place vibes, locality understanding, and social fit will improve over time. Your honest feedback and real-world behavior help the system get better.',
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: betaConsentAccepted,
          onChanged: (value) => onBetaConsentChanged(value ?? false),
          title: const Text(
            'I understand that this is a supervised Birmingham beta, that AVRAI learns from my behavior and agent activity, and that admin can see agent-level learning without my direct personal identity by default.',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: termsAccepted,
          onChanged: (value) => onTermsChanged(value ?? false),
          title: const Text('I accept the Terms of Service.'),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: privacyAccepted,
          onChanged: (value) => onPrivacyChanged(value ?? false),
          title: const Text('I accept the Privacy Policy.'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  final Map<String, bool> permissionStates;
  final Future<void> Function() onRequestPermissions;

  const _PermissionsStep({
    required this.permissionStates,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'These permissions help your personal agent learn from real life and help the AI2AI network work without depending on the internet. You can review them now and adjust them later.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 24),
        const _ConsentSection(
          title: 'Location',
          body:
              'Location helps AVRAI understand what part of Birmingham you are actually living in and what doors are around you.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Background location',
          body:
              'Background location helps AVRAI learn routines, context shifts, dwell, and real-world follow-through without needing constant phone interaction.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Bluetooth',
          body:
              'Bluetooth is a core AI2AI transport for nearby exchange. Without it, the nearby network is weaker.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Calendar',
          body:
              'Calendar helps AVRAI understand what you commit to, save, and follow through on.',
        ),
        const SizedBox(height: 16),
        const _ConsentSection(
          title: 'Health/activity',
          body:
              'Health and activity signals help AVRAI understand movement, energy, and real-world behavior more accurately.',
        ),
        const SizedBox(height: 24),
        for (final entry in permissionStates.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${entry.key}: ${entry.value ? 'granted or limited' : 'not granted'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRequestPermissions,
          child: const Text('Review recommended permissions'),
        ),
        const SizedBox(height: 12),
        Text(
          'Minimum usable permissions for this slice are explicit but not dead-end gating. You can continue with your current permission state and adjust later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _ConsentSection extends StatelessWidget {
  final String title;
  final String body;

  const _ConsentSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  final String prompt;
  final String helperText;
  final TextEditingController controller;
  final int maxLines;

  const _QuestionField({
    required this.prompt,
    required this.helperText,
    required this.controller,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Type your answer',
            ),
          ),
        ],
      ),
    );
  }
}
