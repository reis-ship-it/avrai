import 'package:avrai_core/models/imports/external_sync_metadata.dart';

class OrganizerSyncAdvice {
  final ExternalConnectionMode mode;
  final String label;
  final String helperText;

  const OrganizerSyncAdvice({
    required this.mode,
    required this.label,
    required this.helperText,
  });
}

/// Suggests the lowest-friction one-way sync mode from a source URL or label.
class OrganizerSyncConnectionAdvisor {
  const OrganizerSyncConnectionAdvisor();

  OrganizerSyncAdvice advise({
    String? sourceUrl,
    String? providerLabel,
  }) {
    final haystack = '${sourceUrl ?? ''} ${providerLabel ?? ''}'.toLowerCase();

    if (haystack.contains('facebook')) {
      return const OrganizerSyncAdvice(
        mode: ExternalConnectionMode.oauth,
        label: 'Facebook connection',
        helperText:
            'Best when the organizer already manages a Facebook page or group and wants AVRAI to keep pulling updates in one direction.',
      );
    }

    if (haystack.contains('ical') ||
        haystack.contains('ics') ||
        haystack.contains('calendar') ||
        haystack.contains('eventbrite')) {
      return const OrganizerSyncAdvice(
        mode: ExternalConnectionMode.feed,
        label: 'Calendar/feed URL',
        helperText:
            'Best when the source already publishes a feed or structured event link.',
      );
    }

    if (haystack.contains('mailchimp') ||
        haystack.contains('substack') ||
        haystack.contains('newsletter') ||
        haystack.contains('email')) {
      return const OrganizerSyncAdvice(
        mode: ExternalConnectionMode.emailList,
        label: 'Newsletter or email list',
        helperText:
            'Best when updates already live in an email workflow and AVRAI should read them without replacing that workflow.',
      );
    }

    if (haystack.contains('api')) {
      return const OrganizerSyncAdvice(
        mode: ExternalConnectionMode.api,
        label: 'API connection',
        helperText:
            'Best when the organizer already has a structured source that can be synced directly.',
      );
    }

    return const OrganizerSyncAdvice(
      mode: ExternalConnectionMode.url,
      label: 'Website or public URL',
      helperText:
          'Best when the source is a public page and AVRAI should keep reading changes without writing back.',
    );
  }
}
