import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/events/event_safety_guidelines.dart';
import 'package:avrai/core/services/events/event_safety_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Safety Checklist Widget
///
/// Agent 2: Phase 5, Week 16-17 - Safety Checklist UI
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Checklist of safety requirements
/// - Emergency contact form
/// - Insurance recommendation display
/// - Acknowledgment checkbox
/// - Educational tooltips
class SafetyChecklistWidget extends StatefulWidget {
  final ExpertiseEvent event;
  final bool showAcknowledgment;
  final ValueChanged<bool>? onAcknowledged;
  final bool readOnly;

  const SafetyChecklistWidget({
    super.key,
    required this.event,
    this.showAcknowledgment = true,
    this.onAcknowledged,
    this.readOnly = false,
  });

  @override
  State<SafetyChecklistWidget> createState() => _SafetyChecklistWidgetState();
}

class _SafetyChecklistWidgetState extends State<SafetyChecklistWidget> {
  EventSafetyService? _safetyService;

  EventSafetyGuidelines? _guidelines;
  bool _isLoading = true;
  bool _acknowledged = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      // Some widget tests (and lightweight environments) don't register the full
      // dependency graph. Degrade gracefully instead of throwing during State
      // construction.
      final eventService = GetIt.instance<ExpertiseEventService>();
      _safetyService = EventSafetyService(eventService: eventService);
    } catch (e) {
      setState(() {
        _error = 'Safety service unavailable: $e';
        _isLoading = false;
      });
      return;
    }

    await _loadGuidelines();
  }

  Future<void> _loadGuidelines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = _safetyService;
      if (service == null) {
        throw StateError('Safety service unavailable');
      }
      final guidelines = await service.generateGuidelines(widget.event.id);
      setState(() {
        _guidelines = guidelines;
        _acknowledged = guidelines.acknowledged;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgeGuidelines() async {
    if (_guidelines == null || widget.readOnly) return;

    try {
      final service = _safetyService;
      if (service == null) {
        throw StateError('Safety service unavailable');
      }
      await service.acknowledgeGuidelines(widget.event.id);
      setState(() {
        _acknowledged = true;
        _guidelines = _guidelines!.copyWith(
          acknowledged: true,
          acknowledgedAt: DateTime.now(),
        );
      });

      if (widget.onAcknowledged != null) {
        widget.onAcknowledged!(true);
      }

      if (mounted) {
        context.showSuccess('Safety guidelines acknowledged');
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(context.spacing.md),
        margin: EdgeInsets.all(context.spacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              'Error loading safety guidelines',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadGuidelines,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_guidelines == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(context.spacing.md),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildRequirementsList(),
          if (_guidelines!.emergencyInfo != null) ...[
            const SizedBox(height: 24),
            _buildEmergencyInfo(),
          ],
          if (_guidelines!.insurance != null) ...[
            const SizedBox(height: 24),
            _buildInsuranceRecommendation(),
          ],
          if (widget.showAcknowledgment) ...[
            const SizedBox(height: 24),
            _buildAcknowledgment(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.spacing.sm),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.security,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Checklist',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              SizedBox(height: context.spacing.xxs),
              Text(
                'Ensure your event meets safety requirements',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    final requirements = _guidelines!.requirements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Requirements',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        ...requirements
            .map((requirement) => _buildRequirementItem(requirement)),
      ],
    );
  }

  Widget _buildRequirementItem(SafetyRequirement requirement) {
    final displayName = _getRequirementDisplayName(requirement);
    final description = _getRequirementDescription(requirement);
    final icon = _getRequirementIcon(requirement);

    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.electricGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    final emergencyInfo = _guidelines!.emergencyInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emergency, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Emergency Information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(context.spacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emergencyInfo.contacts.isNotEmpty) ...[
                Text(
                  'Emergency Contacts:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                ...emergencyInfo.contacts.map((contact) => Padding(
                      padding: EdgeInsets.only(bottom: context.spacing.xs),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${contact.name} (${contact.role})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                Text(
                                  contact.phone,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (emergencyInfo.nearestHospital != null) ...[
                Text(
                  'Nearest Hospital:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  emergencyInfo.nearestHospital!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                if (emergencyInfo.nearestHospitalAddress != null) ...[
                  Text(
                    emergencyInfo.nearestHospitalAddress!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (emergencyInfo.nearestHospitalPhone != null) ...[
                  Text(
                    emergencyInfo.nearestHospitalPhone!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if (emergencyInfo.meetingPoint != null) ...[
                Text(
                  'Emergency Meeting Point:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  emergencyInfo.meetingPoint!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceRecommendation() {
    final insurance = _guidelines!.insurance!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shield,
              color:
                  insurance.required ? AppColors.error : AppTheme.warningColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Insurance Recommendation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(context.spacing.md),
          decoration: BoxDecoration(
            color:
                (insurance.required ? AppColors.error : AppTheme.warningColor)
                    .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  (insurance.required ? AppColors.error : AppTheme.warningColor)
                      .withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.xs,
                      vertical: context.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: insurance.required
                          ? AppColors.error
                          : AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      insurance.required ? 'REQUIRED' : 'RECOMMENDED',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insurance.explanation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suggested Coverage: \$${insurance.suggestedCoverageAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (insurance.insuranceProviders.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Recommended Providers:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                ...insurance.insuranceProviders.map((provider) => Padding(
                      padding: EdgeInsets.only(bottom: context.spacing.xxs),
                      child: Row(
                        children: [
                          const Icon(Icons.check,
                              size: 14, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Text(
                            provider,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgment() {
    return Container(
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _acknowledged ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _acknowledged,
            onChanged: widget.readOnly
                ? null
                : (value) {
                    if (value == true) {
                      _acknowledgeGuidelines();
                    }
                  },
            activeColor: AppTheme.primaryColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I acknowledge the safety requirements',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  'By checking this box, you confirm that you understand and will comply with all safety requirements for this event.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRequirementDisplayName(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return 'Capacity Limit';
      case SafetyRequirement.emergencyExits:
        return 'Emergency Exits';
      case SafetyRequirement.firstAidKit:
        return 'First Aid Kit';
      case SafetyRequirement.emergencyContacts:
        return 'Emergency Contacts';
      case SafetyRequirement.weatherPlan:
        return 'Weather Plan';
      case SafetyRequirement.alcoholPolicy:
        return 'Alcohol Policy';
      case SafetyRequirement.minorPolicy:
        return 'Minor Policy';
      case SafetyRequirement.foodSafety:
        return 'Food Safety';
      case SafetyRequirement.accessibilityPlan:
        return 'Accessibility Plan';
      case SafetyRequirement.covidProtocol:
        return 'COVID Protocol';
      case SafetyRequirement.securityPersonnel:
        return 'Security Personnel';
      case SafetyRequirement.fireSafety:
        return 'Fire Safety';
      case SafetyRequirement.crowdControl:
        return 'Crowd Control';
    }
  }

  String? _getRequirementDescription(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return 'Event must not exceed maximum attendee capacity';
      case SafetyRequirement.emergencyExits:
        return 'Clear emergency exit routes must be identified and accessible';
      case SafetyRequirement.firstAidKit:
        return 'First aid kit must be available on-site';
      case SafetyRequirement.emergencyContacts:
        return 'Emergency contact information must be readily available';
      case SafetyRequirement.weatherPlan:
        return 'Plan for weather-related contingencies';
      case SafetyRequirement.alcoholPolicy:
        return 'Alcohol service must comply with local regulations';
      case SafetyRequirement.minorPolicy:
        return 'Special considerations for events with minors';
      case SafetyRequirement.foodSafety:
        return 'Food handling must comply with health regulations';
      case SafetyRequirement.accessibilityPlan:
        return 'Event must be accessible to all attendees';
      case SafetyRequirement.covidProtocol:
        return 'COVID-19 safety protocols must be followed';
      case SafetyRequirement.securityPersonnel:
        return 'Security personnel may be required for large events';
      case SafetyRequirement.fireSafety:
        return 'Fire safety measures must be in place';
      case SafetyRequirement.crowdControl:
        return 'Crowd control measures must be implemented';
    }
  }

  IconData _getRequirementIcon(SafetyRequirement requirement) {
    switch (requirement) {
      case SafetyRequirement.capacityLimit:
        return Icons.people;
      case SafetyRequirement.emergencyExits:
        return Icons.exit_to_app;
      case SafetyRequirement.firstAidKit:
        return Icons.medical_services;
      case SafetyRequirement.emergencyContacts:
        return Icons.phone;
      case SafetyRequirement.weatherPlan:
        return Icons.wb_sunny;
      case SafetyRequirement.alcoholPolicy:
        return Icons.local_bar;
      case SafetyRequirement.minorPolicy:
        return Icons.child_care;
      case SafetyRequirement.foodSafety:
        return Icons.restaurant;
      case SafetyRequirement.accessibilityPlan:
        return Icons.accessible;
      case SafetyRequirement.covidProtocol:
        return Icons.health_and_safety;
      case SafetyRequirement.securityPersonnel:
        return Icons.security;
      case SafetyRequirement.fireSafety:
        return Icons.local_fire_department;
      case SafetyRequirement.crowdControl:
        return Icons.groups;
    }
  }
}
