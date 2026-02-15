import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/models/events/event_template.dart';
import 'package:avrai/core/services/events/event_template_service.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// Template Selection Widget
/// Agent 2: Event Discovery & Hosting UI (Week 3, Task 2.9)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Display available templates
/// - Template cards with preview
/// - Filter by category
/// - Show popular templates
/// - "Use Template" button
class TemplateSelectionWidget extends StatefulWidget {
  final Function(EventTemplate) onTemplateSelected;
  final String? selectedCategory;
  final bool showBusinessTemplates;

  const TemplateSelectionWidget({
    super.key,
    required this.onTemplateSelected,
    this.selectedCategory,
    this.showBusinessTemplates = false,
  });

  @override
  State<TemplateSelectionWidget> createState() =>
      _TemplateSelectionWidgetState();
}

class _TemplateSelectionWidgetState extends State<TemplateSelectionWidget> {
  final EventTemplateService _templateService = EventTemplateService();
  List<EventTemplate> _allTemplates = [];
  List<EventTemplate> _filteredTemplates = [];
  String? _selectedCategoryFilter;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() {
      if (widget.showBusinessTemplates) {
        _allTemplates = _templateService.getBusinessTemplates();
      } else {
        _allTemplates = _templateService.getExpertTemplates();
      }

      // Apply initial category filter if provided
      if (widget.selectedCategory != null) {
        _selectedCategoryFilter = widget.selectedCategory;
      }

      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = List<EventTemplate>.from(_allTemplates);

    // Apply category filter
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((t) =>
              t.category.toLowerCase() ==
              _selectedCategoryFilter!.toLowerCase())
          .toList();
    }

    // Apply search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query) ||
            t.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    setState(() {
      _filteredTemplates = filtered;
    });
  }

  List<String> _getAvailableCategories() {
    final categories = _allTemplates.map((t) => t.category).toSet().toList();
    categories.sort();
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(spacing.md),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textHint),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textPrimary),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isEmpty ? null : value;
              });
              _applyFilters();
            },
          ),
        ),

        // Category Filters
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                const SizedBox(width: 8),
                ..._getAvailableCategories().map((category) {
                  return Padding(
                    padding: EdgeInsets.only(right: spacing.xs),
                    child: _buildCategoryChip(category, category),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Template List
        Expanded(
          child: _buildTemplateList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategoryFilter == category;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryFilter = selected ? category : null;
        });
        _applyFilters();
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.primaryColor : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
    );
  }

  Widget _buildTemplateList() {
    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery != null || _selectedCategoryFilter != null
                  ? 'Try adjusting your filters'
                  : 'Templates will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.spacing.md),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(EventTemplate template) {
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.md),
      child: InkWell(
        onTap: () {
          widget.onTemplateSelected(template);
        },
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon and Title
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.spacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.icon,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.category,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Price Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.xs,
                      vertical: context.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: template.isFree
                          ? AppColors.electricGreen.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.getPriceDisplay(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: template.isFree
                                ? AppColors.electricGreen
                                : AppTheme.primaryColor,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description Preview
              Text(
                template.descriptionTemplate.length > 150
                    ? '${template.descriptionTemplate.substring(0, 150)}...'
                    : template.descriptionTemplate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Template Details
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${template.defaultDuration.inHours}h ${template.defaultDuration.inMinutes % 60}m',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Up to ${template.defaultMaxAttendees}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (template.recommendedSpotCount > 0) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.place,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${template.recommendedSpotCount} ${template.recommendedSpotCount == 1 ? 'spot' : 'spots'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),

              // Tags
              if (template.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: template.tags.take(3).map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacing.xs,
                        vertical: context.spacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Use Template Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onTemplateSelected(template);
                  },
                  icon: const Icon(Icons.event_available, size: 18),
                  label: Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
