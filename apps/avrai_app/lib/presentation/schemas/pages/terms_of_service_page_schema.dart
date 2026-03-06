import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildTermsOfServicePageSchema({
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
          ? 'You have already accepted the current Terms of Service.'
          : 'Read the current terms that govern access to AVRAI.',
      icon: hasAccepted ? Icons.check_circle_outline : Icons.description_outlined,
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
      title: 'Terms',
      paragraphs: paragraphs,
    ),
  ];

  if (error != null && error.isNotEmpty) {
    sections.add(
      BannerSectionSchema(
        title: 'Unable to accept terms',
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
        body: 'Accept the Terms of Service to continue.',
        primaryLabel: isSubmitting
            ? 'Submitting...'
            : 'I Accept the Terms of Service',
        onPrimaryTap: isSubmitting ? null : onAccept,
      ),
    );
  }

  return PageSchema(
    title: 'Terms of Service',
    header: const PageHeaderSchema(
      title: 'Terms of Service',
      subtitle: 'The current terms for using AVRAI.',
      leadingIcon: Icons.description_outlined,
    ),
    sections: sections,
  );
}

List<String> splitLegalContent(String content) {
  return content
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.replaceAll('\n', ' ').trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
}
