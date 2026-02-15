import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/controllers/business_onboarding_controller.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/pages/business/business_dashboard_page.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Business Onboarding Page
///
/// Multi-step onboarding flow for new business accounts.
/// Similar to user onboarding but tailored for businesses.
class BusinessOnboardingPage extends StatefulWidget {
  final BusinessAccount businessAccount;

  const BusinessOnboardingPage({
    super.key,
    required this.businessAccount,
  });

  @override
  State<BusinessOnboardingPage> createState() => _BusinessOnboardingPageState();
}

class _BusinessOnboardingPageState extends State<BusinessOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Onboarding data
  // ignore: unused_field
  final Map<String, dynamic> _expertPreferences = {};
  // ignore: unused_field - Reserved for future patron preferences
  final Map<String, dynamic> _patronPreferences = {};
  final List<String> _teamMembers = [];
  bool _setupSharedAgent = true;
  bool _isCompleting = false;

  late BusinessOnboardingController _onboardingController;

  final List<OnboardingStep> _steps = [
    const OnboardingStep(
      title: 'Welcome',
      description: 'Let\'s set up your business profile',
    ),
    const OnboardingStep(
      title: 'Expert Preferences',
      description: 'What experts do you want to connect with?',
    ),
    const OnboardingStep(
      title: 'Customer Preferences',
      description: 'What customers are you looking for?',
    ),
    const OnboardingStep(
      title: 'Team Setup',
      description: 'Invite team members (optional)',
    ),
    const OnboardingStep(
      title: 'AI Agent Setup',
      description: 'Set up your shared business AI agent',
    ),
    const OnboardingStep(
      title: 'Complete',
      description: 'You\'re all set!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _onboardingController = di.sl<BusinessOnboardingController>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return; // Prevent duplicate submissions

    setState(() {
      _isCompleting = true;
    });

    try {
      // Prepare onboarding data
      // Note: Currently _expertPreferences and _patronPreferences are Maps
      // In a full implementation, these would be converted to BusinessExpertPreferences
      // and BusinessPatronPreferences objects
      final data = BusinessOnboardingData(
        expertPreferences:
            null, // TODO: Convert _expertPreferences to BusinessExpertPreferences
        patronPreferences:
            null, // TODO: Convert _patronPreferences to BusinessPatronPreferences
        teamMembers: _teamMembers.isEmpty ? null : _teamMembers,
        setupSharedAgent: _setupSharedAgent,
      );

      // Complete onboarding via controller
      final result = await _onboardingController.completeBusinessOnboarding(
        businessId: widget.businessAccount.id,
        data: data,
      );

      if (mounted) {
        if (result.success) {
          // Show success message if there's a warning (partial success)
          if (result.warning != null) {
            context.showWarning(result.warning!);
          }

          // Navigate to dashboard
          AppNavigator.replaceBuilder(
            context,
            builder: (context) => const BusinessDashboardPage(),
          );
        } else {
          // Show error message
          context.showError('Error completing onboarding: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: _steps[_currentStep].title,
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      leading: _currentStep > 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
            )
          : null,
      automaticallyImplyLeading: false,
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(kSpaceMd),
            child: Row(
              children: List.generate(
                _steps.length,
                (index) => Expanded(
                  child: SizedBox(
                    height: 4,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: kSpaceNano),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ColoredBox(
                          color: index <= _currentStep
                              ? AppTheme.primaryColor
                              : AppColors.grey300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomeStep(),
                _buildExpertPreferencesStep(),
                _buildPatronPreferencesStep(),
                _buildTeamSetupStep(),
                _buildAIAgentSetupStep(),
                _buildCompleteStep(),
              ],
            ),
          ),

          // Navigation buttons
          PortalSurface(
            padding: const EdgeInsets.all(kSpaceMd),
            color: AppColors.white,
            radius: 0,
            elevation: 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _previousStep,
                    child: Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed:
                      (_currentStep == _steps.length - 1 && _isCompleting)
                          ? null
                          : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: _currentStep == _steps.length - 1 && _isCompleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == _steps.length - 1
                              ? 'Complete'
                              : 'Next',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business_center,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome, ${widget.businessAccount.name}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your business profile to help you connect with the right experts and customers.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpertPreferencesStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What experts are you looking for?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about the expertise you need for your business',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          // TODO: Add expert preferences form
          Expanded(
            child: Center(
              child: Text(
                'Expert preferences form coming soon',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatronPreferencesStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What customers are you looking for?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe your ideal customers and patrons',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          // TODO: Add patron preferences form
          Expanded(
            child: Center(
              child: Text(
                'Patron preferences form coming soon',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite Team Members',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add team members to your business account (optional)',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          // TODO: Add team member invitation form
          Expanded(
            child: Center(
              child: Text(
                'Team member invitation coming soon',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAgentSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Up Shared AI Agent',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your business will have a shared AI agent that learns from all team members',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PortalSurface(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: Text('Enable Shared AI Agent'),
              subtitle: Text(
                'All team members will contribute to a shared business personality',
              ),
              value: _setupSharedAgent,
              onChanged: (value) {
                setState(() {
                  _setupSharedAgent = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_setupSharedAgent)
            PortalSurface(
              padding: const EdgeInsets.all(kSpaceMd),
              color: AppColors.success.withValues(alpha: 0.1),
              borderColor: AppColors.success.withValues(alpha: 0.3),
              radius: 8,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your shared agent will learn from all team member interactions and create a unified business personality for better matching.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.success,
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re All Set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your business account is ready. Start connecting with experts and growing your business!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;

  const OnboardingStep({
    required this.title,
    required this.description,
  });
}
