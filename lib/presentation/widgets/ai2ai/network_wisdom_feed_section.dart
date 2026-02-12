import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai2ai/network_wisdom_feed_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:go_router/go_router.dart';

/// Small "From the network" section for home/discovery that shows network wisdom feed items.
///
/// Uses [NetworkWisdomFeedService] and optional [AgentIdService] to resolve agentId from userId.
/// When service or agentId is unavailable, shows nothing or empty state.
class NetworkWisdomFeedSection extends StatefulWidget {
  /// Current user ID (from auth). If null, feed is not loaded.
  final String? userId;

  /// Optional peer agent IDs to include. If null/empty, only messages involving current agent are shown.
  final List<String>? peerAgentIds;

  /// Max items to show (default 5).
  final int maxItems;

  const NetworkWisdomFeedSection({
    super.key,
    this.userId,
    this.peerAgentIds,
    this.maxItems = 5,
  });

  @override
  State<NetworkWisdomFeedSection> createState() =>
      _NetworkWisdomFeedSectionState();
}

class _NetworkWisdomFeedSectionState extends State<NetworkWisdomFeedSection> {
  List<NetworkWisdomFeedItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) _loadFeed();
  }

  @override
  void didUpdateWidget(NetworkWisdomFeedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != null && widget.userId != oldWidget.userId) _loadFeed();
  }

  Future<void> _loadFeed() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    if (!GetIt.instance.isRegistered<NetworkWisdomFeedService>()) return;

    setState(() => _loading = true);
    try {
      String? agentId;
      if (GetIt.instance.isRegistered<AgentIdService>()) {
        agentId = await GetIt.instance<AgentIdService>().getUserAgentId(userId);
      }
      if (agentId == null || agentId.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }
      final service = GetIt.instance<NetworkWisdomFeedService>();
      final items = await service.getFeedItems(
        currentAgentId: agentId,
        peerAgentIds: widget.peerAgentIds ?? [],
      );
      if (mounted) {
        setState(() {
          _items = items.take(widget.maxItems).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null ||
        !GetIt.instance.isRegistered<NetworkWisdomFeedService>()) {
      return const SizedBox.shrink();
    }
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'From the network',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(
                  item.shortLabel,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _formatTimestamp(item.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: item.deepLink != null
                    ? Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textSecondary)
                    : null,
                onTap: item.deepLink != null
                    ? () => context.go(item.deepLink!)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.month}/${t.day}';
  }
}
