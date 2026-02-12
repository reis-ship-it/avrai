// Learning Analytics Page for Phase 11: User-AI Interaction Update
// Section 8: Learning Quality Monitoring
// Dashboard to visualize learning quality and dimension improvements over time

import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Learning Analytics Page
///
/// Dashboard to visualize learning quality:
/// - Dimension improvements over time
/// - Detects when interactions fail to improve metrics
/// - Suggests which signals to capture next
///
/// Phase 11 Section 8: Learning Quality Monitoring
class LearningAnalyticsPage extends StatefulWidget {
  const LearningAnalyticsPage({super.key});

  @override
  State<LearningAnalyticsPage> createState() => _LearningAnalyticsPageState();
}

class _LearningAnalyticsPageState extends State<LearningAnalyticsPage> {
  static const String _logName = 'LearningAnalyticsPage';

  final ContinuousLearningSystem _learningSystem =
      GetIt.instance<ContinuousLearningSystem>();
  final SupabaseService? _supabaseService =
      GetIt.instance.isRegistered<SupabaseService>()
          ? GetIt.instance<SupabaseService>()
          : null;

  bool _isLoading = true;
  List<LearningEvent> _learningHistory = [];
  String? _selectedDimension;

  @override
  void initState() {
    super.initState();
    _loadLearningData();
  }

  Future<void> _loadLearningData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabaseService?.currentUser?.id;
      if (userId == null) {
        developer.log('No user ID available for learning analytics',
            name: _logName);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load learning history
      final history = await _learningSystem.getLearningHistory(
        userId: userId,
        dimension: _selectedDimension,
        limit: 100,
      );

      setState(() {
        _learningHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading learning data: $e', name: _logName);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Learning Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadLearningData,
          tooltip: 'Refresh',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _learningHistory.isEmpty
              ? _buildEmptyState()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No learning data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Learning history will appear here as the AI learns',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // Dimension filter
          _buildDimensionFilter(),

          const SizedBox(height: 24),

          // Learning history list
          _buildLearningHistoryList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Calculate summary statistics from learning history
    final dimensions = <String>{};
    final improvementsByDimension = <String, List<double>>{};
    final dataSourceCounts = <String, int>{};

    for (final event in _learningHistory) {
      dimensions.add(event.dimension);
      improvementsByDimension
          .putIfAbsent(event.dimension, () => [])
          .add(event.improvement);
      dataSourceCounts[event.dataSource] =
          (dataSourceCounts[event.dataSource] ?? 0) + 1;
    }

    final avgImprovements = <String, double>{};
    for (final entry in improvementsByDimension.entries) {
      final avg =
          entry.value.fold(0.0, (sum, imp) => sum + imp) / entry.value.length;
      avgImprovements[entry.key] = avg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Events',
                '${_learningHistory.length}',
                Icons.event,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Dimensions',
                '${dimensions.length}',
                Icons.layers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Avg Improvement',
                avgImprovements.values.isNotEmpty
                    ? '${(avgImprovements.values.fold(0.0, (sum, avg) => sum + avg) / avgImprovements.length * 100).toStringAsFixed(1)}%'
                    : '0%',
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Data Sources',
                '${dataSourceCounts.length}',
                Icons.data_usage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionFilter() {
    final dimensions = _learningHistory.map((e) => e.dimension).toSet().toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Dimension',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip('All', _selectedDimension == null, () {
              setState(() {
                _selectedDimension = null;
              });
              _loadLearningData();
            }),
            ...dimensions.map((dimension) => _buildFilterChip(
                  dimension.replaceAll('_', ' '),
                  _selectedDimension == dimension,
                  () {
                    setState(() {
                      _selectedDimension = dimension;
                    });
                    _loadLearningData();
                  },
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildLearningHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._learningHistory
            .take(50)
            .map((event) => _buildLearningEventCard(event)),
      ],
    );
  }

  Widget _buildLearningEventCard(LearningEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getImprovementColor(event.improvement),
          child: Icon(
            _getImprovementIcon(event.improvement),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.dimension.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          'Source: ${event.dataSource.replaceAll('_', ' ')}\n'
          'Time: ${_formatTimestamp(event.timestamp)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${(event.improvement * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getImprovementColor(event.improvement),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Color _getImprovementColor(double improvement) {
    if (improvement > 0.05) {
      return Colors.green;
    } else if (improvement > 0.02) {
      return Colors.blue;
    } else if (improvement > 0) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  IconData _getImprovementIcon(double improvement) {
    if (improvement > 0.05) {
      return Icons.trending_up;
    } else if (improvement > 0.02) {
      return Icons.trending_flat;
    } else {
      return Icons.trending_down;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
