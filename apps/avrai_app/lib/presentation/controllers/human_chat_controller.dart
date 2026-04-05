import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/events/event_template.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/events/event_template_service.dart';
import 'package:avrai_runtime_os/services/recommendations/agent_happiness_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

/// View-model for the human-facing AI chat surface.
///
/// This keeps the widget focused on rendering while the controller owns
/// identity/session initialization, history loading, sending messages,
/// optional location enrichment, and helpfulness feedback.
class HumanChatController extends ChangeNotifier {
  final PersonalityAgentChatService _chatService;
  final AgentIdService _agentIdService;
  final EntitySignatureService? _entitySignatureService;
  final EventTemplateService _eventTemplateService;
  final Future<SharedPreferencesCompat> Function() _prefsProvider;
  final Future<Position?> Function() _locationProvider;
  final DateTime Function() _nowLocal;

  HumanChatController({
    PersonalityAgentChatService? chatService,
    AgentIdService? agentIdService,
    EntitySignatureService? entitySignatureService,
    EventTemplateService? eventTemplateService,
    Future<SharedPreferencesCompat> Function()? prefsProvider,
    Future<Position?> Function()? locationProvider,
    DateTime Function()? nowLocal,
  })  : _chatService =
            chatService ?? GetIt.instance<PersonalityAgentChatService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _entitySignatureService = entitySignatureService ??
            (GetIt.instance.isRegistered<EntitySignatureService>()
                ? GetIt.instance<EntitySignatureService>()
                : null),
        _eventTemplateService = eventTemplateService ?? EventTemplateService(),
        _prefsProvider =
            prefsProvider ?? (() => SharedPreferencesCompat.getInstance()),
        _locationProvider = locationProvider ?? _defaultLocationProvider,
        _nowLocal = nowLocal ?? DateTime.now;

  List<HumanChatMessage> _messages = const [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _userId;
  String? _agentId;
  String? _lastError;
  SharedPreferencesCompat? _prefs;
  Map<String, double>? _recentDNAOverlay;
  Timer? _overlayTimer;
  String? _signatureSummary;
  List<String> _signaturePrompts = const [];
  PersonalityAgentChatResult? _lastChatKernelResult;
  AgentEventPlanningDraft? _lastEventPlanningDraft;

  List<HumanChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isReady => _userId != null && _agentId != null;
  String? get userId => _userId;
  String? get lastError => _lastError;
  Map<String, double>? get recentDNAOverlay => _recentDNAOverlay;
  String? get signatureSummary => _signatureSummary;
  List<String> get signaturePrompts => _signaturePrompts;
  PersonalityAgentChatResult? get lastChatKernelResult => _lastChatKernelResult;
  AgentEventPlanningDraft? get lastEventPlanningDraft =>
      _lastEventPlanningDraft;
  String? get lastKernelEventId => _lastChatKernelResult?.kernelEventId;
  bool get modelTruthReady => _lastChatKernelResult?.modelTruthReady ?? false;
  bool get localityContainedInWhere =>
      _lastChatKernelResult?.localityContainedInWhere ?? false;
  String? get governanceSummary => _lastChatKernelResult?.governanceSummary;
  List<String> get governanceDomains =>
      _lastChatKernelResult?.governanceDomains ?? const <String>[];

  /// Initialize the chat session for the authenticated user.
  Future<void> initialize({required String userId}) async {
    if (_userId == userId && _agentId != null) {
      return;
    }

    _isLoading = true;
    _userId = userId;
    _lastError = null;
    notifyListeners();

    try {
      _prefs ??= await _prefsProvider();
      _agentId = await _agentIdService.getUserAgentId(userId);
      _lastChatKernelResult = null;
      _lastEventPlanningDraft = null;
      await _loadConversationHistory();
      await _refreshSignatureContext();
    } catch (e, st) {
      developer.log(
        'Failed to initialize human chat controller',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
      _lastError = 'Your AI chat did not load. Try again in a moment.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a new human message and append the agent response.
  Future<void> sendMessage(String messageText) async {
    final trimmedMessage = messageText.trim();
    if (trimmedMessage.isEmpty || _userId == null || _agentId == null) {
      return;
    }

    final pendingUserMessage = HumanChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: trimmedMessage,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    _messages = [..._messages, pendingUserMessage];
    _isSending = true;
    _lastError = null;
    notifyListeners();

    try {
      _recordChatReflection(trimmedMessage);
      final result = await _chatService.chatWithKernelContext(
        _userId!,
        trimmedMessage,
        currentLocation: await _locationProvider(),
      );
      final response = result.response;

      await _checkAspirationalDNA();
      await _refreshSignatureContext();
      _lastChatKernelResult = result;
      _lastEventPlanningDraft = _buildEventPlanningDraft(
        userMessage: trimmedMessage,
        agentResponse: response,
      );

      _messages = [
        ..._messages,
        HumanChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response,
          isFromUser: false,
          timestamp: DateTime.now(),
          happinessRated: false,
        ),
      ];
    } catch (e, st) {
      developer.log(
        'Failed to send human chat message',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
      _lastError = 'Your message did not send. Nothing changed silently.';
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> recordPromptSuggestion(String prompt) async {
    if (_userId == null || prompt.trim().isEmpty) {
      return;
    }
    try {
      await _entitySignatureService?.recordChatReflectionSignal(
        userId: _userId!,
        messageText: prompt,
      );
      await _refreshSignatureContext();
      notifyListeners();
    } catch (e, st) {
      developer.log(
        'Failed to record chat prompt suggestion signal',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Record whether an agent response was helpful.
  Future<void> rateMessage({
    required String messageId,
    required double score,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    try {
      final service = AgentHappinessService(prefs: prefs);
      await service.recordSignal(
        source: 'chat_rating',
        score: score,
        metadata: <String, dynamic>{
          'message_id': messageId,
        },
      );

      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(happinessRated: true)
                : message,
          )
          .toList(growable: false);
      notifyListeners();
    } catch (e, st) {
      developer.log(
        'Failed to record chat helpfulness signal',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _loadConversationHistory() async {
    if (_userId == null || _agentId == null) {
      return;
    }

    final history = await _chatService.getConversationHistory(_userId!);
    final decryptedMessages = await Future.wait(
      history.map((message) async {
        final decrypted = await _chatService.getDecryptedMessageAsync(
          message,
          _agentId!,
          _userId!,
        );
        return HumanChatMessage(
          id: message.messageId,
          content: decrypted,
          isFromUser: message.isFromUser,
          timestamp: message.timestamp,
        );
      }),
    );

    decryptedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _messages = List<HumanChatMessage>.unmodifiable(decryptedMessages);
  }

  Future<void> _checkAspirationalDNA() async {
    if (_userId == null || _prefs == null) {
      return;
    }

    final storedData = _prefs!.getString('aspirational_state_$_userId');
    if (storedData == null || storedData.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(storedData) as Map<String, dynamic>;
      final dnaShifts = <String, double>{};
      decoded.forEach((key, value) {
        dnaShifts[key] = (value as num).toDouble();
      });

      _recentDNAOverlay = dnaShifts;
      notifyListeners();

      _overlayTimer?.cancel();
      _overlayTimer = Timer(const Duration(seconds: 4), () {
        _recentDNAOverlay = null;
        notifyListeners();
      });

      await _prefs!.remove('aspirational_state_$_userId');
    } catch (e, st) {
      developer.log(
        'Failed to decode aspirational DNA overlay payload',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _refreshSignatureContext() async {
    if (_userId == null) {
      return;
    }

    try {
      _signatureSummary = await _chatService.getUserSignatureSummary(
        userId: _userId!,
        currentLocation: await _locationProvider(),
      );
      _signaturePrompts = _buildSignaturePrompts(_signatureSummary);
    } catch (e, st) {
      developer.log(
        'Failed to refresh signature chat context',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
      _signatureSummary = null;
      _signaturePrompts = const [];
    }
  }

  List<String> _buildSignaturePrompts(String? summary) {
    if (summary == null || summary.trim().isEmpty) {
      return const <String>[
        'What fits my life tonight?',
        'Why would this event fit me?',
        'What should you remember about what matters to me?',
      ];
    }

    return <String>[
      'What fits my current signature tonight?',
      'Why does this vibe fit me right now?',
      'Use my signature to suggest one spot and one event.',
    ];
  }

  void _recordChatReflection(String messageText) {
    if (_userId == null || messageText.trim().isEmpty) {
      return;
    }

    unawaited(
      _entitySignatureService?.recordChatReflectionSignal(
        userId: _userId!,
        messageText: messageText,
      ),
    );
  }

  static Future<Position?> _defaultLocationProvider() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Location unavailable for chat turn, sending without location context',
        name: 'HumanChatController',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  AgentEventPlanningDraft? _buildEventPlanningDraft({
    required String userMessage,
    required String agentResponse,
  }) {
    final String combined = '$userMessage $agentResponse'.trim().toLowerCase();
    final EventTemplate? template = _suggestTemplate(combined);
    final bool looksEventLike = template != null ||
        _eventPlanningKeywords.any((String keyword) => combined.contains(keyword));
    if (!looksEventLike) {
      return null;
    }

    final DateTime? preferredStartDate = _derivePreferredStartDate(userMessage);
    final RawEventPlanningInput input = RawEventPlanningInput(
      sourceKind: EventPlanningSourceKind.personalAgent,
      purposeText: _boundedText(userMessage, 220),
      vibeText: _boundedText(_firstSentence(agentResponse), 220),
      targetAudienceText: _boundedText(
        _signatureSummary ??
            'People who already fit this vibe and those close to it.',
        220,
      ),
      candidateLocalityLabel: '',
      preferredStartDate: preferredStartDate,
      preferredEndDate: preferredStartDate == null || template == null
          ? null
          : preferredStartDate.add(template.defaultDuration),
      sizeIntent: _sizeIntentForTemplate(template),
      priceIntent: _priceIntentForTemplate(template),
      hostGoal: _hostGoalForTemplate(template),
    );

    return AgentEventPlanningDraft(
      planningInput: input,
      suggestedTemplate: template,
      summary: template == null
          ? 'Drafted from your last personal-agent chat turn.'
          : 'Drafted from your last personal-agent chat turn using ${template.name}.',
    );
  }

  EventTemplate? _suggestTemplate(String combined) {
    if (combined.contains('coffee')) {
      return _eventTemplateService.getTemplate('coffee_tasting_tour');
    }
    if (combined.contains('music') ||
        combined.contains('concert') ||
        combined.contains('festival')) {
      return _eventTemplateService.getTemplate('concert_meetup');
    }
    if (combined.contains('trivia')) {
      return _eventTemplateService.getTemplate('trivia_night');
    }
    if (combined.contains('food')) {
      return _eventTemplateService.getTemplate('food_tour');
    }
    if (combined.contains('book')) {
      return _eventTemplateService.getTemplate('bookstore_walk');
    }
    if (combined.contains('museum') || combined.contains('art')) {
      return _eventTemplateService.getTemplate('museum_tour');
    }
    if (combined.contains('bar') || combined.contains('crawl')) {
      return _eventTemplateService.getTemplate('bar_crawl');
    }

    final List<EventTemplate> searchResults =
        _eventTemplateService.searchTemplates(combined);
    return searchResults.isEmpty ? null : searchResults.first;
  }

  EventHostGoal _hostGoalForTemplate(EventTemplate? template) {
    final String templateId = template?.id ?? '';
    if (templateId == 'concert_meetup') {
      return EventHostGoal.celebration;
    }
    if (templateId == 'trivia_night') {
      return EventHostGoal.networking;
    }
    if (templateId == 'coffee_tasting_tour' || templateId == 'museum_tour') {
      return EventHostGoal.learning;
    }
    return EventHostGoal.community;
  }

  EventSizeIntent _sizeIntentForTemplate(EventTemplate? template) {
    final int attendeeCap = template?.defaultMaxAttendees ?? 20;
    if (attendeeCap >= 40) {
      return EventSizeIntent.large;
    }
    if (attendeeCap <= 16) {
      return EventSizeIntent.intimate;
    }
    return EventSizeIntent.standard;
  }

  EventPriceIntent _priceIntentForTemplate(EventTemplate? template) {
    final double? price = template?.suggestedPrice;
    if (price == null || price <= 0) {
      return EventPriceIntent.free;
    }
    if (price <= 20) {
      return EventPriceIntent.lowCost;
    }
    return EventPriceIntent.ticketed;
  }

  DateTime? _derivePreferredStartDate(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('next weekend')) {
      return _nextWeekday(DateTime.saturday, weeksAhead: 1);
    }
    if (lower.contains('this weekend') || lower.contains('weekend')) {
      return _nextWeekday(DateTime.saturday);
    }
    if (lower.contains('friday')) {
      return _nextWeekday(DateTime.friday);
    }
    if (lower.contains('saturday')) {
      return _nextWeekday(DateTime.saturday);
    }
    if (lower.contains('sunday')) {
      return _nextWeekday(DateTime.sunday);
    }
    if (lower.contains('tonight')) {
      final DateTime now = _nowLocal();
      return DateTime(now.year, now.month, now.day, 19);
    }
    return null;
  }

  DateTime _nextWeekday(int weekday, {int weeksAhead = 0}) {
    final DateTime now = _nowLocal();
    final int daysUntil = (weekday - now.weekday + 7) % 7;
    final DateTime target = now.add(
      Duration(days: daysUntil == 0 ? 7 : daysUntil + (weeksAhead * 7)),
    );
    return DateTime(target.year, target.month, target.day, 18);
  }

  String _firstSentence(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final Match? match = RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(trimmed);
    return match?.group(0)?.trim() ?? trimmed;
  }

  String _boundedText(String text, int maxChars) {
    final String trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxChars - 1).trimRight()}…';
  }

  static const List<String> _eventPlanningKeywords = <String>[
    'event',
    'festival',
    'meetup',
    'music',
    'concert',
    'tour',
    'workshop',
    'tasting',
    'party',
    'celebration',
    'host',
    'spring',
  ];

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }
}

/// Immutable chat message model for the human-facing AI chat UI.
class HumanChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool happinessRated;

  const HumanChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.happinessRated = false,
  });

  HumanChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    bool? happinessRated,
  }) {
    return HumanChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      happinessRated: happinessRated ?? this.happinessRated,
    );
  }
}

class AgentEventPlanningDraft {
  const AgentEventPlanningDraft({
    required this.planningInput,
    required this.suggestedTemplate,
    required this.summary,
  });

  final RawEventPlanningInput planningInput;
  final EventTemplate? suggestedTemplate;
  final String summary;
}
