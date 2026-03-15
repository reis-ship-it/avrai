import 'package:flutter/material.dart';
import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/knot_privacy_settings_page_schema.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

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
    setState(() {
      _showKnotPublicly = false;
      _friendKnotContext = KnotContext.friends;
      _publicKnotContext = KnotContext.anonymous;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildKnotPrivacySettingsPageSchema(
        showKnotPublicly: _showKnotPublicly,
        friendContext: _getContextLabel(_friendKnotContext),
        publicContext: _getContextLabel(_publicKnotContext),
        contextOptions: KnotContext.values.map(_getContextLabel).toList(),
        onShowKnotPubliclyChanged: (value) {
          setState(() {
            _showKnotPublicly = value;
          });
        },
        onFriendContextChanged: (value) {
          if (value == null) return;
          setState(() {
            _friendKnotContext = _parseContext(value);
          });
        },
        onPublicContextChanged: (value) {
          if (value == null) return;
          setState(() {
            _publicKnotContext = _parseContext(value);
          });
        },
      ),
    );
  }

  KnotContext _parseContext(String label) {
    return KnotContext.values.firstWhere(
      (context) => _getContextLabel(context) == label,
      orElse: () => KnotContext.anonymous,
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
