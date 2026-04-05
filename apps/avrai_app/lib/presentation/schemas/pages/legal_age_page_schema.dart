import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildLegalAgePageSchema({
  required Widget birthdayField,
  required Widget agreements,
  required Widget? ageValidationMessage,
}) {
  final sections = <SectionSchema>[
    const BannerSectionSchema(
      title: 'Age and legal requirements',
      body:
          'You must be 18 or older to use AVRAI. Confirm your details to continue.',
      icon: Icons.verified_user_outlined,
      tone: SchemaTone.neutral,
    ),
    const TextSectionSchema(
      title: 'Purpose',
      paragraphs: [
        'AVRAI validates the legal minimum age and keeps required agreements on file.',
        'You can review policy documents and legal notes from this screen.',
      ],
    ),
    CustomSectionSchema(
      title: 'Birthday',
      subtitle: 'Select the date used for age validation.',
      child: birthdayField,
    ),
    CustomSectionSchema(
      title: 'Legal agreements',
      subtitle: 'Choose and confirm the required agreements.',
      child: agreements,
    ),
  ];

  if (ageValidationMessage != null) {
    sections.insert(
      3,
      CustomSectionSchema(
        title: 'Age verification',
        child: ageValidationMessage,
      ),
    );
  }

  return PageSchema(
    title: 'Age and Legal',
    header: const PageHeaderSchema(
      title: 'Age and Legal',
      subtitle: 'Confirm age verification and core agreements to continue.',
      leadingIcon: Icons.verified_user_outlined,
    ),
    sections: sections,
  );
}
