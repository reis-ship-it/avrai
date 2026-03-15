import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildKnotBirthPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Knot Birth',
    header: const PageHeaderSchema(
      title: 'Knot Birth',
      subtitle: 'Generate your personality knot before discovery.',
      leadingIcon: Icons.auto_awesome,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Knot birth',
        child: content,
      ),
    ],
  );
}
