import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  // Notification preferences - would normally be stored in user preferences
  bool _spotRecommendations = true;
  bool _listRespects = true;
  bool _communityActivity = false;
  bool _nearbySpots = true;
  bool _aiLearningUpdates = false;
  bool _weeklyDigest = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _quietHours = true;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Notifications',
      scrollable: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Note
            const AppSurface(
              color: AppColors.grey100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Privacy First',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You control notification delivery, quiet hours, and how AVRAI uses your activity for updates.',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Notification Types
            const AppPageHeader(
              title: 'Notification Types',
              subtitle:
                  'Choose which updates you receive and how they should reach you during the beta.',
              leadingIcon: Icons.notifications_outlined,
            ),
            const SizedBox(height: 16),

            _buildNotificationTile(
              'Spot Recommendations',
              'Get notified about spots you might love',
              _spotRecommendations,
              (value) => setState(() => _spotRecommendations = value),
              Icons.location_on,
            ),

            _buildNotificationTile(
              'List Respects',
              'Know when someone respects your lists',
              _listRespects,
              (value) => setState(() => _listRespects = value),
              Icons.favorite,
            ),

            _buildNotificationTile(
              'Nearby Spots',
              'Discover spots near your current location',
              _nearbySpots,
              (value) => setState(() => _nearbySpots = value),
              Icons.near_me,
            ),

            _buildNotificationTile(
              'Community Activity',
              'Updates from your community networks',
              _communityActivity,
              (value) => setState(() => _communityActivity = value),
              Icons.group,
            ),

            _buildNotificationTile(
              'AI Learning Updates',
              'Learn about your AI personality improvements',
              _aiLearningUpdates,
              (value) => setState(() => _aiLearningUpdates = value),
              Icons.psychology,
            ),

            _buildNotificationTile(
              'Weekly Digest',
              'Summary of your week in spots and discoveries',
              _weeklyDigest,
              (value) => setState(() => _weeklyDigest = value),
              Icons.email,
            ),

            const SizedBox(height: 24),

            // Delivery Methods
            Text(
              'Delivery Methods',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildNotificationTile(
              'Push Notifications',
              'Instant notifications on your device',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
              Icons.notifications,
            ),

            _buildNotificationTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
              Icons.email_outlined,
            ),

            const SizedBox(height: 24),

            // Quiet Hours
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            AppSurface(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Quiet Hours'),
                    subtitle: const Text(
                        'Pause notifications during specified hours'),
                    value: _quietHours,
                    onChanged: (value) => setState(() => _quietHours = value),
                    secondary: const Icon(Icons.bedtime),
                  ),
                  if (_quietHours) ...[
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(_quietStart.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectTime(context, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(_quietEnd.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test Notification
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a test notification to verify your settings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Notification'),
                    // Use global ElevatedButtonTheme
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return AppSurface(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietStart : _quietEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your notification panel.'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // In a real app, this would trigger an actual test notification
    // For now, we'll just show the snackbar
  }
}
