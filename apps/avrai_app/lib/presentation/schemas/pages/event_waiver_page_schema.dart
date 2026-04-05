import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';
import 'package:avrai/presentation/schemas/pages/terms_of_service_page_schema.dart';

PageSchema buildEventWaiverPageSchema({
  required String eventTitle,
  required String eventDetails,
  required List<String> paragraphs,
  required bool requiresFull,
  required bool acknowledgeRisks,
  required bool acknowledgeRelease,
  required bool acknowledgeAge,
  required bool hasAccepted,
  required bool requireAcceptance,
  required bool isSubmitting,
  String? error,
  ValueChanged<bool>? onAcknowledgeRisksChanged,
  ValueChanged<bool>? onAcknowledgeReleaseChanged,
  ValueChanged<bool>? onAcknowledgeAgeChanged,
  VoidCallback? onAccept,
}) {
  final sections = <SectionSchema>[
    BannerSectionSchema(
      title: eventTitle,
      body: eventDetails,
      icon: Icons.event_note_outlined,
      tone: hasAccepted ? SchemaTone.success : SchemaTone.warning,
    ),
    TextSectionSchema(
      title: 'Waiver',
      paragraphs: paragraphs,
    ),
  ];

  if (requiresFull && !hasAccepted) {
    sections.add(
      SettingsGroupSectionSchema(
        title: 'Acknowledgment',
        items: [
          CheckboxSettingItemSchema(
            title: 'I understand and acknowledge the risks of participation.',
            value: acknowledgeRisks,
            onChanged: onAcknowledgeRisksChanged,
          ),
          CheckboxSettingItemSchema(
            title: 'I release AVRAI and participating parties from liability.',
            value: acknowledgeRelease,
            onChanged: onAcknowledgeReleaseChanged,
          ),
          CheckboxSettingItemSchema(
            title:
                'I am of legal age to enter into this agreement or have guardian consent.',
            value: acknowledgeAge,
            onChanged: onAcknowledgeAgeChanged,
          ),
        ],
      ),
    );
  }

  if (error != null && error.isNotEmpty) {
    sections.add(
      BannerSectionSchema(
        title: 'Unable to accept waiver',
        body: error,
        tone: SchemaTone.error,
        icon: Icons.error_outline,
      ),
    );
  }

  if (requireAcceptance && !hasAccepted) {
    sections.add(
      CtaSectionSchema(
        title: 'Acceptance',
        body: 'Review the waiver and confirm the acknowledgments to continue.',
        primaryLabel: isSubmitting ? 'Submitting...' : 'I Agree',
        onPrimaryTap: isSubmitting ? null : onAccept,
      ),
    );
  }

  return PageSchema(
    title: 'Event Waiver',
    header: const PageHeaderSchema(
      title: 'Event Waiver',
      subtitle: 'Review the waiver before joining this event.',
      leadingIcon: Icons.warning_amber_outlined,
    ),
    sections: sections,
  );
}

List<String> splitWaiverContent(String content) => splitLegalContent(content);
