import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:avrai/presentation/schema_renderer/app_schema_page.dart';
import 'package:avrai/presentation/schemas/pages/help_support_page_schema.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSchemaPage(
      schema: buildHelpSupportPageSchema(
        gettingStarted: () => _showMessage(
          context,
          'Getting Started',
          'Create a place, organize it into lists, and let recommendations improve as AVRAI learns your preferences.',
        ),
        creatingSpots: () => _showMessage(
          context,
          'Creating Spots',
          'Use the add flow to save a place, then add notes and organize it into collections.',
        ),
        managingLists: () => _showMessage(
          context,
          'Managing Lists',
          'Lists help you group places by context, purpose, or mood without losing your own logic.',
        ),
        privacyHelp: () => _showMessage(
          context,
          'Privacy & Settings',
          'Privacy settings let you control what AVRAI shares, retains, and uses for recommendations.',
        ),
        aiLearningHelp: () => _showMessage(
          context,
          'AI2AI Learning',
          'AI2AI learning exchanges anonymized signals, not raw private content.',
        ),
        sendFeedback: () => _launchUrl('https://avrai.org/support'),
        reportBug: () => _launchUrl('https://avrai.org/support'),
        emailSupport: () => _launchUrl('https://avrai.org/support'),
        openCommunityForum: () => _launchUrl('https://avrai.org/support'),
        openVideoTutorials: () => _launchUrl('https://avrai.org/support'),
        openUserGuide: () => _launchUrl('https://avrai.org/support'),
        showWhatsNew: () => _launchUrl('https://avrai.org/support'),
        showPrinciples: () => _launchUrl('https://avrai.org/principles'),
        platformName: Theme.of(context).platform.name,
        supportId:
            'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ),
    );
  }

  Future<void> _showMessage(
    BuildContext context,
    String title,
    String body,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
