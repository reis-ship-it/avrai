import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai/presentation/widgets/common/action_confirmation_dialog.dart';
import 'package:avrai/presentation/widgets/common/action_error_dialog.dart';
import 'package:avrai/presentation/widgets/common/action_success_widget.dart';
import 'package:avrai/presentation/widgets/common/ai_thinking_indicator.dart';
import 'package:avrai/presentation/widgets/common/streaming_response_widget.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_runtime_os/ai/action_executor.dart';
import 'package:avrai_runtime_os/ai/action_models.dart';
import 'package:avrai_runtime_os/ai/action_parser.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/misc/action_error_handler.dart';
import 'package:avrai_runtime_os/services/misc/action_history_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

class AICommandProcessor {
  static const String _logName = 'AICommandProcessor';

  /// Process a command using the language-kernel stack and deterministic action
  /// execution. Dynamic app-authored text is rendered through the
  /// `ExpressionKernel`, not through a freeform model response.
  static Future<String> processCommand(
    String command,
    BuildContext context, {
    String? userId,
    Position? currentLocation,
    bool useStreaming = true,
    bool showThinkingIndicator = true,
    Connectivity? connectivity,
  }) async {
    final connectivityInstance = connectivity ?? Connectivity();
    final connectivityResult = await connectivityInstance.checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);
    developer.log(
      'Processing command surface (${useStreaming ? "streaming_ui" : "single_turn"})',
      name: _logName,
    );
    final humanLanguageTurn = await _processHumanCommand(
      command: command,
      userId: userId,
    );

    if (userId != null) {
      OverlayEntry? thinkingOverlay;
      try {
        if (context.mounted &&
            showThinkingIndicator &&
            _canShowOverlay(context)) {
          thinkingOverlay = _showThinkingIndicator(context);
        }

        final actionParser = ActionParser();
        final intent = await actionParser.parseAction(
          command,
          userId: userId,
          currentLocation: currentLocation,
        );

        thinkingOverlay?.remove();
        thinkingOverlay = null;

        if (intent != null) {
          developer.log(
            'Action intent detected: ${intent.type} (confidence: ${intent.confidence})',
            name: _logName,
          );

          if (context.mounted &&
              showThinkingIndicator &&
              _canShowOverlay(context)) {
            thinkingOverlay = _showThinkingIndicator(context);
          }

          final canExecute = await actionParser.canExecute(intent);
          thinkingOverlay?.remove();
          thinkingOverlay = null;

          if (canExecute) {
            if (!context.mounted) {
              return _renderGroundedResponse(
                command: command,
                userId: userId,
                humanLanguageTurn: humanLanguageTurn,
                spec: _buildActionPreviewSpec(intent),
              );
            }

            final confirmed = await _showConfirmationDialog(context, intent);
            if (!confirmed) {
              return _renderGroundedResponse(
                command: command,
                userId: userId,
                humanLanguageTurn: humanLanguageTurn,
                spec: _buildCancelledSpec(intent),
              );
            }

            if (context.mounted &&
                showThinkingIndicator &&
                _canShowOverlay(context)) {
              thinkingOverlay = _showThinkingIndicator(context);
            }

            try {
              if (!context.mounted) {
                return _renderGroundedResponse(
                  command: command,
                  userId: userId,
                  humanLanguageTurn: humanLanguageTurn,
                  spec: _buildActionPreviewSpec(intent),
                );
              }
              final result = await _executeActionWithUI(
                context,
                intent,
                command,
                userId,
                humanLanguageTurn,
              );
              thinkingOverlay?.remove();
              return result;
            } catch (e) {
              thinkingOverlay?.remove();
              rethrow;
            }
          }

          return _renderGroundedResponse(
            command: command,
            userId: userId,
            humanLanguageTurn: humanLanguageTurn,
            spec: _buildNeedsMoreInfoSpec(intent),
          );
        }
      } catch (e, stackTrace) {
        thinkingOverlay?.remove();
        developer.log('Error in action execution: $e', name: _logName);
        developer.log('Stack trace: $stackTrace', name: _logName);
      }
    }

    OverlayEntry? thinkingOverlay;
    try {
      if (context.mounted &&
          showThinkingIndicator &&
          _canShowOverlay(context)) {
        thinkingOverlay = _showThinkingIndicator(context);
      }
      return _renderGroundedResponse(
        command: command,
        userId: userId,
        humanLanguageTurn: humanLanguageTurn,
        spec: _buildRuleBasedSpec(
          command,
          isOffline: isOffline,
          humanLanguageTurn: humanLanguageTurn,
        ),
      );
    } finally {
      thinkingOverlay?.remove();
    }
  }

  static Future<HumanLanguageKernelTurn?> _processHumanCommand({
    required String command,
    required String? userId,
  }) async {
    try {
      return await _resolveLanguageKernelOrchestrator().processHumanText(
        actorAgentId: userId ?? 'local_command_surface',
        rawText: command,
        consentScopes: userId == null
            ? const <String>{}
            : const <String>{'user_runtime_learning'},
        privacyMode: BoundaryPrivacyMode.localSovereign,
        shareRequested: false,
        userId: userId,
        chatType: 'agent',
        surface: 'command',
        channel: 'ai_command_processor',
      );
    } catch (e, st) {
      developer.log(
        'Command interpretation failed; using grounded fallback',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static LanguageKernelOrchestratorService
      _resolveLanguageKernelOrchestrator() {
    final sl = GetIt.instance;
    if (sl.isRegistered<LanguageKernelOrchestratorService>()) {
      return sl<LanguageKernelOrchestratorService>();
    }
    return LanguageKernelOrchestratorService();
  }

  static String _renderGroundedResponse({
    required String command,
    required String? userId,
    required HumanLanguageKernelTurn? humanLanguageTurn,
    required _GroundedCommandResponseSpec spec,
  }) {
    final evidenceRefs = <String>[
      ...spec.evidenceRefs,
      'command_len:${command.trim().length}',
      if (humanLanguageTurn != null)
        'interpretation:${humanLanguageTurn.interpretation.intent.toWireValue()}',
      if (humanLanguageTurn != null)
        'boundary:${humanLanguageTurn.boundary.disposition.toWireValue()}',
    ];
    final claims = <String>[
      ...spec.claims,
      if (humanLanguageTurn != null &&
          humanLanguageTurn
              .boundary.sanitizedArtifact.safePreferenceSignals.isNotEmpty)
        'I can keep your local preference signal around ${humanLanguageTurn.boundary.sanitizedArtifact.safePreferenceSignals.first.value} in mind while staying grounded.',
    ];

    final rendered = _resolveLanguageKernelOrchestrator().renderGroundedOutput(
      speechAct: spec.speechAct,
      audience: ExpressionAudience.userSafe,
      surfaceShape: ExpressionSurfaceShape.chatTurn,
      subjectLabel: spec.subjectLabel,
      allowedClaims: claims.take(4).toList(growable: false),
      evidenceRefs: evidenceRefs,
      confidenceBand:
          humanLanguageTurn?.interpretation.needsClarification ?? false
              ? 'medium'
              : 'high',
      toneProfile: 'grounded_direct',
      uncertaintyNotice: (humanLanguageTurn
                  ?.interpretation.needsClarification ??
              false)
          ? 'I can stay more grounded if you narrow the action, place type, or timing.'
          : null,
      cta: spec.cta,
      adaptationProfileRef: userId,
    );
    return rendered.text;
  }

  static _GroundedCommandResponseSpec _buildRuleBasedSpec(
    String command, {
    required bool isOffline,
    required HumanLanguageKernelTurn? humanLanguageTurn,
  }) {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('create') && lowerCommand.contains('list')) {
      return _buildCreateListSpec(command);
    }

    if (lowerCommand.contains('add') &&
        lowerCommand.contains('to') &&
        (lowerCommand.contains('spot') ||
            lowerCommand.contains('location') ||
            lowerCommand.contains('list'))) {
      return _buildAddSpotSpec(command);
    }

    if (lowerCommand.contains('event') ||
        lowerCommand.contains('weekend') ||
        lowerCommand.contains('upcoming')) {
      return _buildEventSpec(command, isOffline: isOffline);
    }

    if (lowerCommand.contains('user') || lowerCommand.contains('people')) {
      return _buildUserDiscoverySpec(command);
    }

    if (lowerCommand.contains('help') ||
        lowerCommand.contains('discover') ||
        lowerCommand.contains('new places')) {
      return _buildDiscoverySpec(isOffline: isOffline);
    }

    if (lowerCommand.contains('trip') ||
        lowerCommand.contains('plan') ||
        lowerCommand.contains('adventure')) {
      return _buildTripSpec();
    }

    if (lowerCommand.contains('trending') || lowerCommand.contains('popular')) {
      return _buildTrendingSpec(isOffline: isOffline);
    }

    if (lowerCommand.contains('find') ||
        lowerCommand.contains('search') ||
        lowerCommand.contains('show me')) {
      return _buildFindSpec(command, isOffline: isOffline);
    }

    if (humanLanguageTurn?.interpretation.needsClarification ?? false) {
      return const _GroundedCommandResponseSpec(
        speechAct: ExpressionSpeechAct.clarify,
        subjectLabel: 'your command',
        claims: <String>[
          'Your command is still broad enough that I should not pretend I know the exact next action.',
          'I can help once you narrow the place type, list name, timing, or action you want.',
        ],
        cta:
            'Try something like "create a coffee list", "find quiet cafes", or "show weekend events".',
      );
    }

    return _buildDefaultSpec();
  }

  static _GroundedCommandResponseSpec _buildCreateListSpec(String command) {
    var listName = 'New List';
    if (command.contains('"')) {
      final start = command.indexOf('"') + 1;
      final end = command.lastIndexOf('"');
      if (start > 0 && end > start) {
        listName = command.substring(start, end);
      }
    } else if (command.contains('called')) {
      final parts = command.split('called');
      if (parts.length > 1) {
        listName = parts[1].trim();
      }
    } else if (command.contains('for')) {
      final parts = command.split('for');
      if (parts.length > 1) {
        listName = parts[1].trim();
      }
    }

    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.confirm,
      subjectLabel: listName,
      claims: <String>[
        'I can create a list called "$listName".',
        'That list can hold spots you want to save or compare later.',
      ],
      cta:
          'Say "add Central Park to my $listName list" or ask me to find places for it.',
      evidenceRefs: const <String>['command:create_list'],
    );
  }

  static _GroundedCommandResponseSpec _buildAddSpotSpec(String command) {
    var spotName = 'this spot';
    var listName = 'your list';

    if (command.contains('add') && command.contains('to')) {
      final addIndex = command.indexOf('add');
      final toIndex = command.indexOf('to');
      if (addIndex < toIndex) {
        spotName = command.substring(addIndex + 4, toIndex).trim();
      }
    }

    if (command.contains('to my') && command.contains('list')) {
      final toMyIndex = command.indexOf('to my');
      final listIndex = command.indexOf('list', toMyIndex);
      if (toMyIndex < listIndex) {
        listName = command.substring(toMyIndex + 5, listIndex).trim();
      }
    }

    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.confirm,
      subjectLabel: listName,
      claims: <String>[
        'I can add $spotName to "$listName".',
        'Once it is saved, you can open that list to review or share it later.',
      ],
      cta:
          'If you want, tell me another spot to save or ask me to show the list.',
      evidenceRefs: const <String>['command:add_spot_to_list'],
    );
  }

  static _GroundedCommandResponseSpec _buildFindSpec(
    String command, {
    required bool isOffline,
  }) {
    final lowerCommand = command.toLowerCase();
    if (lowerCommand.contains('restaurant') || lowerCommand.contains('food')) {
      return _GroundedCommandResponseSpec(
        speechAct: ExpressionSpeechAct.recommend,
        subjectLabel: 'restaurant options',
        claims: <String>[
          'You are asking for restaurant options.',
          isOffline
              ? 'While you are offline, I can help narrow the kind of place you want and save the search for later.'
              : 'I can narrow the recommendations by vibe, price, distance, or neighborhood.',
        ],
        cta: 'Tell me casual, date-night, quick, cheap, or a neighborhood.',
        evidenceRefs: const <String>['command:find_restaurants'],
      );
    }

    if (lowerCommand.contains('coffee') || lowerCommand.contains('cafe')) {
      return _GroundedCommandResponseSpec(
        speechAct: ExpressionSpeechAct.recommend,
        subjectLabel: 'coffee options',
        claims: <String>[
          'You are asking for coffee or cafe options.',
          isOffline
              ? 'I can help define the kind of cafe you want now, and live lookups can resume when you reconnect.'
              : 'I can narrow the options by wifi, quietness, distance, or atmosphere.',
        ],
        cta: 'Tell me quiet, good wifi, quick stop, or best atmosphere.',
        evidenceRefs: const <String>['command:find_coffee'],
      );
    }

    if (lowerCommand.contains('park') || lowerCommand.contains('outdoor')) {
      return _GroundedCommandResponseSpec(
        speechAct: ExpressionSpeechAct.recommend,
        subjectLabel: 'outdoor options',
        claims: <String>[
          'You are asking for outdoor spots.',
          'I can narrow the options by walking distance, views, trails, or how social you want it to feel.',
        ],
        cta: 'Tell me walkable, scenic, social, or quiet.',
        evidenceRefs: const <String>['command:find_outdoors'],
      );
    }

    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.explain,
      subjectLabel: 'place search',
      claims: <String>[
        'I can help with place searches across restaurants, cafes, parks, study spots, and other local categories.',
        isOffline
            ? 'While you are offline, I can narrow the search and save the intent for later.'
            : 'I can narrow the search by vibe, price, distance, timing, or category.',
      ],
      cta:
          'Tell me what kind of place you want and one constraint that matters most.',
      evidenceRefs: const <String>['command:find_generic'],
    );
  }

  static _GroundedCommandResponseSpec _buildEventSpec(
    String command, {
    required bool isOffline,
  }) {
    final lowerCommand = command.toLowerCase();
    if (lowerCommand.contains('weekend')) {
      return _GroundedCommandResponseSpec(
        speechAct: ExpressionSpeechAct.recommend,
        subjectLabel: 'weekend events',
        claims: <String>[
          'You are asking about weekend events.',
          isOffline
              ? 'I can narrow the kind of event you want now, but live event freshness depends on reconnecting.'
              : 'I can help narrow by music, food, outdoors, social energy, or budget.',
        ],
        cta:
            'Tell me low-key, social, music, food, outdoors, or family-friendly.',
        evidenceRefs: const <String>['command:weekend_events'],
      );
    }

    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.recommend,
      subjectLabel: 'events',
      claims: <String>[
        'I can help you discover events by timing, category, and energy level.',
        isOffline
            ? 'I can hold the event intent locally and refine it now.'
            : 'I can help narrow the event search before you choose.',
      ],
      cta: 'Tell me the day, vibe, or kind of event you want.',
      evidenceRefs: const <String>['command:events_generic'],
    );
  }

  static _GroundedCommandResponseSpec _buildUserDiscoverySpec(String command) {
    final lowerCommand = command.toLowerCase();
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.explain,
      subjectLabel: 'people discovery',
      claims: <String>[
        lowerCommand.contains('area')
            ? 'You are asking about people in your area.'
            : 'You are asking about people with a shared interest.',
        'I can help narrow the kind of connection you want without exposing more than AVRAI should share.',
      ],
      cta:
          'Tell me the interest, location range, or kind of connection you want.',
      evidenceRefs: const <String>['command:people_discovery'],
    );
  }

  static _GroundedCommandResponseSpec _buildDiscoverySpec({
    required bool isOffline,
  }) {
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.recommend,
      subjectLabel: 'discovery help',
      claims: <String>[
        'I can help you discover places, events, and lists that fit what you want right now.',
        isOffline
            ? 'While offline, I can still help narrow the discovery path and hold it locally.'
            : 'The quickest way to get a strong result is to name the vibe, price, or distance you want.',
      ],
      cta:
          'Try "find quiet coffee shops", "show weekend events", or "create a food list".',
      evidenceRefs: const <String>['command:discovery_help'],
    );
  }

  static _GroundedCommandResponseSpec _buildTripSpec() {
    return const _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.explain,
      subjectLabel: 'trip planning',
      claims: <String>[
        'I can help structure a trip around places, timing, and saved lists.',
        'The most useful next step is to say whether this is a weekend trip, city exploration, or something outdoors.',
      ],
      cta:
          'Tell me the trip type and one thing you want the plan to optimize for.',
      evidenceRefs: <String>['command:trip_planning'],
    );
  }

  static _GroundedCommandResponseSpec _buildTrendingSpec({
    required bool isOffline,
  }) {
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.recommend,
      subjectLabel: 'trending places',
      claims: <String>[
        'You are asking for what is trending or popular.',
        isOffline
            ? 'Community freshness can lag while offline, but I can still help narrow what kind of popular place you want.'
            : 'I can narrow trending places by food, nightlife, outdoors, or social energy.',
      ],
      cta: 'Tell me the category or vibe you want from the trending results.',
      evidenceRefs: const <String>['command:trending'],
    );
  }

  static _GroundedCommandResponseSpec _buildDefaultSpec() {
    return const _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.explain,
      subjectLabel: 'command help',
      claims: <String>[
        'I can help create lists, save spots, find places, discover events, surface people, and structure trips.',
        'The clearest commands usually say the action plus one concrete thing you want.',
      ],
      cta:
          'Try "create a coffee list", "find restaurants near me", or "show weekend events".',
      evidenceRefs: <String>['command:help'],
    );
  }

  static _GroundedCommandResponseSpec _buildActionPreviewSpec(
    ActionIntent intent,
  ) {
    final preview = _generateActionPreview(intent);
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.confirm,
      subjectLabel: intent.type,
      claims: <String>[
        'You asked me to $preview.',
        'I am ready to execute that action once you confirm it.',
      ],
      cta: 'Confirm to continue or cancel to stop here.',
      evidenceRefs: const <String>['action:preview'],
    );
  }

  static _GroundedCommandResponseSpec _buildCancelledSpec(ActionIntent intent) {
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.confirm,
      subjectLabel: intent.type,
      claims: <String>[
        'I did not execute ${intent.type}.',
        'The action stayed local and nothing changed.',
      ],
      cta: 'If you want, edit the command and try again.',
      evidenceRefs: const <String>['action:cancelled'],
    );
  }

  static _GroundedCommandResponseSpec _buildNeedsMoreInfoSpec(
    ActionIntent intent,
  ) {
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.clarify,
      subjectLabel: intent.type,
      claims: <String>[
        'I understand the action direction, but I do not have enough grounded detail to execute ${intent.type}.',
        'I should ask for the missing detail instead of guessing.',
      ],
      cta:
          'Add the missing place, list name, location, or timing and try again.',
      evidenceRefs: const <String>['action:needs_more_info'],
    );
  }

  static _GroundedCommandResponseSpec _buildActionSuccessSpec({
    required ActionIntent intent,
    required ActionResult result,
  }) {
    final successMessage = result.successMessage ?? 'The action completed.';
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.confirm,
      subjectLabel: intent.type,
      claims: <String>[
        successMessage,
        'The action completed inside AVRAI without needing a freeform reply model.',
      ],
      cta: _buildActionSuccessCta(intent),
      evidenceRefs: const <String>['action:success'],
    );
  }

  static _GroundedCommandResponseSpec _buildActionFailureSpec({
    required ActionIntent intent,
    required ActionResult result,
  }) {
    return _GroundedCommandResponseSpec(
      speechAct: ExpressionSpeechAct.warn,
      subjectLabel: intent.type,
      claims: <String>[
        result.errorMessage ?? 'The action did not complete.',
        'I should not pretend the action succeeded when it did not.',
      ],
      cta:
          'Try again with a more specific command or adjust the missing detail.',
      evidenceRefs: const <String>['action:failure'],
    );
  }

  static String? _buildActionSuccessCta(ActionIntent intent) {
    if (intent is CreateListIntent) {
      return 'Tell me a spot to add to "${intent.title}" or ask me to find places for it.';
    }
    if (intent is CreateSpotIntent) {
      return 'If you want, ask me to add this spot to a list next.';
    }
    if (intent is CreateEventIntent) {
      return 'If you want, tell me how you want to refine or share the event.';
    }
    return 'If you want, tell me the next action to take.';
  }

  /// Show confirmation dialog for action execution.
  static Future<bool> _showConfirmationDialog(
    BuildContext context,
    ActionIntent intent,
  ) async {
    var confirmed = false;
    final preview = _generateActionPreview(intent);
    developer.log('Showing confirmation for action: $preview', name: _logName);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActionConfirmationDialog(
        intent: intent,
        showConfidence: intent.confidence < 0.8,
        onConfirm: () {
          confirmed = true;
        },
        onCancel: () {
          confirmed = false;
        },
      ),
    );
    return confirmed;
  }

  static String _generateActionPreview(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return 'create spot "${intent.name}" (${intent.category}) at ${intent.latitude.toStringAsFixed(4)}, ${intent.longitude.toStringAsFixed(4)}';
    }
    if (intent is CreateListIntent) {
      return 'create list "${intent.title}" (${intent.isPublic ? "public" : "private"})';
    }
    if (intent is AddSpotToListIntent) {
      final spotName = intent.metadata['spotName'] as String? ?? intent.spotId;
      final listName = intent.metadata['listName'] as String? ?? intent.listId;
      return 'add spot "$spotName" to list "$listName"';
    }
    if (intent is CreateEventIntent) {
      return 'create event "${intent.title ?? intent.templateId ?? "event"}"${intent.startTime != null ? " at ${intent.startTime}" : ""}';
    }
    return 'execute action: ${intent.type}';
  }

  static Future<String> _executeActionWithUI(
    BuildContext context,
    ActionIntent intent,
    String command,
    String? userId,
    HumanLanguageKernelTurn? humanLanguageTurn,
  ) async {
    final preview = _generateActionPreview(intent);
    developer.log('Executing action: $preview', name: _logName);

    final executor = ActionExecutor.fromDI();
    ActionResult result;

    try {
      result = await executor.execute(intent);
    } catch (e, stackTrace) {
      developer.log('Error executing action: $e', name: _logName);
      developer.log('Stack trace: $stackTrace', name: _logName);
      result = ActionResult.failure(
        error: 'Unexpected error: $e',
        intent: intent,
      );
    }

    if (result.success) {
      try {
        final historyService = GetIt.instance<ActionHistoryService>();
        await historyService.addAction(intent: intent, result: result);
        developer.log('Action stored in history', name: _logName);
      } catch (e) {
        developer.log('Failed to save action history: $e', name: _logName);
      }

      if (context.mounted) {
        await _showActionSuccessWidget(context, result, intent);
      }

      return _renderGroundedResponse(
        command: command,
        userId: userId,
        humanLanguageTurn: humanLanguageTurn,
        spec: _buildActionSuccessSpec(intent: intent, result: result),
      );
    }

    ActionErrorHandler.logError(
      result.errorMessage,
      result,
      intent,
      context: 'AICommandProcessor._executeActionWithUI',
    );

    if (!context.mounted) {
      return _renderGroundedResponse(
        command: command,
        userId: userId,
        humanLanguageTurn: humanLanguageTurn,
        spec: _buildActionFailureSpec(intent: intent, result: result),
      );
    }

    return _showErrorDialogWithRetry(
      context,
      intent,
      result,
      command,
      userId,
      humanLanguageTurn,
    );
  }

  static Future<String> _showErrorDialogWithRetry(
    BuildContext context,
    ActionIntent intent,
    ActionResult result,
    String command,
    String? userId,
    HumanLanguageKernelTurn? humanLanguageTurn,
  ) async {
    var retry = false;
    final technicalDetails = result.errorMessage ?? 'Unknown error occurred';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActionErrorDialog(
        error: technicalDetails,
        intent: intent,
        technicalDetails: technicalDetails,
        onDismiss: () {},
        onRetry: () {
          retry = true;
        },
      ),
    );

    if (retry) {
      developer.log('Retrying action after error', name: _logName);
      if (!context.mounted) {
        return _renderGroundedResponse(
          command: command,
          userId: userId,
          humanLanguageTurn: humanLanguageTurn,
          spec: _buildActionFailureSpec(intent: intent, result: result),
        );
      }
      return _executeActionWithUI(
        context,
        intent,
        command,
        userId,
        humanLanguageTurn,
      );
    }

    return _renderGroundedResponse(
      command: command,
      userId: userId,
      humanLanguageTurn: humanLanguageTurn,
      spec: _buildActionFailureSpec(intent: intent, result: result),
    );
  }

  static OverlayEntry _showThinkingIndicator(BuildContext context) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: AppColors.black.withValues(alpha: 0.54),
        child: const Center(
          child: AIThinkingIndicator(
            stage: AIThinkingStage.generatingResponse,
            showDetails: true,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }

  static bool _canShowOverlay(BuildContext context) {
    try {
      return context.mounted && Overlay.maybeOf(context) != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showActionSuccessWidget(
    BuildContext context,
    ActionResult result,
    ActionIntent intent,
  ) async {
    if (!context.mounted) return;

    VoidCallback? onUndo;
    if (intent is CreateListIntent || intent is CreateSpotIntent) {
      onUndo = null;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ActionSuccessWidget(
        result: result,
        onUndo: onUndo,
        onViewResult: () {
          if (intent is CreateListIntent) {
            final listId = result.data['listId'] as String?;
            developer.log(
              'Navigate to list: ${listId ?? intent.title}',
              name: _logName,
            );
          } else if (intent is CreateSpotIntent) {
            final spotId = result.data['spotId'] as String?;
            developer.log(
              'Navigate to spot: ${spotId ?? intent.name}',
              name: _logName,
            );
          }
        },
        autoDismiss: false,
      ),
    );
  }

  static Future<void> showStreamingResponse(
    BuildContext context,
    Stream<String> textStream, {
    VoidCallback? onComplete,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVRAI Response',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StreamingResponseWidget(
                textStream: textStream,
                onComplete: onComplete,
                onStop: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroundedCommandResponseSpec {
  const _GroundedCommandResponseSpec({
    required this.speechAct,
    required this.subjectLabel,
    required this.claims,
    this.cta,
    this.evidenceRefs = const <String>[],
  });

  final ExpressionSpeechAct speechAct;
  final String subjectLabel;
  final List<String> claims;
  final String? cta;
  final List<String> evidenceRefs;
}
