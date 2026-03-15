import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:avrai_runtime_os/services/lists/list_analytics_service.dart';
import 'package:avrai_runtime_os/services/lists/list_sync_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';

Future<void> commitSuggestedListNegativeFeedback({
  required SuggestedList suggestedList,
  required NegativePreferenceIntent intent,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return;
  }

  if (di.sl.isRegistered<EntitySignatureService>()) {
    await di.sl<EntitySignatureService>().recordNegativePreferenceSignal(
          userId: userId,
          title: suggestedList.title,
          subtitle: suggestedList.description,
          category: suggestedList.theme,
          tags: <String>[
            suggestedList.theme,
            ...suggestedList.triggerReasons,
          ],
          intent: intent,
          entityType: 'suggested_list',
        );
  }

  if (di.sl.isRegistered<ListAnalyticsService>()) {
    final analytics = di.sl<ListAnalyticsService>();
    await analytics.initialize();
    await analytics.trackListDismiss(
      list: suggestedList,
      userId: userId,
      reason: switch (intent) {
        NegativePreferenceIntent.softIgnore =>
          ListInteraction.softIgnoreIntentValue,
        NegativePreferenceIntent.hardNotInterested =>
          ListInteraction.hardNotInterestedIntentValue,
      },
    );
  }

  if (di.sl.isRegistered<ListSyncService>()) {
    final sync = di.sl<ListSyncService>();
    await sync.initialize();
    await sync.markListDismissed(
      userId: userId,
      listId: suggestedList.id,
    );
    await sync.recordInteraction(
      userId: userId,
      listId: suggestedList.id,
      interaction: ListInteraction(
        type: ListInteractionType.dismissed,
        listId: suggestedList.id,
        involvedPlaces: suggestedList.places,
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{
          ListInteraction.negativePreferenceIntentMetadataKey: switch (intent) {
            NegativePreferenceIntent.softIgnore =>
              ListInteraction.softIgnoreIntentValue,
            NegativePreferenceIntent.hardNotInterested =>
              ListInteraction.hardNotInterestedIntentValue,
          },
          'theme': suggestedList.theme,
        },
      ),
    );
  }

  if (di.sl.isRegistered<KernelOutcomeAttributionLane>()) {
    await di.sl<KernelOutcomeAttributionLane>().recordListInteraction(
          userId: userId,
          interaction: ListInteraction(
            type: ListInteractionType.dismissed,
            listId: suggestedList.id,
            involvedPlaces: suggestedList.places,
            timestamp: DateTime.now(),
            metadata: <String, dynamic>{
              ListInteraction.negativePreferenceIntentMetadataKey: switch (
                  intent) {
                NegativePreferenceIntent.softIgnore =>
                  ListInteraction.softIgnoreIntentValue,
                NegativePreferenceIntent.hardNotInterested =>
                  ListInteraction.hardNotInterestedIntentValue,
              },
              'theme': suggestedList.theme,
            },
          ),
          suggestedList: suggestedList,
        );
  }
}
