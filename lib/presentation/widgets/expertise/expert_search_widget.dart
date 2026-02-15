import 'package:flutter/material.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/services/expertise/expert_search_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/expertise/expertise_pin_widget.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Expert Search Widget
/// UI for searching and finding experts
class ExpertSearchWidget extends StatefulWidget {
  final String? initialCategory;
  final String? initialLocation;
  final Function(UnifiedUser)? onExpertSelected;

  const ExpertSearchWidget({
    super.key,
    this.initialCategory,
    this.initialLocation,
    this.onExpertSelected,
  });

  @override
  State<ExpertSearchWidget> createState() => _ExpertSearchWidgetState();
}

class _ExpertSearchWidgetState extends State<ExpertSearchWidget> {
  final ExpertSearchService _searchService = ExpertSearchService();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<ExpertSearchResult> _results = [];
  bool _isLoading = false;
  ExpertiseLevel? _selectedMinLevel;

  @override
  void initState() {
    super.initState();
    _categoryController.text = widget.initialCategory ?? '';
    _locationController.text = widget.initialLocation ?? '';
    _performSearch();
  }

  @override
  void didUpdateWidget(covariant ExpertSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep controllers in sync when parent changes initial values and the
    // widget state is reused across rebuilds (common in widget tests and lists).
    if (widget.initialCategory != oldWidget.initialCategory) {
      final next = widget.initialCategory ?? '';
      if (_categoryController.text != next) {
        _categoryController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    if (widget.initialLocation != oldWidget.initialLocation) {
      final next = widget.initialLocation ?? '';
      if (_locationController.text != next) {
        _locationController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _searchService.searchExperts(
        category:
            _categoryController.text.isEmpty ? null : _categoryController.text,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        minLevel: _selectedMinLevel,
        maxResults: 20,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Fields
        _buildSearchFields(),
        const SizedBox(height: 16),
        // Level Filter
        _buildLevelFilter(),
        const SizedBox(height: 16),
        // Results
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_results.isEmpty)
          _buildEmptyState()
        else
          _buildResultsList(),
      ],
    );
  }

  Widget _buildSearchFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: 'Category (e.g., Coffee)',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Location (optional)',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _performSearch,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.electricGreen,
            foregroundColor: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelFilter() {
    return Wrap(
      spacing: 8,
      children: [
        Text('Min Level:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        ...ExpertiseLevel.values.map((level) {
          final isSelected = _selectedMinLevel == level;
          return FilterChip(
            label: Text('${level.emoji} ${level.displayName}'),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedMinLevel = selected ? level : null;
              });
              _performSearch();
            },
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No experts found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return _buildExpertCard(result);
        },
      ),
    );
  }

  Widget _buildExpertCard(ExpertSearchResult result) {
    final user = result.user;
    final pins = user
        .getExpertisePins()
        .where((pin) => result.matchingCategories.contains(pin.category))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: kSpaceXxs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.grey200,
          child: user.photoUrl != null
              ? Image.network(user.photoUrl!)
              : Text(
                  (user.displayName ?? user.email)[0].toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
        ),
        title: Text(user.displayName ?? user.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.location != null)
              Text(
                result.location!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pins
                  .map((pin) => ExpertisePinWidget(
                        pin: pin,
                        showDetails: false,
                      ))
                  .toList(),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(result.relevanceScore * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricGreen,
                  ),
            ),
            Text(
              'match',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        onTap: () => widget.onExpertSelected?.call(user),
      ),
    );
  }
}
