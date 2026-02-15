// Knot Privacy Settings Page
//
// UI for managing knot privacy settings
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 7: Audio & Privacy

import 'package:flutter/material.dart';
import 'package:avrai_knot/services/knot/knot_privacy_service.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Settings page for knot privacy controls
class KnotPrivacySettingsPage extends StatefulWidget {
  const KnotPrivacySettingsPage({super.key});

  @override
  State<KnotPrivacySettingsPage> createState() =>
      _KnotPrivacySettingsPageState();
}

class _KnotPrivacySettingsPageState extends State<KnotPrivacySettingsPage> {
  bool _showKnotPublicly = false;
  KnotContext _friendKnotContext = KnotContext.friends;
  KnotContext _publicKnotContext = KnotContext.anonymous;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    // TODO: Load from storage/preferences
    // For now, use defaults
    setState(() {
      _showKnotPublicly = false;
      _friendKnotContext = KnotContext.friends;
      _publicKnotContext = KnotContext.anonymous;
    });
  }

  Future<void> _updatePrivacySetting(bool value) async {
    setState(() {
      _showKnotPublicly = value;
    });
    // TODO: Save to storage/preferences
  }

  Future<void> _updateFriendContext(KnotContext? value) async {
    if (value == null) return;
    setState(() {
      _friendKnotContext = value;
    });
    // TODO: Save to storage/preferences
  }

  Future<void> _updatePublicContext(KnotContext? value) async {
    if (value == null) return;
    setState(() {
      _publicKnotContext = value;
    });
    // TODO: Save to storage/preferences
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'Knot Privacy Settings',
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          Text(
            'Control how your personality knot is shared with others',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacing.lg),
          SwitchListTile(
            title: const Text('Show knot publicly'),
            subtitle: const Text('Allow others to see your knot'),
            value: _showKnotPublicly,
            onChanged: _updatePrivacySetting,
          ),
          const Divider(),
          ListTile(
            title: const Text('Knot context for friends'),
            subtitle: const Text('Choose knot detail level for friends'),
            trailing: DropdownButton<KnotContext>(
              value: _friendKnotContext,
              items: KnotContext.values.map((ctx) {
                return DropdownMenuItem(
                  value: ctx,
                  child: Text(_getContextLabel(ctx)),
                );
              }).toList(),
              onChanged: _updateFriendContext,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Knot context for public'),
            subtitle: const Text('Choose knot detail level for public viewing'),
            trailing: DropdownButton<KnotContext>(
              value: _publicKnotContext,
              items: KnotContext.values.map((ctx) {
                return DropdownMenuItem(
                  value: ctx,
                  child: Text(_getContextLabel(ctx)),
                );
              }).toList(),
              onChanged: _updatePublicContext,
            ),
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Privacy Levels:',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing.xs),
          _buildPrivacyLevelInfo(KnotContext.public, 'Full knot visible'),
          _buildPrivacyLevelInfo(
              KnotContext.friends, 'Visible to friends only'),
          _buildPrivacyLevelInfo(KnotContext.private, 'Private (not shared)'),
          _buildPrivacyLevelInfo(
            KnotContext.anonymous,
            'Topology-only (no personal info)',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyLevelInfo(KnotContext context, String description) {
    final spacing = this.context.spacing;
    final textTheme = Theme.of(this.context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ${_getContextLabel(context)}: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }

  String _getContextLabel(KnotContext context) {
    switch (context) {
      case KnotContext.public:
        return 'Public';
      case KnotContext.friends:
        return 'Friends';
      case KnotContext.private:
        return 'Private';
      case KnotContext.anonymous:
        return 'Anonymous';
    }
  }
}
