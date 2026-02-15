import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/presentation/widgets/common/standard_error_widget.dart';
import 'package:avrai/presentation/widgets/common/standard_loading_widget.dart';

/// Border visualization panel for **flutter_map** (iOS fallback, Windows/Linux/Web).
///
/// Uses [GeoHierarchyService.getLocalityPolygon] for real boundaries. Same panel
/// UI as [BorderVisualizationWidget]; map overlay is drawn by the parent (MapView).
class BorderVisualizationWidgetFlutterMap extends StatefulWidget {
  /// flutter_map controller (optional; for future map interactions).
  final MapController? mapController;

  final String? locality;
  final String? localityCode;
  final String city;
  final bool showSoftBorderSpots;
  final bool showRefinementIndicators;
  final void Function(String locality1, String locality2)? onBorderTapped;
  final void Function(String spotId)? onSoftBorderSpotTapped;
  final double? height;
  final double? width;

  const BorderVisualizationWidgetFlutterMap({
    super.key,
    this.mapController,
    this.locality,
    this.localityCode,
    required this.city,
    this.showSoftBorderSpots = true,
    this.showRefinementIndicators = true,
    this.onBorderTapped,
    this.onSoftBorderSpotTapped,
    this.height,
    this.width,
  });

  @override
  State<BorderVisualizationWidgetFlutterMap> createState() =>
      _BorderVisualizationWidgetFlutterMapState();
}

class _BorderVisualizationWidgetFlutterMapState
    extends State<BorderVisualizationWidgetFlutterMap> {
  final AppLogger _logger = const AppLogger(
    defaultTag: 'avrai',
    minimumLevel: LogLevel.debug,
  );
  final GeoHierarchyService _geoHierarchyService = GeoHierarchyService();

  bool _isLoading = true;
  String? _error;
  final List<_BoundaryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadBoundaries();
  }

  @override
  void didUpdateWidget(
      covariant BorderVisualizationWidgetFlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localityCode != widget.localityCode ||
        oldWidget.city != widget.city) {
      _loadBoundaries();
    }
  }

  Future<void> _loadBoundaries() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items.clear();
    });

    final localityCode = widget.localityCode;
    if (localityCode == null || localityCode.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final poly = await _geoHierarchyService.getLocalityPolygon(
        localityCode: localityCode,
        simplifyTolerance: 0.01,
      );

      if (!mounted) return;
      if (poly == null || poly.rings.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final displayName =
          widget.locality ?? localityCode.split('-').last.replaceAll('_', ' ');

      _items.add(_BoundaryItem(
        id: 'locality:$localityCode',
        name: displayName,
        subtitle: 'Locality boundary',
      ));

      setState(() => _isLoading = false);
    } catch (e, st) {
      _logger.error('Error loading boundaries', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load boundaries';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_items.isEmpty) return _buildEmpty();
    return _buildPanel();
  }

  Widget _buildLoading() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StandardLoadingWidget.container(
        message: 'Loading boundaries...',
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpaceLg),
          child: StandardErrorWidget(
            message: _error ?? 'Error loading boundaries',
            onRetry: _loadBoundaries,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final message = widget.localityCode == null
        ? 'Select a locality to view boundaries.'
        : 'No boundaries available';
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              color: AppColors.grey400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                Text(
                  'Hard Borders',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                ..._items.map((item) => _buildCard(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Hard Border', AppTheme.primaryColor, isSpot: false),
          _legendItem('Soft Border', AppColors.grey600, isSpot: false),
          if (widget.showSoftBorderSpots)
            _legendItem('Soft Spot', AppColors.warning, isSpot: true),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {bool isSpot = false}) {
    return Row(
      children: [
        if (isSpot)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(color: color),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildCard(_BoundaryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: kSpaceXs),
      child: ListTile(
        leading: Icon(
          Icons.border_clear,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        subtitle: Text(
          item.subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        onTap: widget.onBorderTapped != null
            ? () => widget.onBorderTapped!(item.name, item.subtitle)
            : null,
      ),
    );
  }
}

class _BoundaryItem {
  final String id;
  final String name;
  final String subtitle;

  _BoundaryItem({
    required this.id,
    required this.name,
    required this.subtitle,
  });
}
