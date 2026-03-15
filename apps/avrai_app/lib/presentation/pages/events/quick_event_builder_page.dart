import 'dart:async';

import 'package:avrai/presentation/pages/events/event_published_page.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/events/event_template.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/services/event_planning_evidence_factory.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_runtime_os/services/events/beta_event_planning_suggestion_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_intake_adapter.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:avrai_runtime_os/services/events/event_template_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Philosophy: 5-7 minutes -> 30 seconds (Instagram Stories-like creation)
class QuickEventBuilderPage extends StatefulWidget {
  final UnifiedUser currentUser;
  final EventTemplate? preselectedTemplate;
  final ExpertiseEvent? copyFrom;
  final bool isBusinessAccount;
  final RawEventPlanningInput? initialPlanningInput;

  const QuickEventBuilderPage({
    super.key,
    required this.currentUser,
    this.preselectedTemplate,
    this.copyFrom,
    this.isBusinessAccount = false,
    this.initialPlanningInput,
  });

  @override
  State<QuickEventBuilderPage> createState() => _QuickEventBuilderPageState();
}

class _QuickEventBuilderPageState extends State<QuickEventBuilderPage> {
  final EventTemplateService _templateService = EventTemplateService();
  late final EventCreationController _eventCreationController;
  late final bool _planningAssistEnabled;
  EventPlanningIntakeAdapter? _planningIntakeAdapter;
  BetaEventPlanningSuggestionService? _planningSuggestionService;
  EventPlanningTelemetryService? _planningTelemetryService;

  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _vibeController = TextEditingController();
  final TextEditingController _audienceController = TextEditingController();
  final TextEditingController _candidateLocalityController =
      TextEditingController();

  int _currentStep = 0;
  EventPlanningSourceKind _planningSourceKind = EventPlanningSourceKind.human;
  EventTemplate? _selectedTemplate;
  DateTime? _selectedDateTime;
  List<Spot> _selectedSpots = <Spot>[];
  int _maxAttendees = 20;
  double? _price;
  String? _customTitle;
  String? _customDescription;
  EventHostGoal _selectedHostGoal = EventHostGoal.community;
  EventSizeIntent _selectedSizeIntent = EventSizeIntent.standard;
  EventPriceIntent _selectedPriceIntent = EventPriceIntent.free;
  EventPlanningAirGapResult? _planningAirGapResult;
  EventCreationSuggestion? _planningSuggestion;
  EventCreationSuggestion? _acceptedSuggestion;
  bool _hasInitialPersonalAgentDraft = false;
  bool _agentDraftEdited = false;
  bool _isSeedingPlanningDraft = false;
  bool _isLoading = false;
  String? _error;

  int get _reviewStepIndex => _planningAssistEnabled ? 4 : 3;
  int get _totalSteps => _planningAssistEnabled ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _eventCreationController = GetIt.instance<EventCreationController>();
    _planningAssistEnabled = BhamBetaDefaults.enableEventPlanningAssist &&
        GetIt.instance.isRegistered<EventPlanningIntakeAdapter>() &&
        GetIt.instance.isRegistered<BetaEventPlanningSuggestionService>();
    if (_planningAssistEnabled) {
      _planningIntakeAdapter = GetIt.instance<EventPlanningIntakeAdapter>();
      _planningSuggestionService =
          GetIt.instance<BetaEventPlanningSuggestionService>();
      _planningTelemetryService =
          GetIt.instance.isRegistered<EventPlanningTelemetryService>()
              ? GetIt.instance<EventPlanningTelemetryService>()
              : null;
      _registerPlanningListeners();
    }

    if (widget.preselectedTemplate != null) {
      _selectedTemplate = widget.preselectedTemplate;
      _currentStep = 1;
      _maxAttendees = _selectedTemplate!.defaultMaxAttendees;
      _price = _selectedTemplate!.suggestedPrice;
    }

    if (widget.copyFrom != null) {
      _prefillFromEvent(widget.copyFrom!);
    }
    if (widget.initialPlanningInput != null) {
      _applyInitialPlanningInput(widget.initialPlanningInput!);
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _vibeController.dispose();
    _audienceController.dispose();
    _candidateLocalityController.dispose();
    super.dispose();
  }

  void _registerPlanningListeners() {
    _purposeController.addListener(_handlePlanningDraftChanged);
    _vibeController.addListener(_handlePlanningDraftChanged);
    _audienceController.addListener(_handlePlanningDraftChanged);
    _candidateLocalityController.addListener(_handlePlanningDraftChanged);
  }

  void _handlePlanningDraftChanged() {
    if (_isSeedingPlanningDraft) {
      return;
    }
    final bool needsRefresh =
        _planningSourceKind == EventPlanningSourceKind.personalAgent ||
            _planningAirGapResult != null ||
            _planningSuggestion != null ||
            _acceptedSuggestion != null;
    if (!needsRefresh) {
      return;
    }
    setState(() {
      _markPlanningInputAsHumanEdited();
      _planningAirGapResult = null;
      _planningSuggestion = null;
      _acceptedSuggestion = null;
    });
  }

  void _markPlanningInputAsHumanEdited() {
    if (_planningSourceKind == EventPlanningSourceKind.personalAgent) {
      _planningSourceKind = EventPlanningSourceKind.human;
      _agentDraftEdited = true;
    }
  }

  void _applyInitialPlanningInput(RawEventPlanningInput input) {
    _isSeedingPlanningDraft = true;
    _planningSourceKind = input.sourceKind;
    _hasInitialPersonalAgentDraft =
        input.sourceKind == EventPlanningSourceKind.personalAgent;
    _agentDraftEdited = false;
    _purposeController.text = input.purposeText;
    _vibeController.text = input.vibeText;
    _audienceController.text = input.targetAudienceText;
    _candidateLocalityController.text = input.candidateLocalityLabel;
    _selectedHostGoal = input.hostGoal;
    _selectedSizeIntent = input.sizeIntent;
    _selectedPriceIntent = input.priceIntent;
    _selectedDateTime = input.preferredStartDate ?? _selectedDateTime;
    if (_selectedTemplate != null && _selectedDateTime != null) {
      _currentStep = _planningAssistEnabled ? 3 : _reviewStepIndex;
    }
    _isSeedingPlanningDraft = false;
  }

  void _prefillFromEvent(ExpertiseEvent event) {
    final templates = _templateService.getAllTemplates();
    _selectedTemplate = templates.firstWhere(
      (template) =>
          template.category == event.category &&
          template.eventType == event.eventType,
      orElse: () => templates.first,
    );

    _selectedSpots = event.spots;
    _maxAttendees = event.maxAttendees;
    _price = event.price;
    _customTitle = event.title;
    _customDescription = event.description;
    _selectedDateTime = _suggestNextWeekend();

    final snapshot = event.planningSnapshot;
    if (snapshot != null) {
      _selectedHostGoal = snapshot.docket.hostGoal;
      _selectedSizeIntent = snapshot.docket.sizeIntent;
      _selectedPriceIntent = snapshot.docket.priceIntent;
      _purposeController.text = snapshot.docket.intentTags.join(', ');
      _vibeController.text = snapshot.docket.vibeTags.join(', ');
      _audienceController.text = snapshot.docket.audienceTags.join(', ');
      _candidateLocalityController.text =
          snapshot.docket.candidateLocalityLabel ?? '';
      _planningAirGapResult = EventPlanningAirGapResult(
        docket: snapshot.docket,
        confidence: snapshot.docket.airGapProvenance.confidence,
        tupleRefs: snapshot.docket.airGapProvenance.tupleRefs,
        sourceKind: snapshot.docket.airGapProvenance.sourceKind,
        truthScope: snapshot.truthScope,
        evidenceEnvelope: EventPlanningEvidenceFactory.airGapResult(
          docket: snapshot.docket,
          confidence: snapshot.docket.airGapProvenance.confidence,
          sourceKind: snapshot.docket.airGapProvenance.sourceKind,
          truthScope: snapshot.truthScope,
        ),
      );
      _planningSuggestion = snapshot.acceptedSuggestion;
      _acceptedSuggestion = snapshot.acceptedSuggestion;
    }
  }

  DateTime _suggestNextWeekend() {
    final now = DateTime.now();
    var saturday =
        now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (saturday.isBefore(now)) {
      saturday = saturday.add(const Duration(days: 7));
    }
    return DateTime(saturday.year, saturday.month, saturday.day, 10, 0);
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Create Event',
      constrainBody: false,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: <Widget>[
        if (_currentStep > 0)
          TextButton(
            onPressed: _canGoBack && !_isLoading ? _previousStep : null,
            child: const Text(
              'Back',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
      ],
      body: Column(
        children: <Widget>[
          _buildProgressIndicator(),
          Expanded(child: _buildCurrentStep()),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List<Widget>.generate(_totalSteps, (int index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? AppTheme.primaryColor
                    : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTemplateSelection();
      case 1:
        return _buildDateTimeSelection();
      case 2:
        return _buildSpotSelection();
      case 3:
        return _planningAssistEnabled
            ? _buildEventTruthStep()
            : _buildReviewPublish();
      case 4:
        return _buildReviewPublish();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTemplateSelection() {
    final templates = widget.isBusinessAccount
        ? _templateService.getBusinessTemplates()
        : _templateService.getExpertTemplates();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Text(
          'Choose Event Type',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a template to get started quickly',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...templates.map(_buildTemplateCard),
      ],
    );
  }

  Widget _buildTemplateCard(EventTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = template;
          _maxAttendees = template.defaultMaxAttendees;
          _price = template.suggestedPrice;
          _markPlanningInputAsHumanEdited();
          _planningAirGapResult = null;
          _planningSuggestion = null;
          _acceptedSuggestion = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  template.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${template.defaultDuration.inHours}h • ${template.recommendedSpotCount} spots • ${template.getPriceDisplay()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (template.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: template.tags.take(3).map((String tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Text(
          'When?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose date and time for your event',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Quick Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickDateOption('This Weekend', _suggestNextWeekend()),
        _buildQuickDateOption(
          'Next Weekend',
          _suggestNextWeekend().add(const Duration(days: 7)),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _pickCustomDateTime,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDateTime == null
                ? 'Choose Custom Date'
                : 'Selected: ${_formatDateTime(_selectedDateTime!)}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.grey300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateOption(String label, DateTime dateTime) {
    final isSelected = _selectedDateTime != null &&
        _selectedDateTime!.year == dateTime.year &&
        _selectedDateTime!.month == dateTime.month &&
        _selectedDateTime!.day == dateTime.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateTime = dateTime;
          _markPlanningInputAsHumanEdited();
          _planningAirGapResult = null;
          _planningSuggestion = null;
          _acceptedSuggestion = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDateTime(dateTime),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) {
      return;
    }

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (!mounted) {
        return;
      }

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _markPlanningInputAsHumanEdited();
          _planningAirGapResult = null;
          _planningSuggestion = null;
          _acceptedSuggestion = null;
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final weekday = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ][dt.weekday - 1];
    final month = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][dt.month - 1];
    final normalizedHour =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dt.day} at $normalizedHour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildSpotSelection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Text(
          'Choose Spots',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select ${_selectedTemplate?.recommendedSpotCount ?? 3} spots for your event',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: <Widget>[
              Icon(
                Icons.location_on,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Spot selection UI coming soon',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'For now, spots will be selected automatically',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventTruthStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Text(
          'Event Truth',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Describe the event clearly. AVRAI will cross this through the event-planning air gap before it can be stored, learned from, or shared upward.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (_hasInitialPersonalAgentDraft) ...<Widget>[
          _buildAgentDraftCard(),
          const SizedBox(height: 16),
        ],
        _buildTextInputCard(
          label: 'Purpose',
          hint: 'What is this event trying to create or celebrate for people?',
          controller: _purposeController,
        ),
        _buildTextInputCard(
          label: 'Vibe',
          hint:
              'What should it feel like when people arrive and move through it?',
          controller: _vibeController,
        ),
        _buildTextInputCard(
          label: 'Audience',
          hint: 'Who should feel like this event is for them?',
          controller: _audienceController,
        ),
        _buildTextInputCard(
          label: 'Candidate Locality',
          hint: 'Neighborhood or area that feels like the best fit',
          controller: _candidateLocalityController,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildChoiceSection<EventHostGoal>(
          title: 'Host Goal',
          value: _selectedHostGoal,
          options: EventHostGoal.values,
          labelFor: (EventHostGoal goal) => _enumLabel(goal.name),
          onChanged: (EventHostGoal goal) {
            setState(() {
              _selectedHostGoal = goal;
              _markPlanningInputAsHumanEdited();
              _planningAirGapResult = null;
              _planningSuggestion = null;
              _acceptedSuggestion = null;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildChoiceSection<EventSizeIntent>(
          title: 'Size Intent',
          value: _selectedSizeIntent,
          options: EventSizeIntent.values,
          labelFor: (EventSizeIntent intent) => _enumLabel(intent.name),
          onChanged: (EventSizeIntent intent) {
            setState(() {
              _selectedSizeIntent = intent;
              _markPlanningInputAsHumanEdited();
              _planningAirGapResult = null;
              _planningSuggestion = null;
              _acceptedSuggestion = null;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildChoiceSection<EventPriceIntent>(
          title: 'Price Intent',
          value: _selectedPriceIntent,
          options: EventPriceIntent.values,
          labelFor: (EventPriceIntent intent) => _enumLabel(intent.name),
          onChanged: (EventPriceIntent intent) {
            setState(() {
              _selectedPriceIntent = intent;
              _markPlanningInputAsHumanEdited();
              _planningAirGapResult = null;
              _planningSuggestion = null;
              _acceptedSuggestion = null;
            });
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Air-Gap Rule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Raw planning text is temporary only. Downstream review, persistence, and learning can use only the bounded abstractions produced after this step.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (!BhamBetaDefaults.enableEventPlanningAssist) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  BhamBetaDefaults.eventPlanningAssistReason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputCard({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 3,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceSection<T>({
    required String title,
    required T value,
    required List<T> options,
    required String Function(T option) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((T option) {
            final isSelected = option == value;
            return ChoiceChip(
              label: Text(labelFor(option)),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.14),
              labelStyle: TextStyle(
                color:
                    isSelected ? AppTheme.primaryColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgentDraftCard() {
    final bool stillAgentOrigin =
        _planningSourceKind == EventPlanningSourceKind.personalAgent &&
            !_agentDraftEdited;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.smart_toy_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stillAgentOrigin
                  ? 'This draft came from your personal agent chat. Review it before crossing the air gap. If you change it here, the next crossing becomes human-reviewed input.'
                  : 'You revised the personal-agent draft. It still must cross the air gap again before review, storage, or learning.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPublish() {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      return const Center(child: Text('Missing information'));
    }

    final previewEvent = _buildPreviewEvent();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Text(
          'Review & Publish',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _planningAssistEnabled
              ? 'AVRAI is showing the air-gapped event truth below. Only sanitized planning abstractions are used from here forward.'
              : 'Everything look good?',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (_planningAssistEnabled &&
            _planningAirGapResult != null) ...<Widget>[
          _buildAirGapSummaryCard(_planningAirGapResult!),
          const SizedBox(height: 16),
        ],
        if (_planningAssistEnabled && _planningSuggestion != null) ...<Widget>[
          _buildSuggestionCard(_planningSuggestion!),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    _selectedTemplate!.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      previewEvent.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today,
                _formatDateTime(previewEvent.startTime),
              ),
              _buildInfoRow(
                Icons.schedule,
                '${previewEvent.endTime.difference(previewEvent.startTime).inHours} hours',
              ),
              _buildInfoRow(
                Icons.people,
                'Max ${previewEvent.maxAttendees} attendees',
              ),
              if (previewEvent.price != null)
                _buildInfoRow(
                  Icons.attach_money,
                  '\$${previewEvent.price!.toStringAsFixed(0)}',
                )
              else
                _buildInfoRow(Icons.local_offer_outlined, 'Free'),
              if ((previewEvent.location ?? '').trim().isNotEmpty)
                _buildInfoRow(
                  Icons.location_on_outlined,
                  previewEvent.location!.trim(),
                ),
              const SizedBox(height: 16),
              Text(
                previewEvent.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAirGapSummaryCard(EventPlanningAirGapResult result) {
    final docket = result.docket;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.shield, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Air-Gapped Event Truth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildPill(_enumLabel(result.confidence.name)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Only sanitized tags and bounded fields survived the air-gap crossing. Raw planning text is not used downstream.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crossed ${_formatDateTime(docket.airGapProvenance.crossedAt)} • '
            'ID ${_shortCrossingId(docket.airGapProvenance.crossingId)} • '
            '${docket.airGapProvenance.extractorVersion}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.flag_outlined,
            'Host goal: ${_enumLabel(docket.hostGoal.name)}',
          ),
          _buildInfoRow(
            Icons.groups_outlined,
            'Size intent: ${_enumLabel(docket.sizeIntent.name)}',
          ),
          _buildInfoRow(
            Icons.sell_outlined,
            'Price intent: ${_enumLabel(docket.priceIntent.name)}',
          ),
          if ((docket.candidateLocalityLabel ?? '').trim().isNotEmpty)
            _buildInfoRow(
              Icons.location_city_outlined,
              docket.candidateLocalityLabel!.trim(),
            ),
          const SizedBox(height: 12),
          if (docket.intentTags.isNotEmpty)
            _buildTagGroup('Intent Tags', docket.intentTags),
          if (docket.vibeTags.isNotEmpty)
            _buildTagGroup('Vibe Tags', docket.vibeTags),
          if (docket.audienceTags.isNotEmpty)
            _buildTagGroup('Audience Tags', docket.audienceTags),
          const SizedBox(height: 12),
          Text(
            'Tuple refs: ${result.tupleRefs.length} • Source: ${_enumLabel(result.sourceKind.name)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(EventCreationSuggestion suggestion) {
    final isAccepted = suggestion == _acceptedSuggestion;
    final isLowConfidence =
        suggestion.confidence == EventPlanningConfidence.low;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.22),
          width: isAccepted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Planning Suggestion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildPill(_enumLabel(suggestion.confidence.name)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.schedule_outlined,
            '${_formatDateTime(suggestion.suggestedStartTime)} to ${_formatTimeOnly(suggestion.suggestedEndTime)}',
          ),
          _buildInfoRow(
            Icons.people_outline,
            'Max ${suggestion.suggestedMaxAttendees} attendees',
          ),
          _buildInfoRow(
            Icons.attach_money_outlined,
            suggestion.suggestedPrice == null
                ? 'Free'
                : '\$${suggestion.suggestedPrice!.toStringAsFixed(0)}',
          ),
          if ((suggestion.suggestedLocalityLabel ?? '').trim().isNotEmpty)
            _buildInfoRow(
              Icons.location_on_outlined,
              suggestion.suggestedLocalityLabel!.trim(),
            ),
          const SizedBox(height: 8),
          Text(
            suggestion.explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (isLowConfidence) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.28),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a conservative beta suggestion. Review it manually or go back and add more event truth if you want stronger guidance.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  final bool shouldRecordAcceptance =
                      _acceptedSuggestion != suggestion;
                  setState(() {
                    _acceptedSuggestion = suggestion;
                  });
                  if (shouldRecordAcceptance &&
                      _planningAirGapResult != null &&
                      _planningTelemetryService != null) {
                    unawaited(
                      _planningTelemetryService!.recordSuggestionAccepted(
                        airGapResult: _planningAirGapResult!,
                        suggestion: suggestion,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                ),
                child: Text(
                  isAccepted
                      ? 'Using Suggestion'
                      : isLowConfidence
                          ? 'Use Conservative Suggestion'
                          : 'Use Suggestion',
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _acceptedSuggestion = null;
                  });
                },
                child: const Text('Keep Current Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagGroup(String title, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((String tag) => _buildPill(tag)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed && !_isLoading ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        _currentStep == _reviewStepIndex
                            ? 'Publish Event'
                            : _planningAssistEnabled && _currentStep == 3
                                ? 'Cross Air Gap & Review'
                                : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedTemplate != null;
      case 1:
        return _selectedDateTime != null;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  bool get _canGoBack => _currentStep > 0;

  Future<void> _nextStep() async {
    if (_currentStep == 3 && _planningAssistEnabled) {
      await _crossPlanningAirGapAndAdvance();
      return;
    }

    if (_currentStep < _reviewStepIndex) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    await _publishEvent();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _crossPlanningAirGapAndAdvance() async {
    if (!_planningAssistEnabled ||
        _planningIntakeAdapter == null ||
        _planningSuggestionService == null ||
        _selectedTemplate == null ||
        _selectedDateTime == null) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final airGapResult = await _planningIntakeAdapter!.ingestPlanningInput(
        ownerUserId: widget.currentUser.id,
        input: _buildRawPlanningInput(),
      );

      final suggestion = _planningSuggestionService!.suggest(
        docket: airGapResult.docket,
        eventType: _selectedTemplate!.eventType,
        currentStartTime: _selectedDateTime!,
        defaultDuration: _selectedTemplate!.defaultDuration,
        currentMaxAttendees: _maxAttendees,
        currentPrice: _price,
        truthScope: airGapResult.truthScope,
      );

      if (suggestion.confidence == EventPlanningConfidence.low &&
          _planningTelemetryService != null) {
        await _planningTelemetryService!.recordLowConfidenceSuggestion(
          airGapResult: airGapResult,
          suggestion: suggestion,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _planningAirGapResult = airGapResult;
        _planningSuggestion = suggestion;
        _currentStep += 1;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to cross planning input through the air gap: $error';
        _isLoading = false;
      });
    }
  }

  RawEventPlanningInput _buildRawPlanningInput() {
    return RawEventPlanningInput(
      sourceKind: _planningSourceKind,
      purposeText: _purposeController.text,
      vibeText: _vibeController.text,
      targetAudienceText: _audienceController.text,
      candidateLocalityLabel: _candidateLocalityController.text,
      preferredStartDate: _selectedDateTime,
      preferredEndDate: _selectedDateTime
          ?.add(_selectedTemplate?.defaultDuration ?? const Duration(hours: 2)),
      sizeIntent: _selectedSizeIntent,
      priceIntent: _selectedPriceIntent,
      hostGoal: _selectedHostGoal,
    );
  }

  EventPlanningSnapshot? _buildPlanningSnapshot() {
    if (!_planningAssistEnabled || _planningAirGapResult == null) {
      return null;
    }

    return EventPlanningSnapshot(
      docket: _planningAirGapResult!.docket,
      acceptedSuggestion: _acceptedSuggestion,
      createdAt: DateTime.now(),
      truthScope: _planningAirGapResult!.truthScope,
      evidenceEnvelope: EventPlanningEvidenceFactory.snapshot(
        airGapResult: _planningAirGapResult!,
        acceptedSuggestion: _acceptedSuggestion,
        truthScope: _planningAirGapResult!.truthScope,
      ),
    );
  }

  ExpertiseEvent _buildPreviewEvent() {
    final template = _selectedTemplate!;
    final startTime =
        _acceptedSuggestion?.suggestedStartTime ?? _selectedDateTime!;
    final endTime = _acceptedSuggestion?.suggestedEndTime ??
        startTime.add(template.defaultDuration);
    final maxAttendees =
        _acceptedSuggestion?.suggestedMaxAttendees ?? _maxAttendees;
    final effectivePrice = _acceptedSuggestion?.suggestedPrice ??
        (_selectedPriceIntent == EventPriceIntent.free ? null : _price);
    final location = _effectiveLocalityLabel();

    final templateEvent = _templateService.createEventFromTemplate(
      template: template,
      host: widget.currentUser,
      startTime: startTime,
      selectedSpots: _selectedSpots,
      customTitle: _customTitle,
      customDescription: _customDescription,
      customMaxAttendees: maxAttendees,
      customPrice: effectivePrice,
    );

    return templateEvent.copyWith(
      endTime: endTime,
      location: location ?? templateEvent.location,
      price: effectivePrice,
      isPaid: effectivePrice != null && effectivePrice > 0,
      planningSnapshot: _buildPlanningSnapshot(),
    );
  }

  String? _effectiveLocalityLabel() {
    final acceptedLocality =
        _acceptedSuggestion?.suggestedLocalityLabel?.trim();
    if (acceptedLocality != null && acceptedLocality.isNotEmpty) {
      return acceptedLocality;
    }

    final docketLocality =
        _planningAirGapResult?.docket.candidateLocalityLabel?.trim();
    if (docketLocality != null && docketLocality.isNotEmpty) {
      return docketLocality;
    }

    return null;
  }

  Future<void> _publishEvent() async {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      setState(() {
        _error = 'Please complete all required steps';
      });
      return;
    }

    if (_planningAssistEnabled && _planningAirGapResult == null) {
      setState(() {
        _error = 'Event truth must cross the air gap before publish.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final previewEvent = _buildPreviewEvent();
      final planningSnapshot = _buildPlanningSnapshot();
      final locality = _effectiveLocalityLabel();

      final formData = EventFormData(
        title: previewEvent.title,
        description: previewEvent.description,
        category: previewEvent.category,
        eventType: previewEvent.eventType,
        startTime: previewEvent.startTime,
        endTime: previewEvent.endTime,
        spots: previewEvent.spots,
        location: previewEvent.location,
        locality: locality,
        latitude: previewEvent.latitude,
        longitude: previewEvent.longitude,
        maxAttendees: previewEvent.maxAttendees,
        price: previewEvent.price,
        isPublic: previewEvent.isPublic,
        planningSnapshot: planningSnapshot,
      );

      final result = await _eventCreationController.createEvent(
        formData: formData,
        host: widget.currentUser,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (!result.isSuccess) {
        setState(() {
          _error = result.error ?? 'Failed to publish event';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (result.event != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                EventPublishedPage(event: result.event!),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to publish event: $error';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _enumLabel(String raw) {
    return raw
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match match) => ' ${match.group(1)}',
        )
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map((String part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatTimeOnly(DateTime dateTime) {
    final normalizedHour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _shortCrossingId(String crossingId) {
    if (crossingId.length <= 18) {
      return crossingId;
    }
    return '${crossingId.substring(0, 10)}...${crossingId.substring(crossingId.length - 6)}';
  }
}
