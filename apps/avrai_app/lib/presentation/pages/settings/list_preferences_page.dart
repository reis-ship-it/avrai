import 'package:flutter/material.dart';
import 'package:avrai_runtime_os/services/lists/list_preference_service.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/filters/age_aware_list_filter.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

/// ListPreferencesPage - Settings page for AI-suggested list preferences
///
/// Features:
/// - Toggle categories on/off
/// - Adjust timing preferences
/// - Set exploration vs familiar balance
/// - Opt-in for sensitive categories
/// - Notification settings
///
/// Part of Phase 2.3: Preference Editing

class ListPreferencesPage extends StatefulWidget {
  final int? userAge;

  const ListPreferencesPage({
    super.key,
    this.userAge,
  });

  @override
  State<ListPreferencesPage> createState() => _ListPreferencesPageState();
}

class _ListPreferencesPageState extends State<ListPreferencesPage> {
  late ListPreferenceService _preferenceService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preferenceService = GetIt.instance<ListPreferenceService>();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _preferenceService.loadPreferences();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'List Preferences',
      constrainBody: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Timing preferences section
                _buildSectionHeader(context, 'When to suggest lists'),
                const SizedBox(height: 8),
                _buildTimeSlotToggles(context),
                const SizedBox(height: 24),

                // Frequency section
                _buildSectionHeader(context, 'Frequency'),
                const SizedBox(height: 8),
                _buildFrequencySettings(context),
                const SizedBox(height: 24),

                // Exploration balance section
                _buildSectionHeader(context, 'Exploration vs Familiar'),
                const SizedBox(height: 8),
                _buildExplorationSlider(context),
                const SizedBox(height: 24),

                // Categories section
                _buildSectionHeader(context, 'Categories'),
                const SizedBox(height: 8),
                _buildCategoryToggles(context),
                const SizedBox(height: 24),

                // Sensitive categories section (age-gated)
                if ((widget.userAge ?? 18) >= 18) ...[
                  _buildSectionHeader(context, 'Sensitive Categories'),
                  const SizedBox(height: 8),
                  _buildSensitiveCategoryToggles(context),
                  const SizedBox(height: 24),
                ],

                // Notifications section
                _buildSectionHeader(context, 'Notifications'),
                const SizedBox(height: 8),
                _buildNotificationSettings(context),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTimeSlotToggles(BuildContext context) {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: TimeSlot.values.map((slot) {
          return SwitchListTile(
            title: Text(_getTimeSlotLabel(slot)),
            subtitle: Text(_getTimeSlotDescription(slot)),
            value: _preferenceService.isTimeSlotPreferred(slot),
            onChanged: (value) async {
              await _preferenceService.setTimeSlotPreference(slot, value);
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  String _getTimeSlotLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.earlyMorning:
        return 'Early Morning';
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
      case TimeSlot.night:
        return 'Night';
      case TimeSlot.lateNight:
        return 'Late Night';
    }
  }

  String _getTimeSlotDescription(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.earlyMorning:
        return '5 AM - 8 AM';
      case TimeSlot.morning:
        return '8 AM - 12 PM';
      case TimeSlot.afternoon:
        return '12 PM - 5 PM';
      case TimeSlot.evening:
        return '5 PM - 9 PM';
      case TimeSlot.night:
        return '9 PM - 12 AM';
      case TimeSlot.lateNight:
        return '12 AM - 5 AM';
    }
  }

  Widget _buildFrequencySettings(BuildContext context) {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            title: const Text('Max lists per day'),
            subtitle: Text('Currently: ${_preferenceService.maxListsPerDay}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _preferenceService.maxListsPerDay > 1
                      ? () async {
                          await _preferenceService.setMaxListsPerDay(
                            _preferenceService.maxListsPerDay - 1,
                          );
                          setState(() {});
                        }
                      : null,
                ),
                Text('${_preferenceService.maxListsPerDay}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _preferenceService.maxListsPerDay < 10
                      ? () async {
                          await _preferenceService.setMaxListsPerDay(
                            _preferenceService.maxListsPerDay + 1,
                          );
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Minimum hours between suggestions'),
            subtitle:
                Text('Currently: ${_preferenceService.minIntervalHours} hours'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _preferenceService.minIntervalHours > 1
                      ? () async {
                          await _preferenceService.setMinIntervalHours(
                            _preferenceService.minIntervalHours - 1,
                          );
                          setState(() {});
                        }
                      : null,
                ),
                Text('${_preferenceService.minIntervalHours}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _preferenceService.minIntervalHours < 24
                      ? () async {
                          await _preferenceService.setMinIntervalHours(
                            _preferenceService.minIntervalHours + 1,
                          );
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorationSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PortalSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Familiar',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Explore',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            Slider(
              value: _preferenceService.explorationBalance,
              onChanged: (value) async {
                await _preferenceService.setExplorationBalance(value);
                setState(() {});
              },
            ),
            Text(
              _getExplorationDescription(_preferenceService.explorationBalance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getExplorationDescription(double balance) {
    if (balance < 0.3) {
      return 'Mostly familiar places you love';
    } else if (balance < 0.5) {
      return 'Lean towards familiar with some new discoveries';
    } else if (balance < 0.7) {
      return 'Balanced mix of familiar and new places';
    } else if (balance < 0.9) {
      return 'Lean towards new discoveries';
    } else {
      return 'Maximum exploration of new places';
    }
  }

  Widget _buildCategoryToggles(BuildContext context) {
    final categories = [
      'restaurants',
      'cafes',
      'bars',
      'museums',
      'parks',
      'entertainment',
      'shopping',
      'nightlife',
    ];

    return PortalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: categories.map((category) {
          return SwitchListTile(
            title: Text(_formatCategory(category)),
            value: _preferenceService.isCategoryEnabled(category),
            onChanged: (value) async {
              if (value) {
                await _preferenceService.enableCategory(category);
              } else {
                await _preferenceService.disableCategory(category);
              }
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSensitiveCategoryToggles(BuildContext context) {
    final sensitiveCategories = AgeAwareListFilter.sensitiveCategories;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PortalSurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These categories require explicit opt-in and are 18+ only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...sensitiveCategories.map((category) {
            return SwitchListTile(
              title: Text(_formatCategory(category)),
              value: _preferenceService.hasOptedIn(category),
              onChanged: (value) async {
                if (value) {
                  // Show confirmation dialog
                  final confirmed =
                      await _showOptInConfirmation(context, category);
                  if (confirmed == true) {
                    await _preferenceService.optInToCategory(category);
                  }
                } else {
                  await _preferenceService.optOutOfCategory(category);
                }
                setState(() {});
              },
            );
          }),
        ],
      ),
    );
  }

  Future<bool?> _showOptInConfirmation(BuildContext context, String category) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Opt into ${_formatCategory(category)}?'),
        content: Text(
          'This will allow AI-suggested lists to include ${_formatCategory(category).toLowerCase()} places. '
          'You can opt out at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Opt In'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        title: const Text('Push notifications'),
        subtitle: const Text('Get notified when new lists are suggested'),
        value: _preferenceService.notificationsEnabled,
        onChanged: (value) async {
          await _preferenceService.setNotificationsEnabled(value);
          setState(() {});
        },
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
