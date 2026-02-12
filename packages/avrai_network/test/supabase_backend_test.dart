import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/backend_factory.dart';
import 'package:avrai_network/models/connection_config.dart';
import 'package:avrai_network/interfaces/backend_interface.dart';

void main() {
  group('Supabase Backend Tests', () {
    test('should create Supabase backend successfully', () async {
      // Arrange
      final config = BackendConfig.supabase(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        name: 'Test Supabase',
      );
      
      // Act
      final backend = await BackendFactory.create(config);
      
      // Assert
      expect(backend, isNotNull);
      expect(backend.backendType, equals('supabase'));
      expect(backend.isInitialized, isTrue);
      
      // Cleanup
      await backend.dispose();
    });
    
    test('should handle Supabase initialization errors gracefully', () async {
      // Arrange
      final config = BackendConfig.supabase(
        url: 'invalid-url',
        anonKey: 'invalid-key',
        name: 'Invalid Supabase',
      );
      
      // Act & Assert
      expect(
        () => BackendFactory.create(config),
        throwsA(isA<BackendInitializationException>()),
      );
    });
    
    test('should switch between backends successfully', () async {
      // Arrange
      final supabaseConfig = BackendConfig.supabase(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        name: 'Test Supabase',
      );
      
      // Act
      final backend1 = await BackendFactory.create(supabaseConfig);
      expect(backend1.backendType, equals('supabase'));
      
      // Switch to different backend (this will fail but should handle gracefully)
      final customConfig = BackendConfig.custom(
        baseUrl: 'https://test-api.com',
        apiKey: 'test-key',
        name: 'Test Custom',
      );
      
      // This should throw since custom backend is not implemented yet
      expect(
        () => BackendFactory.switchBackend(customConfig),
        throwsA(isA<BackendInitializationException>()),
      );
      
      // Cleanup
      await BackendFactory.dispose();
    });
    
    test('should perform health check correctly', () async {
      // Arrange
      final config = BackendConfig.supabase(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        name: 'Test Supabase',
      );
      
      final backend = await BackendFactory.create(config);
      
      // Act
      final isHealthy = await backend.healthCheck();
      
      // Assert
      // Health check should return false for test configuration
      expect(isHealthy, isFalse);
      
      // Cleanup
      await backend.dispose();
    });
    
    test('should get backend capabilities correctly', () {
      // Arrange
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      final config = BackendConfig.supabase(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        name: 'Test Supabase',
      );
      
      // Act
      const capabilities = BackendCapabilities.supabase;
      
      // Assert
      expect(capabilities.supportsRealtimeUpdates, isTrue);
      expect(capabilities.supportsAuth, isTrue);
      expect(capabilities.supportsFileUpload, isTrue);
      expect(capabilities.supportsFullTextSearch, isTrue);
      expect(capabilities.supportsEdgeFunctions, isTrue);
    });
  });
}
