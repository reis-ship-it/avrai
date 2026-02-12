// Knot Matching Tab
//
// Admin tab for analyzing knot matching insights
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/admin/knot_admin_service.dart';
import 'package:avrai/core/theme/colors.dart';

/// Tab for analyzing knot matching insights
class KnotMatchingTab extends StatefulWidget {
  const KnotMatchingTab({super.key});

  @override
  State<KnotMatchingTab> createState() => _KnotMatchingTabState();
}

class _KnotMatchingTabState extends State<KnotMatchingTab> {
  final _knotAdminService = GetIt.instance<KnotAdminService>();
  Map<String, dynamic>? _matchingInsights;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatchingInsights();
  }

  Future<void> _loadMatchingInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insights = await _knotAdminService.getMatchingInsights();

      setState(() {
        _matchingInsights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadMatchingInsights,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatchingInsights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _matchingInsights == null
                  ? const Center(child: Text('No matching insights available'))
                  : _buildMatchingContent(),
    );
  }

  Widget _buildMatchingContent() {
    final insights = _matchingInsights!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Overview Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matching Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  'Total Matches',
                  '${insights['totalMatches'] ?? 0}',
                  Icons.favorite,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Average Matching Score',
                  (insights['averageMatchingScore'] as num? ?? 0.0).toStringAsFixed(3),
                  Icons.star,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Average Integrated Compatibility',
                  (insights['integratedCompatibilityAverage'] as num? ?? 0.0).toStringAsFixed(3),
                  Icons.link,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Compatibility Comparison
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibility Comparison',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildCompatibilityBar(
                  'Quantum Compatibility',
                  insights['quantumCompatibilityAverage'] as num? ?? 0.0,
                  AppColors.primary,
                ),
                const SizedBox(height: 8),
                _buildCompatibilityBar(
                  'Knot Compatibility',
                  insights['knotCompatibilityAverage'] as num? ?? 0.0,
                  AppColors.electricGreen,
                ),
                const SizedBox(height: 8),
                _buildCompatibilityBar(
                  'Integrated Compatibility',
                  insights['integratedCompatibilityAverage'] as num? ?? 0.0,
                  AppColors.warning,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Success Rate by Knot Type
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Rate by Knot Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if ((insights['successRateByKnotType'] as Map?)?.isEmpty ??
                    true)
                  const Text('No knot type data available')
                else
                  ...(insights['successRateByKnotType'] as Map<String, dynamic>)
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key),
                                    Text(
                                      '${((entry.value as num) * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (entry.value as num).toDouble(),
                                  backgroundColor: AppColors.grey200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Top Matching Patterns
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Matching Patterns',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if ((insights['topMatchingPatterns'] as List?)?.isEmpty ?? true)
                  const Text('No matching patterns available')
                else
                  ...(insights['topMatchingPatterns'] as List<dynamic>)
                      .take(5)
                      .map((pattern) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: const Icon(Icons.pattern),
                              title: Text(pattern['description'] ?? 'Pattern'),
                              subtitle: Text(
                                'Strength: ${(pattern['strength'] as num? ?? 0.0).toStringAsFixed(3)}',
                              ),
                            ),
                          )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityBar(String label, num value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(3),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value.clamp(0.0, 1.0).toDouble(),
          backgroundColor: AppColors.grey200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
