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
  final pending = await queueSecurityCodeChangeTriggers(
    changedPaths: parser.changedPaths,
    commitRef: parser.commitRef,
    actorAlias: parser.actorAlias,
    prefs: prefs,
  );
  stdout.writeln(
    'Queued ${pending.length} security trigger(s) for commit ${parser.commitRef}.',
  );
  for (final trigger in pending) {
    stdout.writeln(
      '- ${trigger.campaignId} (${trigger.trigger.name}) by ${trigger.actorAlias}',
    );
  }
}

Future<List<SecurityQueuedCampaignTrigger>> queueSecurityCodeChangeTriggers({
  required List<String> changedPaths,
  required String commitRef,
  String actorAlias = 'ci_release',
  SharedPreferencesCompat? prefs,
  SecurityCampaignRegistry campaignRegistry = const SecurityCampaignRegistry(),
}) async {
  final ingress = SecurityTriggerIngressService(
    campaignRegistry: campaignRegistry,
    prefs: prefs,
  );
  await ingress.notifyCodeChange(
    changedPaths: changedPaths,
    commitRef: commitRef,
    actorAlias: actorAlias,
  );
  return ingress.pendingTriggers(limit: 128);
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
  bash work/scripts/ci/queue_security_code_change_from_git.sh [<git-diff-range>]

Example:
  SECURITY_TRIGGER_COMMIT_REF=abc123 \\
  SECURITY_TRIGGER_ACTOR_ALIAS=ci_release \\
  bash work/scripts/ci/queue_security_code_change_from_git.sh
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
