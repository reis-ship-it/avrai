import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI2AI learning artifact guardrails', () {
    test('conversation extractor stays on learnable artifacts', () {
      final source = File(
        'lib/ai/ai2ai_learning/extractors/conversation_insights_extractor.dart',
      ).readAsStringSync();

      expect(source, contains('learnablePatternText'));
      expect(source, contains('learnableSummaryText'));
      expect(source, contains('learnableTopicTerms'));
      expect(source, isNot(contains('message.content.toLowerCase()')));
      expect(source, isNot(contains('message.content.substring')));
    });

    test('consensus builder stays on learnable artifacts', () {
      final source = File(
        'lib/ai/ai2ai_learning/builders/consensus_knowledge_builder.dart',
      ).readAsStringSync();

      expect(source, contains('learnablePatternText'));
      expect(source, isNot(contains('message.content.toLowerCase()')));
    });

    test('chat analysis heuristics do not parse raw transcripts directly', () {
      final source = File('lib/ai/ai2ai_learning.dart').readAsStringSync();

      expect(source, contains('learnablePatternText'));
      expect(source, isNot(contains('message.content.toLowerCase()')));
    });
  });
}
