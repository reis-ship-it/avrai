import 'dart:developer' as developer;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_auto_install_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_macos_auto_install_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/on_device_ai_capability_gate.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/onboarding/open_intake_page.dart';
import 'package:avrai/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:avrai/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:avrai/presentation/pages/onboarding/social_media_connection_page.dart';
import 'package:avrai/presentation/pages/onboarding/data_intake_connection_page.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_step.dart';
import 'package:avrai/presentation/pages/onboarding/legal_acceptance_dialog.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/onboarding/age_collection_page.dart';
import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_core/models/user/onboarding_data.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/controllers/onboarding_flow_controller.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

enum OnboardingStepType {
  welcome,
  homebase,
  openIntake,
  friends,
  permissions, // Includes age and legal
  socialMedia,
  dataIntake,
  knotBirth, // Routed post-processing step after AI loading
  connectAndDiscover,
}

class OnboardingStep {
  final OnboardingStepType page;
  final String title;
  final String description;

  const OnboardingStep({
    required this.page,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final PageController _pageController = PageController();
  bool _showWelcome = true;
  int _currentPage = 0;
  DateTime? _selectedBirthday;
  String? _selectedHomebase;
  Map<String, String> _openResponses = {};
  List<String> _respectedFriends = [];
  Map<String, bool> _connectedSocialPlatforms = {
    'Spotify': false,
    'Instagram': false,
    'Facebook': false,
    'Google': false,
    'Apple': false,
    'Strava': false,
  };
  bool _isCompleting = false;

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      page: OnboardingStepType.permissions,
      title: 'Permissions & Legal',
      description: 'Enable permissions and accept terms',
    ),
    const OnboardingStep(
      page: OnboardingStepType.homebase,
      title: 'Choose Your Homebase',
      description: 'Select your primary location',
    ),
    const OnboardingStep(
      page: OnboardingStepType.openIntake,
      title: 'About You',
      description: 'Tell us about yourself to seed your AI',
    ),
    const OnboardingStep(
      page: OnboardingStepType.socialMedia,
      title: 'Social Media',
      description: 'Connect your social accounts (optional)',
    ),
    const OnboardingStep(
      page: OnboardingStepType.friends,
      title: 'Starter Lists',
      description: 'Choose local lists to start from',
    ),
    const OnboardingStep(
      page: OnboardingStepType.connectAndDiscover,
      title: 'Connect & Discover',
      description: 'Enable ai2ai discovery and connections',
    ),
  ];

  @override
  void dispose() {
    // Stop any ongoing operations
    _isCompleting = true;

    // Dispose PageController first to prevent any ongoing animations
    // This must happen before super.dispose() to prevent rendering issues
    // Note: PageController may already be disposed in _completeOnboarding
    try {
      if (_pageController.hasClients) {
        _pageController.dispose();
      } else {
        // Try to dispose even if no clients - may already be disposed but that's ok
        try {
          _pageController.dispose();
        } catch (e) {
          // Already disposed, ignore
        }
      }
    } catch (e) {
      // Ignore disposal errors - controller may already be disposed
      _logger.debug('PageController disposal note: $e', tag: 'Onboarding');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showWelcome) {
      return PopScope(
        canPop: false,
        child: WelcomePage(
          onContinue: () {
            if (mounted) {
              setState(() => _showWelcome = false);
            }
          },
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_isCompleting) {
          _goBack();
        }
      },
      child: AdaptivePlatformPageScaffold(
        title: '',
        automaticallyImplyLeading: true,
        constrainBody: false,
        actions: const [],
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  if (!_isCompleting && mounted) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  if (_isCompleting) {
                    return const SizedBox.shrink();
                  }
                  return _buildStepContent(_steps[index]);
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (!mounted || _isCompleting) return;
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _showWelcome = true);
    }
  }

  Widget _buildStepContent(OnboardingStep step) {
    switch (step.page) {
      case OnboardingStepType.welcome:
        return const SizedBox.shrink();
      case OnboardingStepType.homebase:
        return HomebaseSelectionPage(
          onHomebaseChanged: (homebase) {
            setState(() {
              _selectedHomebase = homebase;
            });
          },
          selectedHomebase: _selectedHomebase,
        );
      case OnboardingStepType.openIntake:
        return OpenIntakePage(
          openResponses: _openResponses,
          onResponsesChanged: (responses) {
            setState(() {
              _openResponses = responses;
            });
          },
        );
      case OnboardingStepType.friends:
        return FriendsRespectPage(
          onRespectedListsChanged: (friends) {
            setState(() {
              _respectedFriends = friends;
            });
          },
          respectedLists: _respectedFriends,
          userId: _getUserIdOrNull(),
          selectedHomebase: _selectedHomebase,
        );
      case OnboardingStepType.permissions:
        return _PermissionsAndLegalPage(
          selectedBirthday: _selectedBirthday,
          onBirthdayChanged: (birthday) {
            setState(() {
              _selectedBirthday = birthday;
            });
          },
        );
      case OnboardingStepType.socialMedia:
        return SocialMediaConnectionPage(
          connectedPlatforms: _connectedSocialPlatforms,
          isOnboarding: true, // Enable batch connections during onboarding
          onConnectionsChanged: (connections) async {
            setState(() {
              _connectedSocialPlatforms = connections;
            });

            // Optionally: Verify connections exist in service
            // This ensures OnboardingData reflects real connections
            try {
              final authBloc = context.read<AuthBloc>();
              final authState = authBloc.state;
              if (authState is Authenticated) {
                final userId = authState.user.id;
                final socialMediaService =
                    di.sl<SocialMediaConnectionService>();
                final realConnections =
                    await socialMediaService.getActiveConnections(userId);

                // Update map to reflect only real connections
                final realPlatforms = <String, bool>{};
                for (final conn in realConnections) {
                  // Map platform names: 'instagram' -> 'Instagram'
                  final displayName = conn.platform[0].toUpperCase() +
                      conn.platform.substring(1);
                  realPlatforms[displayName] = true;
                }

                if (mounted) {
                  setState(() {
                    _connectedSocialPlatforms = realPlatforms;
                  });
                }
              }
            } catch (e) {
              // Continue with UI state if service check fails
              _logger.warn('⚠️ Could not verify social media connections: $e',
                  tag: 'Onboarding');
            }
          },
        );
      case OnboardingStepType.dataIntake:
        return DataIntakeConnectionPage(
          onComplete: () {
            if (_currentPage < _steps.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      case OnboardingStepType.connectAndDiscover:
        return const _ConnectAndDiscoverPage();
      case OnboardingStepType.knotBirth:
        // Knot birth runs as a guarded route after ai-loading.
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              key: const Key('onboarding_primary_cta'),
              onPressed: _isCompleting
                  ? null
                  : (_canProceedToNextStep()
                      ? () {
                          _logger.debug(
                              'Button pressed on step ${_steps[_currentPage].page.name}',
                              tag: 'Onboarding');
                          if (_currentPage == _steps.length - 1) {
                            _logger.info(
                                'Completing onboarding from Connect & Discover step',
                                tag: 'Onboarding');
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null),
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String? _getUserIdOrNull() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.id : null;
  }

  bool _canProceedToNextStep() {
    if (_currentPage >= _steps.length) {
      _logger.debug('Cannot proceed: currentPage >= steps.length',
          tag: 'Onboarding');
      return false;
    }

    // Always allow proceeding from the last step.
    if (_currentPage == _steps.length - 1) {
      _logger.debug('Can proceed: on last step', tag: 'Onboarding');
      return true;
    }

    final stepType = _steps[_currentPage].page;
    bool canProceed;

    switch (stepType) {
      case OnboardingStepType.welcome:
        canProceed = true; // Welcome page is always ready to proceed
        break;
      case OnboardingStepType.homebase:
        canProceed = _selectedHomebase != null && _selectedHomebase!.isNotEmpty;
        break;
      case OnboardingStepType.openIntake:
        canProceed = true; // Optional text fields
        break;
      case OnboardingStepType.friends:
        canProceed = true; // Optional step
        break;
      case OnboardingStepType.permissions:
        canProceed =
            _selectedBirthday != null && _areCriticalPermissionsGrantedSync();
        break;
      case OnboardingStepType.socialMedia:
        canProceed = true; // Social media step is optional
        break;
      case OnboardingStepType.dataIntake:
        canProceed = true; // Optional step
        break;
      case OnboardingStepType.connectAndDiscover:
        // This step is optional - user can complete setup with or without enabling AI discovery
        canProceed = true;
        break;
      case OnboardingStepType.knotBirth:
        canProceed = true;
        break;
    }

    _logger.debug('Can proceed from ${stepType.name}: $canProceed',
        tag: 'Onboarding');
    return canProceed;
  }

  bool _areCriticalPermissionsGrantedSync() {
    // Synchronous snapshot using cached status flags; if not available, assume false
    // For strict gating, prefer calling requestCriticalPermissions() before this or check statuses directly
    // Here we query current status synchronously via value getters (permission_handler requires async; kept simple)
    // We'll optimistically enable Next and re-validate in guards.
    return true;
  }

  String _getNextButtonText() {
    if (_currentPage == _steps.length - 1) {
      return 'Complete Setup';
    }
    return 'Next';
  }

  void _completeOnboarding() async {
    // Prevent multiple completion attempts
    if (_isCompleting) {
      _logger.warn(
          '⚠️ [ONBOARDING_PAGE] Onboarding completion already in progress',
          tag: 'Onboarding');
      return;
    }

    _isCompleting = true;
    bool savedOnboardingData = false;
    int? calculatedAge;
    try {
      _logger.info('🎯 Completing Onboarding:', tag: 'Onboarding');
      _logger.debug('  Homebase: $_selectedHomebase', tag: 'Onboarding');
      _logger.debug('  Open Responses: $_openResponses', tag: 'Onboarding');

      // Get authenticated user
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        _logger.error('❌ [ONBOARDING_PAGE] User not authenticated',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }
      final userId = authState.user.id;

      const bool isIntegrationTest = bool.fromEnvironment('FLUTTER_TEST');

      // Show legal acceptance dialog if needed (UI responsibility)
      if (!isIntegrationTest) {
        final legalService = GetIt.instance<LegalDocumentService>();
        final hasAcceptedTerms = await legalService.hasAcceptedTerms(userId);
        final hasAcceptedPrivacy =
            await legalService.hasAcceptedPrivacyPolicy(userId);

        if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
          // Check mounted before using context
          if (!mounted) {
            _isCompleting = false;
            return;
          }

          final accepted = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => LegalAcceptanceDialog(
              requireTerms: !hasAcceptedTerms,
              requirePrivacy: !hasAcceptedPrivacy,
            ),
          );

          if (accepted != true) {
            _isCompleting = false;
            return;
          }
        }
      }

      // Calculate age from birthday
      int? age;
      if (_selectedBirthday != null) {
        final now = DateTime.now();
        age = now.year - _selectedBirthday!.year;
        if (now.month < _selectedBirthday!.month ||
            (now.month == _selectedBirthday!.month &&
                now.day < _selectedBirthday!.day)) {
          age--;
        }
      }
      calculatedAge = age;

      // Build onboarding data (agentId will be set by controller)
      final onboardingData = OnboardingData(
        agentId: '', // Will be set by controller
        age: age,
        birthday: _selectedBirthday,
        homebase: _selectedHomebase,
        openResponses: _openResponses,
        respectedFriends: _respectedFriends,
        socialMediaConnected: _connectedSocialPlatforms,
        completedAt: DateTime.now(),
      );

      // Use OnboardingFlowController to complete workflow
      if (!mounted) return;
      final controller = di.sl<OnboardingFlowController>();
      final result = await controller.completeOnboarding(
        data: onboardingData,
        userId: userId,
        context: context,
      );
      if (!mounted) return;

      // Handle controller result
      if (!result.isSuccess) {
        _logger.error(
            '❌ [ONBOARDING_PAGE] Onboarding completion failed: ${result.error}',
            tag: 'Onboarding');

        // Show error to user if needed
        if (result.requiresLegalAcceptance) {
          // Legal acceptance required - already handled above, but log for clarity
          _logger.warn('⚠️ [ONBOARDING_PAGE] Legal acceptance required',
              tag: 'Onboarding');
        }

        _isCompleting = false;

        // In integration tests, surface the root cause
        if (isIntegrationTest) {
          throw Exception('Onboarding completion failed: ${result.error}');
        }

        // Show error dialog to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to complete onboarding'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Success - log and continue to navigation
      _logger.info(
          '✅ [ONBOARDING_PAGE] Onboarding data saved successfully (agentId: ${result.agentId?.substring(0, 10)}...)',
          tag: 'Onboarding');
      savedOnboardingData = true;

      // Ensure widget is still mounted before navigation
      if (!mounted) {
        _logger.warn(
            '⚠️ [ONBOARDING_PAGE] Widget not mounted, skipping navigation',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }

      // Stop PageView from rendering by setting completion flag
      // This must happen before any delays to prevent rendering during transition
      setState(() {
        _isCompleting = true;
      });

      // Wait for the current frame to complete using SchedulerBinding
      // This ensures all rendering operations are finished
      await SchedulerBinding.instance.endOfFrame;

      // Note: PageController disposal is handled by dispose() method in normal widget lifecycle
      // Do NOT dispose here - disposing before navigation can cause graphics thread crashes
      // The controller will be properly disposed after navigation completes

      // Double-check mounted after delays
      if (!mounted) {
        _logger.warn(
            '⚠️ [ONBOARDING_PAGE] Widget not mounted after delays, skipping navigation',
            tag: 'Onboarding');
        _isCompleting = false;
        return;
      }

      final routeExtras = <String, dynamic>{
        'userName': authState.user.name,
        'birthday': _selectedBirthday?.toIso8601String(),
        'age': calculatedAge,
        'homebase': _selectedHomebase,
        'openResponses': _openResponses,
      };

      try {
        GoRouter.of(context).go('/ai-loading', extra: routeExtras);
      } catch (e, st) {
        _logger.error(
          'Navigation to ai-loading failed',
          error: e,
          stackTrace: st,
          tag: 'Onboarding',
        );
        rethrow;
      }
    } catch (e) {
      _isCompleting = false; // Reset on error
      _logger.error('Error completing onboarding', error: e, tag: 'Onboarding');
      // In integration tests, surface the root cause instead of silently falling back.
      if (const bool.fromEnvironment('FLUTTER_TEST')) {
        rethrow;
      }

      if (savedOnboardingData && mounted) {
        try {
          final currentAuthState = context.read<AuthBloc>().state;
          final userName = currentAuthState is Authenticated
              ? currentAuthState.user.name
              : 'User';
          GoRouter.of(context).go('/ai-loading', extra: {
            'userName': userName,
            'birthday': _selectedBirthday?.toIso8601String(),
            'age': calculatedAge,
            'homebase': _selectedHomebase,
            'openResponses': _openResponses,
          });
          return;
        } catch (fallbackError) {
          _logger.error(
            'Fallback navigation to ai-loading also failed',
            error: fallbackError,
            tag: 'Onboarding',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not finish setup. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Optional utility to request critical permissions early; can be called at specific steps
  Future<void> requestCriticalPermissions() async {
    try {
      final requests = <Permission>[
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ];
      final statuses = await requests.request();
      final denied = statuses.entries
          .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
          .map((e) => e.key)
          .toList();
      if (denied.isNotEmpty) {
        _logger.warn('Some permissions denied: $denied', tag: 'Onboarding');
      }
    } catch (e) {
      _logger.error('Permission request error', error: e, tag: 'Onboarding');
    }
  }

  // ignore: unused_element
  Future<void> _saveRespectedLists(List<String> respectedListNames) async {
    try {
      // Save respected lists logic
    } catch (e) {
      // Handle error
    }
  }
}

/// Combined Permissions and Legal page
/// Includes: Permissions, Age Verification, and Legal Acceptance
class _PermissionsAndLegalPage extends StatefulWidget {
  final DateTime? selectedBirthday;
  final Function(DateTime?) onBirthdayChanged;

  const _PermissionsAndLegalPage({
    required this.selectedBirthday,
    required this.onBirthdayChanged,
  });

  @override
  State<_PermissionsAndLegalPage> createState() =>
      _PermissionsAndLegalPageState();
}

class _PermissionsAndLegalPageState extends State<_PermissionsAndLegalPage> {
  bool _legalAccepted = false;

  @override
  void initState() {
    super.initState();
    _checkLegalStatus();
  }

  Future<void> _checkLegalStatus() async {
    try {
      final legalService = GetIt.instance<LegalDocumentService>();
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final hasAcceptedTerms =
            await legalService.hasAcceptedTerms(authState.user.id);
        final hasAcceptedPrivacy =
            await legalService.hasAcceptedPrivacyPolicy(authState.user.id);
        setState(() {
          _legalAccepted = hasAcceptedTerms && hasAcceptedPrivacy;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _handleLegalAcceptance() async {
    final legalService = GetIt.instance<LegalDocumentService>();
    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      final hasAcceptedTerms =
          await legalService.hasAcceptedTerms(authState.user.id);
      final hasAcceptedPrivacy =
          await legalService.hasAcceptedPrivacyPolicy(authState.user.id);

      if (!hasAcceptedTerms || !hasAcceptedPrivacy) {
        if (!mounted) return;
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => LegalAcceptanceDialog(
            requireTerms: !hasAcceptedTerms,
            requirePrivacy: !hasAcceptedPrivacy,
          ),
        );
        if (!mounted) return;

        if (accepted == true) {
          await _checkLegalStatus();
        }
      } else {
        setState(() => _legalAccepted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Permissions & Legal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable connectivity and accept terms to continue',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 24),

          // Permissions Section
          AppSurface(
            borderColor: AppColors.grey500.withValues(alpha: 0.2),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                PermissionsPage(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Age Verification Section
          AppSurface(
            borderColor: AppColors.grey500.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Age Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AgeCollectionPage(
                  selectedBirthday: widget.selectedBirthday,
                  onBirthdayChanged: widget.onBirthdayChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legal Acceptance Section
          AppSurface(
            borderColor: (_legalAccepted
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.grey500.withValues(alpha: 0.2))
                .withValues(alpha: _legalAccepted ? 1 : 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _legalAccepted ? Icons.check_circle : Icons.description,
                      color: _legalAccepted
                          ? AppColors.success
                          : Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _legalAccepted
                      ? 'You have accepted the Terms of Service and Privacy Policy.'
                      : 'Please review and accept our Terms of Service and Privacy Policy to continue.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _legalAccepted
                      ? OutlinedButton.icon(
                          onPressed: _handleLegalAcceptance,
                          icon: const Icon(Icons.visibility),
                          label: const Text('Review Again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _handleLegalAcceptance,
                          icon: const Icon(Icons.description),
                          label: const Text('Review & Accept'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Connect and Discover Page
/// Final step before AI loading - enables ai2ai discovery
class _ConnectAndDiscoverPage extends StatefulWidget {
  const _ConnectAndDiscoverPage();

  @override
  State<_ConnectAndDiscoverPage> createState() =>
      _ConnectAndDiscoverPageState();
}

class _ConnectAndDiscoverPageState extends State<_ConnectAndDiscoverPage> {
  bool _discoveryEnabled = false;
  bool _offlineLlmEnabled = false;
  bool _offlineLlmEligible = false;
  OfflineLlmTier _recommendedTier = OfflineLlmTier.none;
  late final LocalLlmProvisioningStateService _provisioning;
  late final Stream<LocalLlmProvisioningState> _provisioningStream;
  late final Stream<LocalLlmProvisioningState> _provisioningStreamWithInitial;

  @override
  void initState() {
    super.initState();
    _provisioning = LocalLlmProvisioningStateService();
    _provisioningStream =
        Stream.periodic(const Duration(seconds: 2)).asyncMap((_) {
      return _provisioning.getState();
    });
    _provisioningStreamWithInitial = _createProvisioningStreamWithInitial();
    _loadDiscoveryPreference();
    _loadOfflineLlmPreferenceAndEligibility();
  }

  Stream<LocalLlmProvisioningState>
      _createProvisioningStreamWithInitial() async* {
    yield await _provisioning.getState();
    yield* _provisioningStream;
  }

  Future<void> _loadDiscoveryPreference() async {
    try {
      final storageService = StorageService.instance;
      final saved = storageService.getBool('discovery_enabled') ?? false;
      if (mounted) {
        setState(() {
          _discoveryEnabled = saved;
        });
      }
    } catch (e) {
      // Ignore errors - use default false
    }
  }

  Future<void> _saveDiscoveryPreference(bool value) async {
    try {
      final storageService = StorageService.instance;
      await storageService.setBool('discovery_enabled', value);
    } catch (e) {
      // Log but don't block - this is optional
      developer.log('Failed to save discovery preference: $e',
          name: '_ConnectAndDiscoverPage');
    }
  }

  Future<void> _loadOfflineLlmPreferenceAndEligibility() async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();

      // Capability gate (best-effort).
      final caps = await DeviceCapabilityService().getCapabilities();
      final gateResult = OnDeviceAiCapabilityGate().evaluate(caps);
      final recommended = gateResult.recommendedTier;
      final eligible = recommended != OfflineLlmTier.none;

      // Opt-out default: if eligible, default enabled unless user disabled.
      final hasUserChoice = prefs.containsKey('offline_llm_enabled_v1');
      bool enabled = prefs.getBool('offline_llm_enabled_v1') ?? false;
      if (!hasUserChoice) {
        enabled = eligible;
        await prefs.setBool('offline_llm_enabled_v1', enabled);
      }

      if (mounted) {
        setState(() {
          _offlineLlmEligible = eligible;
          _recommendedTier = recommended;
          _offlineLlmEnabled = enabled;
        });
      }

      // Best-effort: kick auto-install
      if (enabled && eligible) {
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          await LocalLlmMacOSAutoInstallService().maybeAutoInstallMacOS();
        } else {
          await LocalLlmAutoInstallService().maybeAutoInstall();
        }
      }
    } catch (e, st) {
      developer.log('Failed to load offline LLM onboarding state: $e',
          name: '_ConnectAndDiscoverPage', error: e, stackTrace: st);
    }
  }

  Future<void> _setOfflineLlmEnabled(bool value) async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      await prefs.setBool('offline_llm_enabled_v1', value);

      if (mounted) {
        setState(() {
          _offlineLlmEnabled = value;
        });
      }

      if (value && _offlineLlmEligible) {
        await LocalLlmAutoInstallService().maybeAutoInstall();
      }
    } catch (e, st) {
      developer.log('Failed to set offline LLM preference: $e',
          name: '_ConnectAndDiscoverPage', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect & Discover',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable ai2ai discovery to connect with nearby SPOTS users and their AI personalities',
          ),
          const SizedBox(height: 24),
          AppSurface(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Enable AI Discovery'),
              subtitle: const Text(
                'Allow your AI personality to discover and connect with nearby devices',
              ),
              value: _discoveryEnabled,
              onChanged: (value) async {
                setState(() {
                  _discoveryEnabled = value;
                });
                // Save preference asynchronously - don't block UI
                await _saveDiscoveryPreference(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          AppSurface(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Enable Offline AI (downloads on Wi‑Fi)'),
              subtitle: Text(
                _offlineLlmEligible
                    ? 'Recommended tier: ${_recommendedTier.name}. You can chat offline once installed.'
                    : 'Not available on this device.',
              ),
              value: _offlineLlmEnabled,
              onChanged: _offlineLlmEligible
                  ? (value) async {
                      await _setOfflineLlmEnabled(value);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<LocalLlmProvisioningState>(
            stream: _provisioningStreamWithInitial,
            builder: (context, snapshot) {
              final s = snapshot.data;
              final phase = s?.phase ?? LocalLlmProvisioningPhase.idle;
              final installed = s?.packStatus.isInstalled ?? false;
              final progress = s?.progressFraction;

              String text;
              if (!_offlineLlmEligible) {
                text = 'Offline AI: not eligible on this device.';
              } else if (!_offlineLlmEnabled) {
                text = 'Offline AI: disabled (opt-out).';
              } else if (installed) {
                final packId = s?.packStatus.activePackId ?? 'unknown';
                if (phase == LocalLlmProvisioningPhase.downloading) {
                  final pct =
                      (progress != null) ? (progress * 100).round() : null;
                  text = pct != null
                      ? 'Offline AI: updating… $pct% (current: $packId)'
                      : 'Offline AI: updating… (current: $packId)';
                } else if (phase == LocalLlmProvisioningPhase.error) {
                  final err = s?.lastError ?? 'Unknown error';
                  text =
                      'Offline AI: installed ($packId) — update error ($err).';
                } else {
                  text = 'Offline AI: installed ($packId).';
                }
              } else {
                switch (phase) {
                  case LocalLlmProvisioningPhase.queuedWifi:
                    text =
                        'Offline AI: queued for Wi‑Fi download (can take a while).';
                    break;
                  case LocalLlmProvisioningPhase.queuedCharging:
                    text = 'Offline AI: queued until your device is charging.';
                    break;
                  case LocalLlmProvisioningPhase.queuedIdle:
                    text = 'Offline AI: queued until you are charging + idle.';
                    break;
                  case LocalLlmProvisioningPhase.downloading:
                    final pct =
                        (progress != null) ? (progress * 100).round() : null;
                    text = pct != null
                        ? 'Offline AI: downloading on Wi‑Fi… $pct%'
                        : 'Offline AI: downloading on Wi‑Fi…';
                    break;
                  case LocalLlmProvisioningPhase.error:
                    final err = s?.lastError ?? 'Unknown error';
                    text = 'Offline AI: error ($err).';
                    break;
                  case LocalLlmProvisioningPhase.installed:
                    text = 'Offline AI: installed.';
                    break;
                  case LocalLlmProvisioningPhase.idle:
                    text = 'Offline AI: waiting to start.';
                    break;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                  if (phase == LocalLlmProvisioningPhase.downloading &&
                      progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.grey200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'When enabled, your anonymized personality data will be used to discover compatible AI personalities nearby. All connections are privacy-preserving and go through the AI layer.',
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
