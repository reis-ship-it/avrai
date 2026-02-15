import 'dart:developer' as developer;
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/controllers/partnership_proposal_controller.dart';
import 'package:avrai/core/services/matching/partnership_matching_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// Partnership Proposal Page
///
/// Allows users to propose partnerships with businesses for events.
/// Shows AI-suggested partners (70%+ compatibility) and allows search.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipProposalPage extends StatefulWidget {
  final ExpertiseEvent event;

  const PartnershipProposalPage({
    super.key,
    required this.event,
  });

  @override
  State<PartnershipProposalPage> createState() =>
      _PartnershipProposalPageState();
}

class _PartnershipProposalPageState extends State<PartnershipProposalPage> {
  final _matchingService = GetIt.instance<PartnershipMatchingService>();
  final _businessService = GetIt.instance<BusinessService>();

  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<PartnershipSuggestion> _suggestions = [];
  List<BusinessAccount> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Defer loading suggestions until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      final suggestions = await _matchingService.findMatchingPartners(
        userId: authState.user.id,
        eventId: widget.event.id,
        minCompatibility: 0.70, // 70% threshold
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading partnership suggestions: $e',
        name: 'PartnershipProposalPage',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        context.showError('Error loading suggestions: $e');
      }
    }
  }

  Future<void> _searchBusinesses(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _businessService.findBusinesses(
        category: query.isNotEmpty ? query : null,
        verifiedOnly: true,
        maxResults: 20,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error searching businesses: $e',
        name: 'PartnershipProposalPage',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProposalForm(BusinessAccount business, double? compatibility) {
    AppNavigator.pushBuilder(
      context,
      builder: (context) => PartnershipProposalFormPage(
        event: widget.event,
        business: business,
        compatibility: compatibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Partnership Proposal',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(kSpaceMdWide),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Business Partner',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Partner with businesses to host events together',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 Search businesses...',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _searchBusinesses('');
                          },
                        )
                      : null,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                onChanged: _searchBusinesses,
              ),
            ),

            SizedBox(height: context.spacing.xl),

            // Search Results or Suggestions
            if (_searchController.text.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kSpaceMdWide),
                child: Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              SizedBox(height: context.spacing.sm),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_searchResults.isEmpty)
                Padding(
                  padding: EdgeInsets.all(kSpaceXl),
                  child: Center(
                    child: Text(
                      'No businesses found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                )
              else
                ..._searchResults.map((business) => _buildBusinessCard(
                      business,
                      null, // No compatibility score for search results
                    )),
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: kSpaceMdWide),
                child: Text(
                  'Suggested Partners (Vibe Match)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              SizedBox(height: context.spacing.sm),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_suggestions.isEmpty)
                Padding(
                  padding: EdgeInsets.all(context.spacing.xxl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: context.spacing.md),
                        Text(
                          'No suggested partners yet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          'Try searching for businesses or check back later',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._suggestions
                    .where((s) => s.business != null)
                    .map((suggestion) => _buildBusinessCard(
                          suggestion.business!,
                          suggestion.compatibility,
                        )),
            ],

            SizedBox(height: context.spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BusinessAccount business, double? compatibility) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.lg,
        vertical: context.spacing.xs,
      ),
      child: PortalSurface(
        radius: context.radius.md,
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Business Icon/Logo
                SizedBox(
                  width: 48,
                  height: 48,
                  child: business.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            business.logoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const CircleAvatar(
                          backgroundColor: Color.fromRGBO(76, 125, 255, 0.1),
                          child: Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (business.categories.isNotEmpty) ...[
                        SizedBox(height: context.spacing.xxs),
                        Text(
                          business.categories.join(', '),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (compatibility != null)
                  CompatibilityBadge(compatibility: compatibility),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // View profile
                      // TODO: Navigate to business profile
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.grey300),
                    ),
                    child: Text('View Profile'),
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showProposalForm(business, compatibility),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text('Propose'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Partnership Proposal Form Page
///
/// Form for creating a partnership proposal with terms and revenue split.
class PartnershipProposalFormPage extends StatefulWidget {
  final ExpertiseEvent event;
  final BusinessAccount business;
  final double? compatibility;

  const PartnershipProposalFormPage({
    super.key,
    required this.event,
    required this.business,
    this.compatibility,
  });

  @override
  State<PartnershipProposalFormPage> createState() =>
      _PartnershipProposalFormPageState();
}

class _PartnershipProposalFormPageState
    extends State<PartnershipProposalFormPage> {
  final _partnershipController =
      GetIt.instance<PartnershipProposalController>();
  final _formKey = GlobalKey<FormState>();

  PartnershipType _partnershipType = PartnershipType.eventBased;
  double _userPercentage = 50.0;
  double _businessPercentage = 50.0;
  final List<String> _selectedResponsibilities = [];
  final _customTermsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableResponsibilities = [
    'Provide venue',
    'Marketing support',
    'Equipment',
    'Catering',
    'Staff support',
  ];

  @override
  void dispose() {
    _customTermsController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      // Create partnership agreement with terms
      final agreement = PartnershipAgreement(
        id: 'agreement_${DateTime.now().millisecondsSinceEpoch}',
        partnershipId: '', // Will be set by service
        terms: {
          'revenueSplit': {
            'userPercentage': _userPercentage,
            'businessPercentage': _businessPercentage,
          },
          'responsibilities': _selectedResponsibilities,
        },
        customArrangementDetails: _customTermsController.text.trim().isEmpty
            ? null
            : _customTermsController.text.trim(),
        agreedAt: DateTime.now(),
        agreedBy: authState.user.id,
      );

      // Create partnership proposal using controller
      final proposalData = PartnershipProposalData(
        agreement: agreement,
        type: _partnershipType,
        sharedResponsibilities: _selectedResponsibilities,
        vibeCompatibilityScore: widget.compatibility,
      );

      final result = await _partnershipController.createProposal(
        eventId: widget.event.id,
        proposerId: authState.user.id,
        businessId: widget.business.id,
        data: proposalData,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result.success) {
          Navigator.pop(context); // Close form
          Navigator.pop(context); // Close proposal page

          context.showSuccess(
            'Partnership proposal sent to ${widget.business.name}!',
          );
        } else {
          context.showError('Error sending proposal: ${result.error}');
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error sending partnership proposal: $e',
        name: 'PartnershipProposalFormPage',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        context.showError('Error sending proposal: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Partnership Proposal',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Info
                PortalSurface(
                  padding: EdgeInsets.all(context.spacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: context.radius.xl,
                        backgroundColor: Color.fromRGBO(76, 125, 255, 0.1),
                        child: Icon(
                          Icons.business,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: context.spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.business.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            if (widget.compatibility != null) ...[
                              SizedBox(height: context.spacing.xxs),
                              CompatibilityBadge(
                                  compatibility: widget.compatibility!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.spacing.xl),

                // Partnership Type
                Text(
                  'Partnership Type',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.sm),
                RadioGroup<PartnershipType>(
                  groupValue: _partnershipType,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _partnershipType = val;
                      });
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<PartnershipType>(
                        title: Text('Co-Host (Equal partners)'),
                        subtitle: Text('Share responsibilities equally'),
                        value: PartnershipType.eventBased,
                      ),
                      RadioListTile<PartnershipType>(
                        title: Text('Venue Provider (Business venue)'),
                        subtitle: Text('Business provides venue space'),
                        value: PartnershipType.ongoing,
                      ),
                      RadioListTile<PartnershipType>(
                        title: Text('Sponsorship'),
                        subtitle: Text('Business sponsors the event'),
                        value: PartnershipType.exclusive,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.spacing.xl),

                // Revenue Split
                Text(
                  'Revenue Split',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'You',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            '${_userPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.business.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_businessPercentage.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _userPercentage,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_userPercentage.toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setState(() {
                      _userPercentage = value;
                      _businessPercentage = 100.0 - value;
                    });
                  },
                ),

                SizedBox(height: context.spacing.xl),

                // Responsibilities
                Text(
                  'Responsibilities',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.sm),
                ..._availableResponsibilities.map((responsibility) =>
                    CheckboxListTile(
                      title: Text(responsibility),
                      value: _selectedResponsibilities.contains(responsibility),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedResponsibilities.add(responsibility);
                          } else {
                            _selectedResponsibilities.remove(responsibility);
                          }
                        });
                      },
                    )),

                SizedBox(height: context.spacing.xl),

                // Custom Terms
                Text(
                  'Custom Terms (Optional)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.sm),
                TextFormField(
                  controller: _customTermsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional terms or notes...',
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),

                SizedBox(height: context.spacing.xxl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: context.spacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Send Proposal',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),

                SizedBox(height: context.spacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
