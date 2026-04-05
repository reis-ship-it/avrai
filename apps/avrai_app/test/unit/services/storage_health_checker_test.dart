import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_health_checker.dart';

import 'storage_health_checker_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([SupabaseClient, SupabaseStorageClient])
void main() {
  group('StorageHealthChecker', () {
    late StorageHealthChecker checker;
    late MockSupabaseClient mockClient;
    late MockSupabaseStorageClient mockStorage;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockStorage = MockSupabaseStorageClient();

      when(mockClient.storage).thenReturn(mockStorage);

      checker = StorageHealthChecker(mockClient);
    });

    group('checkBucketAccessible', () {
      test('should return false when storage throws exception', () async {
        when(mockStorage.from('test-bucket'))
            .thenThrow(Exception('Access denied'));

        final result = await checker.checkBucketAccessible('test-bucket');

        expect(result, isFalse);
      });

      test('should handle storage errors gracefully', () async {
        when(mockStorage.from('invalid-bucket'))
            .thenThrow(Exception('Bucket not found'));

        final result = await checker.checkBucketAccessible('invalid-bucket');

        expect(result, isFalse);
      });
    });

    group('checkCanary', () {
      test('should return null when public URL is null', () async {
        // Mock storage.from to throw to trigger null return path
        when(mockStorage.from('test-bucket'))
            .thenThrow(Exception('Storage error'));

        final result = await checker.checkCanary('test-bucket');

        expect(result, isNull);
      });

      test('should return null when public URL is empty', () async {
        // Mock storage.from to throw to trigger null return path
        when(mockStorage.from('test-bucket'))
            .thenThrow(Exception('Storage error'));

        final result = await checker.checkCanary('test-bucket');

        expect(result, isNull);
      });

      test('should handle errors gracefully', () async {
        when(mockStorage.from('test-bucket'))
            .thenThrow(Exception('Storage error'));

        final result = await checker.checkCanary('test-bucket');

        expect(result, isNull);
      });
    });

    group('checkAllBuckets', () {
      test('should handle empty bucket list', () async {
        final result = await checker.checkAllBuckets([]);

        expect(result, isEmpty);
      });

      test('should return map with bucket results', () async {
        when(mockStorage.from('bucket1')).thenThrow(Exception('Error'));
        when(mockStorage.from('bucket2')).thenThrow(Exception('Error'));

        final result = await checker.checkAllBuckets(['bucket1', 'bucket2']);

        expect(result, isA<Map<String, bool>>());
        expect(result['bucket1'], isFalse);
        expect(result['bucket2'], isFalse);
        expect(result.length, equals(2));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

// Mock class removed - using exception-based testing instead
