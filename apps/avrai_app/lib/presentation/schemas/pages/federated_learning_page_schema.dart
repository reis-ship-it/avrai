import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildFederatedLearningPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Federated Learning',
    header: const PageHeaderSchema(
      title: 'Federated Learning',
      subtitle: 'Contribute to shared models while keeping raw data on-device.',
      leadingIcon: Icons.school_outlined,
    ),
    sections: [
      CustomSectionSchema(
        title: 'Learning overview',
        child: content,
      ),
    ],
  );
}
