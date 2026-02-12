/// Federated Learning Status Widget
/// 
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// 
/// Widget showing active learning rounds, participation status, and progress:
/// - Active learning rounds display
/// - Participation status (whether user is participating)
/// - Round progress indicators
/// - Round status (initializing, training, aggregating, completed, failed)
/// 
/// Location: Settings/Account page (within Federated Learning section)
/// Uses AppColors for consistent styling per design token requirements.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/p2p/federated_learning.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/standard_error_widget.dart';
import 'package:avrai/presentation/widgets/common/standard_loading_widget.dart';

/// Widget displaying federated learning round status and participation
class FederatedLearningStatusWidget extends StatefulWidget {
  /// Optional override for tests/debug: preloaded active rounds.
  final List<FederatedLearningRound>? activeRounds;

  /// Optional override for tests/debug: current node id.
  final String? currentNodeId;

  /// Optional override for tests/debug: federated learning system instance.
  final FederatedLearningSystem? federatedLearningSystem;

  const FederatedLearningStatusWidget({
    super.key,
    this.activeRounds,
    this.currentNodeId,
    this.federatedLearningSystem,
  });

  @override
  State<FederatedLearningStatusWidget> createState() => _FederatedLearningStatusWidgetState();
}

class _FederatedLearningStatusWidgetState extends State<FederatedLearningStatusWidget> {
  late final FederatedLearningSystem _federatedLearningSystem;
  List<FederatedLearningRound> _activeRounds = [];
  String? _currentNodeId;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  final Map<String, bool> _actionInProgress = {}; // Track join/leave actions per round

  @override
  void initState() {
    super.initState();
    _federatedLearningSystem = widget.federatedLearningSystem ??
        (() {
          // Use dependency injection to get FederatedLearningSystem
          try {
            return GetIt.instance<FederatedLearningSystem>();
          } catch (_) {
            // Fallback if not registered in DI (shouldn't happen in production)
            return FederatedLearningSystem();
          }
        })();

    _currentNodeId = widget.currentNodeId;

    // If tests/debug provided rounds, render without async loading/timers.
    if (widget.activeRounds != null) {
      _activeRounds = widget.activeRounds!;
      _isLoading = false;
      _errorMessage = null;
      return;
    }

    _loadActiveRounds();
    // Set up periodic refresh (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadActiveRounds();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FederatedLearningStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Keep local node id in sync with widget overrides.
    if (widget.currentNodeId != oldWidget.currentNodeId) {
      _currentNodeId = widget.currentNodeId;
    }

    // Support test/debug overrides updating across rebuilds.
    if (widget.activeRounds != oldWidget.activeRounds) {
      if (widget.activeRounds != null) {
        _refreshTimer?.cancel();
        _refreshTimer = null;

        setState(() {
          _activeRounds = widget.activeRounds!;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (oldWidget.activeRounds != null && widget.activeRounds == null) {
        // Transition back to live loading mode.
        _loadActiveRounds();
        _refreshTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
          if (mounted) {
            _loadActiveRounds();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveRounds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID as node ID (unless provided by widget override)
      if (_currentNodeId == null) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          _currentNodeId = authState.user.id;
        }
      }

      // Fetch active rounds from backend
      final activeRounds = await _federatedLearningSystem.getActiveRounds(_currentNodeId);
      
      if (mounted) {
        setState(() {
          _activeRounds = activeRounds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load active rounds: ${e.toString()}';
          _isLoading = false;
          _activeRounds = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sync,
                    color: AppColors.electricGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Learning Round Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showLearningRoundInfoDialog(context),
                  tooltip: 'What is a learning round?',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_activeRounds.isEmpty)
              _buildNoActiveRoundsMessage()
            else
              ..._activeRounds.map((round) => _buildRoundCard(round)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return StandardLoadingWidget.container(
      message: 'Loading active rounds...',
    );
  }

  Widget _buildErrorState() {
    return StandardErrorWidget(
      message: _errorMessage ?? 'An error occurred',
      onRetry: _loadActiveRounds,
    );
  }

  Widget _buildNoActiveRoundsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active learning rounds at the moment. Rounds start when enough participants join.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(FederatedLearningRound round) {
    final isParticipating = _currentNodeId != null &&
        round.participantNodeIds.contains(_currentNodeId);
    final progress = _calculateProgress(round);
    final statusColor = _getStatusColor(round.status);
    final statusText = _getStatusText(round.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Round ${round.roundNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildParticipationBadge(isParticipating),
            ],
          ),
          const SizedBox(height: 8),
          // Learning objective/topic
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.electricGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getObjectiveIcon(round.objective.type),
                  size: 16,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning: ${round.objective.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (round.objective.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          round.objective.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${round.participantNodeIds.length} participant${round.participantNodeIds.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(round.globalModel.accuracy * 100).toStringAsFixed(1)}% accuracy',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Join/Leave button
          if (_currentNodeId != null && 
              round.status != RoundStatus.completed && 
              round.status != RoundStatus.failed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildJoinLeaveButton(round, isParticipating),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinLeaveButton(FederatedLearningRound round, bool isParticipating) {
    final isActionInProgress = _actionInProgress[round.roundId] ?? false;
    final canJoin = !isParticipating && 
        round.status != RoundStatus.completed && 
        round.status != RoundStatus.failed;
    final canLeave = isParticipating && 
        round.status != RoundStatus.completed && 
        round.status != RoundStatus.failed;

    if (!canJoin && !canLeave) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: isActionInProgress
          ? null
          : () {
              if (isParticipating) {
                _leaveRound(round);
              } else {
                _joinRound(round);
              }
            },
      icon: isActionInProgress
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
              ),
            )
          : Icon(
              isParticipating ? Icons.exit_to_app : Icons.login,
              size: 18,
            ),
      label: Text(
        isActionInProgress
            ? (isParticipating ? 'Leaving...' : 'Joining...')
            : (isParticipating ? 'Leave Round' : 'Join Round'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isParticipating ? AppColors.error : AppColors.electricGreen,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _joinRound(FederatedLearningRound round) async {
    if (_currentNodeId == null) {
      _showError('Please sign in to join learning rounds');
      return;
    }

    setState(() {
      _actionInProgress[round.roundId] = true;
    });

    try {
      await _federatedLearningSystem.joinRound(round.roundId, _currentNodeId!);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined learning round'),
            backgroundColor: AppColors.electricGreen,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Reload rounds to reflect changes
        await _loadActiveRounds();
      }
    } catch (e) {
      developer.log('Error joining round: $e', name: 'FederatedLearningStatusWidget');
      if (mounted) {
        _showError('Failed to join round: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress[round.roundId] = false;
        });
      }
    }
  }

  Future<void> _leaveRound(FederatedLearningRound round) async {
    if (_currentNodeId == null) {
      _showError('Please sign in to leave learning rounds');
      return;
    }

    // Confirm before leaving
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Leave Learning Round?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to leave this learning round? Your contributions will be lost.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _actionInProgress[round.roundId] = true;
    });

    try {
      await _federatedLearningSystem.leaveRound(round.roundId, _currentNodeId!);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left learning round'),
            backgroundColor: AppColors.textSecondary,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Reload rounds to reflect changes
        await _loadActiveRounds();
      }
    } catch (e) {
      developer.log('Error leaving round: $e', name: 'FederatedLearningStatusWidget');
      if (mounted) {
        _showError('Failed to leave round: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress[round.roundId] = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildParticipationBadge(bool isParticipating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isParticipating
            ? AppColors.electricGreen.withValues(alpha: 0.1)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isParticipating ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isParticipating
                ? AppColors.electricGreen
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isParticipating ? 'Participating' : 'Not participating',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isParticipating
                  ? AppColors.electricGreen
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(FederatedLearningRound round) {
    // Calculate progress based on status and participant updates
    switch (round.status) {
      case RoundStatus.initializing:
        return 0.1;
      case RoundStatus.training:
        // Progress based on how many participants have submitted updates
        final updateCount = round.participantUpdates.length;
        final participantCount = round.participantNodeIds.length;
        if (participantCount == 0) return 0.2;
        return 0.2 + (updateCount / participantCount) * 0.6;
      case RoundStatus.aggregating:
        return 0.9;
      case RoundStatus.completed:
        return 1.0;
      case RoundStatus.failed:
        return 0.0;
    }
  }

  Color _getStatusColor(RoundStatus status) {
    switch (status) {
      case RoundStatus.initializing:
        return AppColors.textSecondary;
      case RoundStatus.training:
        return AppColors.electricGreen;
      case RoundStatus.aggregating:
        return AppColors.primary;
      case RoundStatus.completed:
        return AppColors.electricGreen;
      case RoundStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText(RoundStatus status) {
    switch (status) {
      case RoundStatus.initializing:
        return 'Initializing';
      case RoundStatus.training:
        return 'Training';
      case RoundStatus.aggregating:
        return 'Aggregating';
      case RoundStatus.completed:
        return 'Completed';
      case RoundStatus.failed:
        return 'Failed';
    }
  }

  IconData _getObjectiveIcon(LearningType type) {
    switch (type) {
      case LearningType.recommendation:
        return Icons.recommend;
      case LearningType.classification:
        return Icons.category;
      case LearningType.clustering:
        return Icons.group_work;
      case LearningType.prediction:
        return Icons.trending_up;
    }
  }

  void _showLearningRoundInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.sync,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'What is a Learning Round?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A learning round is a cycle in federated learning where the AI improves through collaborative training.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How it works:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('1. Initialization', 'A global AI model is created and distributed to participants'),
              _buildInfoItem('2. Local Training', 'Each device trains the model on local data (data never leaves your device)'),
              _buildInfoItem('3. Update Sharing', 'Only model updates (patterns), not raw data, are sent'),
              _buildInfoItem('4. Aggregation', 'Updates from all participants are combined to improve the global model'),
              _buildInfoItem('5. Distribution', 'The improved model is sent back to your device'),
              _buildInfoItem('6. Repeat', 'Process repeats until model converges (stops improving)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Think of it like: A group of chefs sharing recipe improvements without sharing their secret ingredients.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.electricGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.electricGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
