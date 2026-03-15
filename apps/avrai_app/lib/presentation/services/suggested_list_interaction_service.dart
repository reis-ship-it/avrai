import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:avrai_runtime_os/services/lists/list_analytics_service.dart';
import 'package:avrai_runtime_os/services/lists/list_sync_service.dart';

Future<void> recordSuggestedListView({
  required SuggestedList suggestedList,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return;
  }

  if (di.sl.isRegistered<ListAnalyticsService>()) {
    final analytics = di.sl<ListAnalyticsService>();
    await analytics.initialize();
    await analytics.trackListView(
      list: suggestedList,
      userId: userId,
    );
  }

  if (di.sl.isRegistered<ListSyncService>()) {
    final sync = di.sl<ListSyncService>();
    await sync.initialize();
    await sync.recordInteraction(
      userId: userId,
      listId: suggestedList.id,
      interaction: ListInteraction(
        type: ListInteractionType.viewed,
        listId: suggestedList.id,
        involvedPlaces: suggestedList.places,
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{'theme': suggestedList.theme},
      ),
    );
  }

  if (di.sl.isRegistered<KernelOutcomeAttributionLane>()) {
    await di.sl<KernelOutcomeAttributionLane>().recordListInteraction(
          userId: userId,
          interaction: ListInteraction(
            type: ListInteractionType.viewed,
            listId: suggestedList.id,
            involvedPlaces: suggestedList.places,
            timestamp: DateTime.now(),
            metadata: <String, dynamic>{'theme': suggestedList.theme},
          ),
          suggestedList: suggestedList,
        );
  }
}

Future<void> recordSuggestedListSave({
  required SuggestedList suggestedList,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return;
  }

  if (di.sl.isRegistered<ListAnalyticsService>()) {
    final analytics = di.sl<ListAnalyticsService>();
    await analytics.initialize();
    await analytics.trackListSave(
      list: suggestedList,
      userId: userId,
    );
  }

  if (di.sl.isRegistered<ListSyncService>()) {
    final sync = di.sl<ListSyncService>();
    await sync.initialize();
    await sync.markListSaved(
      userId: userId,
      listId: suggestedList.id,
      isSaved: true,
    );
    await sync.recordInteraction(
      userId: userId,
      listId: suggestedList.id,
      interaction: ListInteraction(
        type: ListInteractionType.saved,
        listId: suggestedList.id,
        involvedPlaces: suggestedList.places,
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{'theme': suggestedList.theme},
      ),
    );
  }

  if (di.sl.isRegistered<KernelOutcomeAttributionLane>()) {
    await di.sl<KernelOutcomeAttributionLane>().recordListInteraction(
          userId: userId,
          interaction: ListInteraction(
            type: ListInteractionType.saved,
            listId: suggestedList.id,
            involvedPlaces: suggestedList.places,
            timestamp: DateTime.now(),
            metadata: <String, dynamic>{'theme': suggestedList.theme},
          ),
          suggestedList: suggestedList,
        );
  }
}
