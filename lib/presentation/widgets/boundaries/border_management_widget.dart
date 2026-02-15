import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/common/standard_error_widget.dart';
import 'package:avrai/presentation/widgets/common/standard_loading_widget.dart';

/// Border Management Widget
///
/// Displays border information and management UI for neighborhood boundaries.
/// Shows doors (boundary information) that users can understand and interact with.
///
/// **Philosophy:** Make neighborhood boundaries visible and accessible.
/// Display border information clearly to help users understand community connections.
class BorderManagementWidget extends StatefulWidget {
  /// Locality 1 name (required)
  final String locality1;

  /// Locality 2 name (required)
  final String locality2;

  /// City name (required)
  final String city;

  /// Whether to show refinement history
  final bool showRefinementHistory;

  /// Whether to show soft border spots
  final bool showSoftBorderSpots;

  /// Callback when refinement is requested
  final void Function(String locality1, String locality2)? onRefineRequested;

  const BorderManagementWidget({
    super.key,
    required this.locality1,
    required this.locality2,
    required this.city,
    this.showRefinementHistory = true,
    this.showSoftBorderSpots = true,
    this.onRefineRequested,
  });

  @override
  State<BorderManagementWidget> createState() => _BorderManagementWidgetState();
}

class _BorderManagementWidgetState extends State<BorderManagementWidget> {
  final AppLogger _logger = AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  bool _isLoading = true;
  String? _error;
  BorderType? _borderType;
  List<CoordinatePoint> _coordinates = [];
  List<SoftBorderSpotInfo> _softBorderSpots = [];
  Map<String, int> _visitCounts = {};
  List<RefinementEvent> _refinementHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBorderData();
  }

  Future<void> _loadBorderData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual NeighborhoodBoundaryService when available
      // For now, use mock data to demonstrate the UI
      await Future.delayed(Duration(milliseconds: 500));

      // Mock border data
      _borderType = BorderType.softBorder;
      _coordinates = _getMockCoordinates();
      _softBorderSpots = _getMockSoftBorderSpots();
      _visitCounts = _getMockVisitCounts();
      _refinementHistory = _getMockRefinementHistory();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.error('Error loading border data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load border data';
      });
    }
  }

  List<CoordinatePoint> _getMockCoordinates() {
    return [
      CoordinatePoint(latitude: 40.7220, longitude: -73.9920),
      CoordinatePoint(latitude: 40.7220, longitude: -73.9880),
      CoordinatePoint(latitude: 40.7200, longitude: -73.9880),
      CoordinatePoint(latitude: 40.7200, longitude: -73.9920),
    ];
  }

  List<SoftBorderSpotInfo> _getMockSoftBorderSpots() {
    return [
      SoftBorderSpotInfo(
        spotId: 'spot-1',
        name: 'Cafe Example',
        visitCountLocality1: 45,
        visitCountLocality2: 32,
        dominantLocality: widget.locality1,
      ),
      SoftBorderSpotInfo(
        spotId: 'spot-2',
        name: 'Restaurant Example',
        visitCountLocality1: 28,
        visitCountLocality2: 51,
        dominantLocality: widget.locality2,
      ),
    ];
  }

  Map<String, int> _getMockVisitCounts() {
    return {
      widget.locality1: 120,
      widget.locality2: 95,
    };
  }

  List<RefinementEvent> _getMockRefinementHistory() {
    return [
      RefinementEvent(
        timestamp: DateTime.now().subtract(Duration(days: 30)),
        description: 'Border refined based on user movement patterns',
        changes: 'Spot "Cafe Example" now associated with ${widget.locality1}',
      ),
      RefinementEvent(
        timestamp: DateTime.now().subtract(Duration(days: 60)),
        description: 'Initial border detection',
        changes:
            'Soft border identified between ${widget.locality1} and ${widget.locality2}',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return _buildBorderInfo();
  }

  Widget _buildLoadingState() {
    return StandardLoadingWidget.container(
      message: 'Loading border information...',
    );
  }

  Widget _buildErrorState() {
    return StandardErrorWidget.fullScreen(
      message: _error ?? 'Error loading border information',
      onRetry: _loadBorderData,
    );
  }

  Widget _buildBorderInfo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          SizedBox(height: 24),

          // Border Type
          _buildBorderTypeCard(),
          SizedBox(height: 16),

          // Coordinates
          _buildCoordinatesCard(),
          SizedBox(height: 16),

          // Visit Counts
          _buildVisitCountsCard(),
          SizedBox(height: 16),

          // Soft Border Spots
          if (widget.showSoftBorderSpots && _softBorderSpots.isNotEmpty) ...[
            _buildSoftBorderSpotsCard(),
            SizedBox(height: 16),
          ],

          // Refinement History
          if (widget.showRefinementHistory &&
              _refinementHistory.isNotEmpty) ...[
            _buildRefinementHistoryCard(),
            SizedBox(height: 16),
          ],

          // Actions
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _borderType == BorderType.hardBorder
              ? Icons.border_clear
              : Icons.border_color,
          color: AppTheme.primaryColor,
          size: 32,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.locality1} / ${widget.locality2}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                _borderType == BorderType.hardBorder
                    ? 'Hard Border (Well-defined)'
                    : 'Soft Border (Blended Area)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBorderTypeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Border Type',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(context.spacing.sm),
              decoration: BoxDecoration(
                color: _borderType == BorderType.hardBorder
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _borderType == BorderType.hardBorder
                      ? AppTheme.primaryColor
                      : AppColors.grey300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _borderType == BorderType.hardBorder
                        ? Icons.border_clear
                        : Icons.border_color,
                    color: _borderType == BorderType.hardBorder
                        ? AppTheme.primaryColor
                        : AppColors.grey600,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _borderType == BorderType.hardBorder
                          ? 'Hard Border: Well-defined geographic boundary'
                          : 'Soft Border: Blended area shared by both localities',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Boundary Coordinates',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._coordinates.asMap().entries.map((entry) {
              final index = entry.key;
              final coord = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: context.spacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${coord.latitude.toStringAsFixed(6)}, ${coord.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCountsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Visit Counts by Locality',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._visitCounts.entries.map((entry) {
              final locality = entry.key;
              final count = entry.value;
              final total = _visitCounts.values.reduce((a, b) => a + b);
              final percentage = total > 0 ? (count / total * 100) : 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: context.spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locality,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        Text(
                          '$count visits (${percentage.toStringAsFixed(1)}%)',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          locality == widget.locality1
                              ? AppTheme.primaryColor
                              : AppColors.grey600,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftBorderSpotsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Soft Border Spots',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._softBorderSpots.map((spot) => _buildSoftBorderSpotItem(spot)),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftBorderSpotItem(SoftBorderSpotInfo spot) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  spot.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.xs,
                    vertical: context.spacing.xxs),
                decoration: BoxDecoration(
                  color: spot.dominantLocality == widget.locality1
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  spot.dominantLocality,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: spot.dominantLocality == widget.locality1
                            ? AppTheme.primaryColor
                            : AppColors.grey600,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildVisitCountItem(
                  widget.locality1,
                  spot.visitCountLocality1,
                  AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildVisitCountItem(
                  widget.locality2,
                  spot.visitCountLocality2,
                  AppColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCountItem(String locality, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(context.spacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locality,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: 4),
          Text(
            '$count visits',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinementHistoryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Refinement History',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._refinementHistory
                .map((event) => _buildRefinementEventItem(event)),
          ],
        ),
      ),
    );
  }

  Widget _buildRefinementEventItem(RefinementEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      padding: EdgeInsets.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                _formatTimestamp(event.timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          if (event.changes.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              event.changes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 12),
            if (widget.onRefineRequested != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onRefineRequested!(
                    widget.locality1,
                    widget.locality2,
                  ),
                  icon: Icon(Icons.tune),
                  label: Text('Request Border Refinement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.black,
                    padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

/// Border type enum
enum BorderType {
  hardBorder,
  softBorder,
}

/// Coordinate point model
class CoordinatePoint {
  final double latitude;
  final double longitude;

  CoordinatePoint({
    required this.latitude,
    required this.longitude,
  });
}

/// Soft border spot info model
class SoftBorderSpotInfo {
  final String spotId;
  final String name;
  final int visitCountLocality1;
  final int visitCountLocality2;
  final String dominantLocality;

  SoftBorderSpotInfo({
    required this.spotId,
    required this.name,
    required this.visitCountLocality1,
    required this.visitCountLocality2,
    required this.dominantLocality,
  });
}

/// Refinement event model
class RefinementEvent {
  final DateTime timestamp;
  final String description;
  final String changes;

  RefinementEvent({
    required this.timestamp,
    required this.description,
    required this.changes,
  });
}
