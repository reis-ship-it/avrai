import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_core/models/signatures/signature_match_result.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/communities_discover_page_schema.dart';
import 'package:avrai/presentation/widgets/common/app_status_pill.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

/// Community discovery page (join/discover ranking)
///
/// Shows communities ranked by **combined true compatibility** for the
/// authenticated user.
class CommunitiesDiscoverPage extends StatefulWidget {
  final bool showAppBar;

  const CommunitiesDiscoverPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<CommunitiesDiscoverPage> createState() =>
      _CommunitiesDiscoverPageState();
}

class _CommunitiesDiscoverPageState extends State<CommunitiesDiscoverPage> {
  final CommunityService _communityService =
      GetIt.instance.isRegistered<CommunityService>()
          ? GetIt.instance<CommunityService>()
          : CommunityService();
  final EntitySignatureService? _entitySignatureService =
      GetIt.instance.isRegistered<EntitySignatureService>()
          ? GetIt.instance<EntitySignatureService>()
          : null;

  bool _isLoading = true;
  String? _error;
  List<Community> _communities = const [];
  Map<String, CommunityTrueCompatibilityBreakdown> _breakdownsByCommunityId =
      const {};
  Map<String, SignatureMatchResult> _matchesByCommunityId = const {};
  final Set<String> _joiningCommunityIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _communities = const [];
        _breakdownsByCommunityId = const {};
        _matchesByCommunityId = const {};
        _isLoading = false;
      });
      return;
    }

    try {
      // Local-first: load candidates, then score with bounded concurrency.
      final all = await _communityService.getAllCommunities(maxResults: 500);
      final candidates =
          all.where((c) => !c.isMember(authState.user.id)).toList();

      final breakdowns =
          await _scoreCommunitiesBounded(candidates, authState.user.id);
      final matches = await _scoreCommunityMatchesBounded(
        communities: candidates,
        userId: authState.user.id,
        fallbackBreakdowns: breakdowns,
      );

      candidates.sort((a, b) {
        final sa =
            matches[a.id]?.finalScore ?? breakdowns[a.id]?.combined ?? 0.5;
        final sb =
            matches[b.id]?.finalScore ?? breakdowns[b.id]?.combined ?? 0.5;
        return sb.compareTo(sa);
      });

      if (!mounted) return;
      setState(() {
        _communities = candidates.take(20).toList();
        _breakdownsByCommunityId = breakdowns;
        _matchesByCommunityId = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load community recommendations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final resultsHeight =
        (MediaQuery.sizeOf(context).height * 0.42).clamp(280.0, 520.0).toDouble();

    return AppSchemaPage(
      schema: buildCommunitiesDiscoverPageSchema(
        content: SizedBox(
          height: resultsHeight,
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.textPrimary,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : authState is! Authenticated
                    ? _buildSignedOutState()
                    : _error != null
                        ? _buildErrorState(_error!)
                        : _communities.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _communities.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final community = _communities[index];
                                  return _buildCommunityCard(
                                    community,
                                    authState.user.id,
                                  );
                                },
                              ),
          ),
        ),
      ),
      showNavigationBar: widget.showAppBar,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _load,
        ),
      ],
    );
  }

  Widget _buildCommunityCard(Community community, String userId) {
    final breakdown = _breakdownsByCommunityId[community.id];
    final match = _matchesByCommunityId[community.id];
    final scoreText = (match?.finalScore ?? breakdown?.combined) == null
        ? '—'
        : '${(((match?.finalScore ?? breakdown?.combined) ?? 0.5) * 100).toStringAsFixed(0)}%';
    final breakdownText = breakdown == null
        ? null
        : 'Q ${(breakdown.quantum * 100).toStringAsFixed(0)}% • '
            'Topo ${(breakdown.topological * 100).toStringAsFixed(0)}% • '
            'Weave ${(breakdown.weaveFit * 100).toStringAsFixed(0)}%';
    final summaryText = match != null && match.usedSignaturePrimary
        ? match.summary
        : breakdownText;
    final isJoining = _joiningCommunityIds.contains(community.id);

    return AppSurface(
      color: AppColors.surface,
      borderColor: AppColors.borderSubtle,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  community.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              AppStatusPill(
                label: scoreText,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${community.category} • ${community.memberCount} members',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (community.description != null &&
              community.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              community.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
          if (summaryText != null) ...[
            const SizedBox(height: 10),
            Text(
              summaryText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewCommunity(community, userId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.grey300),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: community.isMember(userId)
                      ? null
                      : isJoining
                          ? null
                          : () => _joinCommunity(community, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.selection,
                    foregroundColor: AppColors.textInverse,
                    elevation: 0,
                  ),
                  child: isJoining
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(community.isMember(userId) ? 'Joined' : 'Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, CommunityTrueCompatibilityBreakdown>>
      _scoreCommunitiesBounded(
    List<Community> communities,
    String userId,
  ) async {
    const maxConcurrency = 6;
    if (communities.isEmpty) return const {};

    final result = <String, CommunityTrueCompatibilityBreakdown>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex++;
        if (i >= communities.length) return;
        final community = communities[i];
        try {
          final breakdown = await _communityService
              .calculateUserCommunityTrueCompatibilityBreakdown(
            communityId: community.id,
            userId: userId,
          );
          result[community.id] = breakdown;
        } catch (_) {
          // Best-effort: scores are optional for rendering.
        }
      }
    }

    final workers = <Future<void>>[];
    final n = communities.length < maxConcurrency
        ? communities.length
        : maxConcurrency;
    for (var i = 0; i < n; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
    return result;
  }

  Future<Map<String, SignatureMatchResult>> _scoreCommunityMatchesBounded({
    required List<Community> communities,
    required String userId,
    required Map<String, CommunityTrueCompatibilityBreakdown>
        fallbackBreakdowns,
  }) async {
    const maxConcurrency = 6;
    if (communities.isEmpty) return const {};

    final result = <String, SignatureMatchResult>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex++;
        if (i >= communities.length) return;
        final community = communities[i];
        final fallbackScore = fallbackBreakdowns[community.id]?.combined ?? 0.5;
        try {
          final match =
              await _communityService.calculateUserCommunitySignatureMatch(
            community: community,
            userId: userId,
            fallbackScore: fallbackScore,
          );
          if (match != null) {
            result[community.id] = match;
          }
        } catch (_) {
          // Best-effort rendering.
        }
      }
    }

    final workers = <Future<void>>[];
    final n = communities.length < maxConcurrency
        ? communities.length
        : maxConcurrency;
    for (var i = 0; i < n; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
    return result;
  }

  Future<void> _joinCommunity(Community community, String userId) async {
    setState(() {
      _joiningCommunityIds.add(community.id);
    });

    try {
      await _communityService.addMember(community, userId);
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (_entitySignatureService != null && authState is Authenticated) {
        unawaited(
          _entitySignatureService.recordCommunityJoinSignal(
            user: _toUnifiedUser(authState.user, community: community),
            community: community,
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${community.name}'),
          backgroundColor: AppColors.success,
        ),
      );

      // Keep the page responsive: remove the joined community from the list.
      setState(() {
        _communities = _communities.where((c) => c.id != community.id).toList();
        _breakdownsByCommunityId =
            Map<String, CommunityTrueCompatibilityBreakdown>.from(
          _breakdownsByCommunityId,
        )..remove(community.id);
        _joiningCommunityIds.remove(community.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joiningCommunityIds.remove(community.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _viewCommunity(Community community, String userId) {
    if (_entitySignatureService != null) {
      unawaited(
        _entitySignatureService.recordCommunityBrowseSelectionSignal(
          userId: userId,
          community: community,
        ),
      );
    }
    context.push('/community/${community.id}');
  }

  UnifiedUser _toUnifiedUser(dynamic user, {Community? community}) {
    return UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
      hasCompletedOnboarding: true,
      location: community?.localityCode ?? community?.cityCode,
    );
  }

  Widget _buildSignedOutState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.lock_outline,
          size: 56,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'Sign in to discover communities',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'We rank communities using your compatibility signals so your recommendations stay personal and relevant.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.push('/login'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.grey300),
          ),
          child: const Text(
            'Go to login',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.group_outlined,
          size: 56,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'No communities to recommend yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Once communities exist in your area/categories, they’ll show up here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(
          Icons.error_outline,
          size: 56,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _load,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.selection,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
