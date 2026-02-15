import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Notifications',
      scrollable: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Note
            PortalSurface(
              color: AppColors.grey100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip,
                          color: AppTheme.primaryColor),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Privacy First',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Per OUR_GUTS.md: "Privacy and Control Are Non-Negotiable". You control all notification settings and data usage.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Main Notification Types
            Text(
              'Notification Types',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

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

            SizedBox(height: spacing.lg),

            // Delivery Methods
            Text(
              'Delivery Methods',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

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

            SizedBox(height: spacing.lg),

            // Quiet Hours
            Text(
              'Quiet Hours',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
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

            SizedBox(height: spacing.lg),

            // Test Notification
            PortalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Notifications',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'Send a test notification to verify your settings',
                    style: textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.md),
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
    final spacing = context.spacing;

    return PortalSurface(
      margin: EdgeInsets.only(bottom: spacing.xs),
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
    context
        .showSuccess('Test notification sent! Check your notification panel.');

    // In a real app, this would trigger an actual test notification.
  }
}
