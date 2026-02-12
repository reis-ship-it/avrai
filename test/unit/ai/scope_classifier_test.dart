/// Unit tests for ScopeClassifier (RAG-as-answer Phase 3).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/scope_classifier.dart';

void main() {
  group('ScopeClassifier', () {
    late ScopeClassifier classifier;

    setUp(() {
      classifier = ScopeClassifier();
    });

    test('classify returns inScope for empty message', () {
      expect(classifier.classify(''), Scope.inScope);
    });

    test('classify returns outOfScope for capital of X', () {
      expect(
        classifier.classify('What is the capital of France?'),
        Scope.outOfScope,
      );
    });

    test('classify returns inScope for capital of my heart', () {
      expect(
        classifier.classify('Capital of my heart'),
        Scope.inScope,
      );
      expect(
        classifier.classify("You're the capital of my heart"),
        Scope.inScope,
      );
    });

    test('classify returns outOfScope for simple math', () {
      expect(classifier.classify('Solve 2+2'), Scope.outOfScope);
      expect(classifier.classify('Calculate 10 * 5'), Scope.outOfScope);
    });

    test('classify returns inScope for preference-like query', () {
      expect(
        classifier.classify('What places do I like?'),
        Scope.inScope,
      );
      expect(
        classifier.classify('Tell me about my traits'),
        Scope.inScope,
      );
    });
  });
}
