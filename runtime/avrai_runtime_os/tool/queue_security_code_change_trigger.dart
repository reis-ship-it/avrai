import 'dart:io';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';

Future<void> main(List<String> args) async {
  final parser = _CodeChangeTriggerArgs.parse(args);
  if (!parser.isValid) {
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final prefs = await SharedPreferencesCompat.getInstance();
  final ingress = SecurityTriggerIngressService(
    campaignRegistry: const SecurityCampaignRegistry(),
    prefs: prefs,
  );
  await ingress.notifyCodeChange(
    changedPaths: parser.changedPaths,
    commitRef: parser.commitRef,
    actorAlias: parser.actorAlias,
  );
  final pending = ingress.pendingTriggers(limit: 128);
  stdout.writeln(
    'Queued ${pending.length} security trigger(s) for commit ${parser.commitRef}.',
  );
  for (final trigger in pending) {
    stdout.writeln(
      '- ${trigger.campaignId} (${trigger.trigger.name}) by ${trigger.actorAlias}',
    );
  }
}

class _CodeChangeTriggerArgs {
  const _CodeChangeTriggerArgs({
    required this.commitRef,
    required this.actorAlias,
    required this.changedPaths,
  });

  final String commitRef;
  final String actorAlias;
  final List<String> changedPaths;

  bool get isValid => commitRef.isNotEmpty && changedPaths.isNotEmpty;

  String get usage => '''
Usage:
  dart run tool/queue_security_code_change_trigger.dart \\
    --commit-ref <sha-or-label> \\
    [--actor <alias>] \\
    --changed-path <path> [--changed-path <path> ...]

Example:
  dart run tool/queue_security_code_change_trigger.dart \\
    --commit-ref abc123 \\
    --actor ci_release \\
    --changed-path runtime/avrai_runtime_os/services/security/security_trigger_ingress_service.dart
''';

  static _CodeChangeTriggerArgs parse(List<String> args) {
    var commitRef = '';
    var actorAlias = 'ci_release';
    final changedPaths = <String>[];

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      switch (arg) {
        case '--commit-ref':
          if (index + 1 < args.length) {
            commitRef = args[++index].trim();
          }
          break;
        case '--actor':
          if (index + 1 < args.length) {
            actorAlias = args[++index].trim();
          }
          break;
        case '--changed-path':
          if (index + 1 < args.length) {
            final path = args[++index].trim();
            if (path.isNotEmpty) {
              changedPaths.add(path);
            }
          }
          break;
        default:
          if (arg.trim().isNotEmpty) {
            changedPaths.add(arg.trim());
          }
          break;
      }
    }

    return _CodeChangeTriggerArgs(
      commitRef: commitRef,
      actorAlias: actorAlias,
      changedPaths: changedPaths,
    );
  }
}
