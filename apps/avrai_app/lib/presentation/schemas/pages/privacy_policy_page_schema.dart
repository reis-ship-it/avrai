import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildPrivacyPolicyPageSchema({
  required String version,
  required String effectiveDate,
  required List<String> paragraphs,
  required bool hasAccepted,
  required bool requireAcceptance,
  required bool isSubmitting,
  String? error,
  VoidCallback? onAccept,
}) {
  final sections = <SectionSchema>[
    BannerSectionSchema(
      title: hasAccepted ? 'Accepted' : 'Review before continuing',
      body: hasAccepted
          ? 'You have already accepted the current Privacy Policy.'
          : 'Review how AVRAI collects, uses, and protects data.',
      icon:
          hasAccepted ? Icons.check_circle_outline : Icons.privacy_tip_outlined,
      tone: hasAccepted ? SchemaTone.success : SchemaTone.neutral,
    ),
    KeyValueSectionSchema(
      title: 'Document Details',
      items: [
        KeyValueItemSchema(label: 'Version', value: version),
        KeyValueItemSchema(label: 'Effective Date', value: effectiveDate),
      ],
    ),
    TextSectionSchema(
      title: 'Privacy Policy',
      paragraphs: paragraphs,
    ),
  ];

  if (error != null && error.isNotEmpty) {
    sections.add(
      BannerSectionSchema(
        title: 'Unable to accept policy',
        body: error,
        tone: SchemaTone.error,
        icon: Icons.error_outline,
      ),
    );
  }

  if (requireAcceptance || !hasAccepted) {
    sections.add(
      CtaSectionSchema(
        title: 'Acceptance',
        body: 'Accept the Privacy Policy to continue.',
        primaryLabel:
            isSubmitting ? 'Submitting...' : 'I Accept the Privacy Policy',
        onPrimaryTap: isSubmitting ? null : onAccept,
      ),
    );
  }

  return PageSchema(
    title: 'Privacy Policy',
    header: const PageHeaderSchema(
      title: 'Privacy Policy',
      subtitle: 'How AVRAI handles user data and product activity.',
      leadingIcon: Icons.privacy_tip_outlined,
    ),
    sections: sections,
  );
}
