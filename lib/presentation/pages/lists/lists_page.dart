import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/pages/lists/create_list_page.dart';
import 'package:avrai/presentation/widgets/lists/spot_list_card.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/widgets/common/offline_indicator.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'My Lists',
      actions: const [
        OfflineIndicator(),
        SizedBox(width: 16),
      ],
      constrainBody: false,
      body: BlocBuilder<ListsBloc, ListsState>(
        builder: (context, state) {
          if (state is ListsInitial) {
            context.read<ListsBloc>().add(LoadLists());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ListsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ListsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading lists',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ListsBloc>().add(LoadLists());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ListsLoaded) {
            return _buildListsContent(context, state.lists);
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppNavigator.pushBuilder(
            context,
            builder: (context) => const CreateListPage(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListsContent(BuildContext context, List<SpotList> lists) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No lists yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first list to start organizing your spots',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                AppNavigator.pushBuilder(
                  context,
                  builder: (context) => const CreateListPage(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create List'),
            ),
          ],
        ),
      );
    }

    // Check if this is the first time showing lists (after onboarding)
    final isFirstTime = lists.length == 3 &&
        lists.any((list) => list.title.contains("'s Chill Spots")) &&
        lists.any((list) => list.title.contains("'s Fun Spots")) &&
        lists.any((list) => list.title.contains("'s Recommended Spots"));

    return Column(
      children: [
        if (isFirstTime) ...[
          PortalSurface(
            margin: const EdgeInsets.all(kSpaceMd),
            padding: const EdgeInsets.all(kSpaceMd),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to avrai!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We\'ve created your first personalized lists. Tap on any list to explore the spots!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(kSpaceMd),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return SpotListCard(
                list: list,
                onTap: () {
                  context.go('/list/${list.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
