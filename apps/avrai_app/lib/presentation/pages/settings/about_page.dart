import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/about_page_schema.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildAboutPageSchema(
        openWebsite: () => _launchUrl('https://avrai.app'),
        openPrinciples: () => _launchUrl('https://avrai.app/principles'),
        openPrivacy: () => _launchUrl('https://avrai.app/privacy'),
        openTerms: () => _launchUrl('https://avrai.app/terms'),
        openSupport: () => _launchEmail('support@avrai.app'),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
