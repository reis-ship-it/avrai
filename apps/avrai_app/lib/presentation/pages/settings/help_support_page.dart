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
        sendFeedback: () =>
            _launchEmail('feedback@avrai.app', subject: 'AVRAI Feedback'),
        reportBug: () =>
            _launchEmail('bugs@avrai.app', subject: 'AVRAI Bug Report'),
        emailSupport: () =>
            _launchEmail('support@avrai.app', subject: 'AVRAI Support'),
        openCommunityForum: () => _launchUrl('https://avrai.app/community'),
        openVideoTutorials: () => _launchUrl('https://avrai.app/tutorials'),
        openUserGuide: () => _launchUrl('https://avrai.app/guide'),
        showWhatsNew: () => _launchUrl('https://avrai.app/updates'),
        showPrinciples: () => _launchUrl('https://avrai.app/principles'),
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

  Future<void> _launchEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject == null ? null : {'subject': subject},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
