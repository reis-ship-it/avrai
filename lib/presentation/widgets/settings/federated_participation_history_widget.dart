/// Federated Participation History Widget
///
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
///
/// Widget showing user's participation history in federated learning:
/// - Participation history (user-specific)
/// - Contribution metrics (rounds participated, contributions made)
/// - Benefits earned from participation
/// - Participation streak
/// - Completion rate
///
/// Location: Settings/Account page (within Federated Learning section)
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/p2p/federated_learning.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

/// Widget displaying user's federated learning participation history
class FederatedParticipationHistoryWidget extends StatefulWidget {
  /// Optional override for tests/debug: preloaded participation history.
  final ParticipationHistory? participationHistory;

  /// Optional override for tests/debug: current node id.
  final String? currentNodeId;

  /// Optional override for tests/debug: federated learning system instance.
  final FederatedLearningSystem? federatedLearningSystem;

  const FederatedParticipationHistoryWidget({
    super.key,
    this.participationHistory,
    this.currentNodeId,
    this.federatedLearningSystem,
  });

  @override
  State<FederatedParticipationHistoryWidget> createState() =>
      _FederatedParticipationHistoryWidgetState();
}

class _FederatedParticipationHistoryWidgetState
    extends State<FederatedParticipationHistoryWidget> {
  late final FederatedLearningSystem _federatedLearningSystem;
  ParticipationHistory? _participationHistory;
  String? _currentNodeId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _federatedLearningSystem = widget.federatedLearningSystem ??
        (() {
          try {
            return GetIt.instance<FederatedLearningSystem>();
          } catch (_) {
            return FederatedLearningSystem();
          }
        })();

    _currentNodeId = widget.currentNodeId;

    // If tests/debug provided history, render without async load.
    if (widget.participationHistory != null) {
      _participationHistory = widget.participationHistory;
      _isLoading = false;
      _errorMessage = null;
      return;
    }

    _loadParticipationHistory();
  }

  @override
  void didUpdateWidget(
      covariant FederatedParticipationHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep local node id in sync with widget overrides.
    if (widget.currentNodeId != oldWidget.currentNodeId) {
      _currentNodeId = widget.currentNodeId;
    }

    // Support test/debug overrides updating across rebuilds.
    if (widget.participationHistory != oldWidget.participationHistory) {
      if (widget.participationHistory != null) {
        setState(() {
          _participationHistory = widget.participationHistory;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (oldWidget.participationHistory != null &&
          widget.participationHistory == null) {
        // Transition back to live loading mode.
        _loadParticipationHistory();
      }
    }
  }

  Future<void> _loadParticipationHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID as node ID
      if (_currentNodeId == null) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          _currentNodeId = authState.user.id;
        }
      }

      if (_currentNodeId == null) {
        // In widget-test contexts (or signed-out UX), treat "no user" as
        // "no history yet" rather than an error state.
        if (mounted) {
          setState(() {
            _participationHistory = null;
            _isLoading = false;
            _errorMessage = null;
          });
        }
        return;
      }

      // Fetch participation history from backend
      final history = await _federatedLearningSystem
          .getParticipationHistory(_currentNodeId!);

      if (mounted) {
        setState(() {
          _participationHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load participation history: ${e.toString()}';
          _isLoading = false;
          _participationHistory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: spacing.md),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppColors.electricGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Participation History',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_participationHistory == null)
                _buildEmptyState()
              else
                _buildHistoryContent(_participationHistory!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.electricGreen,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'An error occurred',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadParticipationHistory,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No participation history yet. Start participating in federated learning rounds to see your contributions here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(ParticipationHistory history) {
    final spacing = context.spacing;
    final completionRate = history.completionRate;
    final completionColor = _getCompletionColor(completionRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Rounds',
                '${history.totalRoundsParticipated}',
                Icons.sync,
                AppColors.electricGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${history.completedRounds}',
                Icons.check_circle,
                AppColors.electricGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Contributions',
                '${history.totalContributions}',
                Icons.upload,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Streak',
                '${history.participationStreak}',
                Icons.local_fire_department,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Completion Rate
        Container(
          padding: EdgeInsets.all(spacing.sm),
          decoration: BoxDecoration(
            color: completionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: completionColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion Rate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    '${(completionRate * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: completionColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completionRate,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(completionColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Last Participation
        if (history.lastParticipationDate != null) ...[
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last participation: ${_formatDate(history.lastParticipationDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Benefits Earned
        Text(
          'Benefits Earned',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        if (history.benefitsEarned.isEmpty)
          Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No benefits earned yet. Continue participating to unlock benefits!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...history.benefitsEarned
              .map((benefit) => _buildBenefitItem(benefit)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    final spacing = context.spacing;
    return Container(
      margin: EdgeInsets.only(bottom: spacing.xs),
      padding: EdgeInsets.all(spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            size: 16,
            color: AppColors.electricGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 0.9) return AppColors.electricGreen;
    if (rate >= 0.7) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
