import 'package:flutter/material.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'suggested_list_card.dart';

/// SuggestedListsSection - Section displaying AI-suggested lists
///
/// Features:
/// - Horizontal scrolling mode for home page
/// - Vertical list mode for full page
/// - Empty state message
/// - Loading state
///
/// Part of Phase 2.1: Suggested Lists UI Components

class SuggestedListsSection extends StatelessWidget {
  final List<SuggestedList> suggestedLists;
  final bool isLoading;
  final String? errorMessage;
  final bool horizontalMode;
  final void Function(SuggestedList)? onListTap;
  final void Function(SuggestedList)? onListDismiss;
  final void Function(SuggestedList)? onListUndoDismiss;
  final void Function(SuggestedList)? onListSave;
  final void Function(SuggestedList)? onWhyThisList;
  final VoidCallback? onSeeAll;

  const SuggestedListsSection({
    super.key,
    required this.suggestedLists,
    this.isLoading = false,
    this.errorMessage,
    this.horizontalMode = true,
    this.onListTap,
    this.onListDismiss,
    this.onListUndoDismiss,
    this.onListSave,
    this.onWhyThisList,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested For You',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (onSeeAll != null && suggestedLists.isNotEmpty)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Content
        if (isLoading)
          _buildLoadingState(context)
        else if (errorMessage != null)
          _buildErrorState(context)
        else if (suggestedLists.isEmpty)
          _buildEmptyState(context)
        else if (horizontalMode)
          _buildHorizontalList(context)
        else
          _buildVerticalList(context),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Text(
        errorMessage!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No suggestions yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep exploring! We\'ll suggest personalized lists based on your preferences.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestedLists.length,
        itemBuilder: (context, index) {
          final list = suggestedLists[index];
          return SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SuggestedListCard(
                suggestedList: list,
                onTap: () => onListTap?.call(list),
                onDismiss: () => onListDismiss?.call(list),
                onUndoDismiss: () => onListUndoDismiss?.call(list),
                onSave: () => onListSave?.call(list),
                onWhyThisList: () => onWhyThisList?.call(list),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: suggestedLists.map((list) {
          return SuggestedListCard(
            suggestedList: list,
            onTap: () => onListTap?.call(list),
            onDismiss: () => onListDismiss?.call(list),
            onUndoDismiss: () => onListUndoDismiss?.call(list),
            onSave: () => onListSave?.call(list),
            onWhyThisList: () => onWhyThisList?.call(list),
          );
        }).toList(),
      ),
    );
  }
}
