import 'package:flutter/material.dart';

import 'package:avrai/presentation/schemas/models/page_schema.dart';

PageSchema buildPublicHandlesPageSchema({
  required Widget content,
}) {
  return PageSchema(
    title: 'Public Profile Analysis',
    header: const PageHeaderSchema(
      title: 'Public Profile Analysis',
      subtitle:
          'Optionally provide public handles for profile enrichment with explicit consent.',
      leadingIcon: Icons.manage_accounts_outlined,
    ),
    sections: [
      const BannerSectionSchema(
        title: 'Consent-first flow',
        body:
            'You control which public signals are used and can revoke and delete stored data at any time.',
        icon: Icons.privacy_tip_outlined,
      ),
      CustomSectionSchema(
        title: 'Profiles and actions',
        child: content,
      ),
    ],
  );
}
