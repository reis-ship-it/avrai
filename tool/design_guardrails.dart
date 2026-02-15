import 'dart:io';

class _Violation {
  final String path;
  final int line;
  final String message;

  const _Violation(this.path, this.line, this.message);
}

void main() {
  final root = Directory('lib/presentation');
  if (!root.existsSync()) {
    stderr.writeln('Expected lib/presentation directory.');
    exitCode = 2;
    return;
  }

  final violations = <_Violation>[];
  var rawEdgeInsetsCount = 0;
  var scaffoldMessengerCount = 0;
  final rawEdgeInsetsPattern = RegExp(
    r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*\d',
  );

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    final lines = entity.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i];

      // Enforce tokenized typography in presentation layer.
      if (RegExp(r'\bTextStyle\(').hasMatch(line) &&
          !line.contains('// guardrail:allow')) {
        violations.add(
          _Violation(path, lineNo, 'Avoid raw TextStyle(...). Use textTheme.'),
        );
      }
      if (RegExp(r'\bfontSize\s*:').hasMatch(line) &&
          !line.contains('// guardrail:allow')) {
        violations.add(
          _Violation(
              path, lineNo, 'Avoid raw fontSize:. Use textTheme scales.'),
        );
      }

      // Enforce centralized navigation transition API.
      if (line.contains('MaterialPageRoute(') &&
          !line.contains('// guardrail:allow')) {
        violations.add(
          _Violation(
            path,
            lineNo,
            'Avoid MaterialPageRoute(...). Use AppNavigator/AppPageTransitions.',
          ),
        );
      }
      if (line.contains('PageRouteBuilder(') &&
          !line.contains('// guardrail:allow') &&
          !path.contains('glass_content_transition.dart')) {
        violations.add(
          _Violation(
            path,
            lineNo,
            'Avoid ad-hoc PageRouteBuilder(...). Use AppPageTransitions.',
          ),
        );
      }

      // Advisory-only migration metrics.
      if (rawEdgeInsetsPattern.hasMatch(line) &&
          !line.contains('// guardrail:allow')) {
        rawEdgeInsetsCount++;
      }
      if (line.contains('ScaffoldMessenger.of(') &&
          !line.contains('// guardrail:allow')) {
        scaffoldMessengerCount++;
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Design guardrails: OK');
    stdout.writeln(
      'Advisory: raw EdgeInsets usages=$rawEdgeInsetsCount, direct ScaffoldMessenger usages=$scaffoldMessengerCount',
    );
    return;
  }

  stdout.writeln('Design guardrails: ${violations.length} violation(s)');
  for (final v in violations) {
    stdout.writeln('${v.path}:${v.line} ${v.message}');
  }
  exitCode = 1;
}
