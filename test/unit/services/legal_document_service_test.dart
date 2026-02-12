/// LegalDocumentService Unit Tests
///
/// Focus: behavior + durability of legal acceptances:
/// - Accepting Terms persists locally (survives new service instance)
/// - Accepting again revokes the previous active record (history retained)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/legal/terms_of_service.dart';
import 'package:avrai/core/models/user/user_agreement.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

import '../../mocks/mock_storage_service.dart';

void main() {
  group('LegalDocumentService', () {
    setUp(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage: MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
    });

    tearDown(() {
      MockGetStorage.reset();
    });

    test('should persist Terms acceptance locally (survives app restart)', () async {
      const userId = 'user_1';

      final serviceA = LegalDocumentService(storage: StorageService.instance);
      expect(await serviceA.hasAcceptedTerms(userId), isFalse);

      await serviceA.acceptTermsOfService(userId: userId);

      // New instance simulates app restart.
      final serviceB = LegalDocumentService(storage: StorageService.instance);
      expect(await serviceB.hasAcceptedTerms(userId), isTrue);

      final agreements = await serviceB.getUserAgreements(userId);
      final terms =
          agreements.where((a) => a.documentType == 'terms_of_service').toList();

      expect(terms, isNotEmpty);
      expect(
        terms.any((a) => a.isActive && a.version == TermsOfService.version),
        isTrue,
      );

      // High-signal: we store a content hash for legal defensibility.
      final active = terms.firstWhere((a) => a.isActive);
      expect(active.metadata['content_sha256'], isA<String>());
    });

    test('should revoke previous active Terms record when accepting again', () async {
      const userId = 'user_1';

      // Seed a prior “active” terms agreement.
      final oldAgreement = UserAgreement(
        id: 'agreement_old',
        userId: userId,
        documentType: 'terms_of_service',
        version: '0.9.0',
        agreedAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      await StorageService.instance.userStorage.write(
        'legal_agreements_v1_$userId',
        [oldAgreement.toJson()],
      );

      final service = LegalDocumentService(storage: StorageService.instance);
      await service.acceptTermsOfService(userId: userId);

      final agreements = await service.getUserAgreements(userId);
      final terms =
          agreements.where((a) => a.documentType == 'terms_of_service').toList();

      // Behavior: history retained, but only one active.
      expect(terms.length, greaterThanOrEqualTo(2));
      expect(terms.where((a) => a.isActive).length, equals(1));

      final inactiveOld = terms.firstWhere((a) => a.id == 'agreement_old');
      expect(inactiveOld.isActive, isFalse);
      expect(inactiveOld.revokedAt, isNotNull);
    });
  });
}

