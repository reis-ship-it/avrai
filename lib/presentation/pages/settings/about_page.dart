import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return AdaptivePlatformPageScaffold(
      title: 'About avrai',
      scrollable: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      Icons.place,
                      size: 60,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'avrai',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'know you belong.',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.grey600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl),

            // OUR_GUTS.md Mission
            PortalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: AppTheme.primaryColor),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Our Mission',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    'avrai exists to help people find places, experiences, and communities where they truly feel at home—wherever they are. We believe everyone deserves to know they belong.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Core Values
            Text(
              'Our Values',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            _buildValueCard(
              context,
              'Belonging Comes First',
              'We help you find places where you truly feel at home.',
              Icons.home,
              AppColors.warning,
            ),
            _buildValueCard(
              context,
              'Privacy & Control',
              'Your data is yours. You control your experience.',
              Icons.privacy_tip,
              AppTheme.successColor,
            ),
            _buildValueCard(
              context,
              'Authenticity Over Algorithms',
              'Real preferences, not advertising dollars.',
              Icons.psychology,
              AppColors.grey600,
            ),
            _buildValueCard(
              context,
              'Effortless Discovery',
              'No check-ins, no hassle. Just enjoy the moment.',
              Icons.auto_awesome,
              AppColors.grey600,
            ),

            SizedBox(height: spacing.lg),

            // App Information
            Text(
              'App Information',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
              child: Column(
                children: [
                  _buildInfoRow(context, 'Version', '1.0.0'),
                  _buildInfoRow(context, 'Build', '100'),
                  _buildInfoRow(context, 'Release Date', 'August 2025'),
                  _buildInfoRow(context, 'Platform', 'Flutter'),
                  _buildInfoRow(context, 'Architecture', 'AI2AI Learning'),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Features
            Text(
              'Key Features',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildFeatureTile(
                    'Spot Discovery',
                    'Find and create your favorite places',
                    Icons.place,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Smart Lists',
                    'Organize spots into curated collections',
                    Icons.list,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'AI2AI Learning',
                    'Anonymous personality learning for better recommendations',
                    Icons.psychology,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Community Sharing',
                    'Share discoveries while maintaining privacy',
                    Icons.share,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Maps Integration',
                    'Seamless navigation to your spots',
                    Icons.directions,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Links & Contact
            Text(
              'Connect With Us',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildLinkTile(
                    'Website',
                    'avrai.app',
                    Icons.web,
                    () => _launchUrl('https://avrai.app'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'OUR_GUTS.md',
                    'Read our full philosophy',
                    Icons.favorite,
                    () => _launchUrl('https://avrai.app/our-guts'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Privacy Policy',
                    'How we protect your data',
                    Icons.policy,
                    () => _launchUrl('https://avrai.app/privacy'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Terms of Service',
                    'Usage terms and conditions',
                    Icons.gavel,
                    () => _launchUrl('https://avrai.app/terms'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Support',
                    'Get help and contact us',
                    Icons.support_agent,
                    () => _launchEmail('support@avrai.app'),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Legal
            Text(
              'Legal',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.md),

            PortalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '© 2025 avrai Technologies, Inc.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'All rights reserved. avrai and "know you belong" are trademarks of avrai Technologies, Inc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'Third-Party Licenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: spacing.xs),
                  TextButton(
                    onPressed: () => _showLicenses(context),
                    child: const Text('View Open Source Licenses'),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // Credits
            PortalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: AppTheme.primaryColor),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Made with ❤️',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    'avrai is built with care by a team that believes technology should help people feel more connected to the places and communities around them.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Thank you for being part of our community! 🌟',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(BuildContext context, String title, String description,
      IconData icon, Color color) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      margin: EdgeInsets.only(bottom: spacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.grey100,
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: spacing.xxs),
                Text(
                  description,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style:
                textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  Widget _buildLinkTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'avrai',
      applicationVersion: '1.0.0',
      applicationIcon: const CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.place,
          color: AppColors.white,
          size: 32,
        ),
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
