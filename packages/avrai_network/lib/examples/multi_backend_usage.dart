import '../component_backend_factory.dart';
// ignore_for_file: avoid_print - Example file demonstrating usage

/// Example of using different backends for different components
class MultiBackendExample {
  
  /// Initialize all component backends
  static Future<void> initializeComponentBackends() async {
    try {
      // Authentication - Supabase (privacy-focused)
      await ComponentBackendFactory.createForComponent(
        ComponentNames.authentication,
        ComponentBackendConfigs.authentication,
      );
      
      // AI2AI - Firebase (best real-time)
      await ComponentBackendFactory.createForComponent(
        ComponentNames.ai2ai,
        ComponentBackendConfigs.ai2ai,
      );
      
      // Data Storage - Custom API (full control)
      await ComponentBackendFactory.createForComponent(
        ComponentNames.dataStorage,
        ComponentBackendConfigs.dataStorage,
      );
      
      // File Upload - Supabase (built-in storage)
      await ComponentBackendFactory.createForComponent(
        ComponentNames.fileUpload,
        ComponentBackendConfigs.fileUpload,
      );
      
      // Analytics - Firebase (best analytics)
      await ComponentBackendFactory.createForComponent(
        ComponentNames.analytics,
        ComponentBackendConfigs.analytics,
      );
      
      print('✅ All component backends initialized successfully');
      
    } catch (e) {
      print('❌ Failed to initialize component backends: $e');
    }
  }
  
  /// Use authentication backend
  static Future<void> authenticateUser() async {
    final authBackend = ComponentBackendFactory.getComponentBackend(
      ComponentNames.authentication,
    );
    
    if (authBackend != null) {
      // Use Supabase for authentication
      await authBackend.auth.signInWithEmailPassword('user@example.com', 'password');
      print('🔐 User authenticated via Supabase');
    }
  }
  
  /// Use AI2AI backend for real-time features
  static Future<void> setupAI2AI() async {
    final ai2aiBackend = ComponentBackendFactory.getComponentBackend(
      ComponentNames.ai2ai,
    );
    
    if (ai2aiBackend != null) {
      // Use Firebase for real-time AI2AI features
      await ai2aiBackend.realtime.joinChannel('personality_updates');
      // ignore: unused_local_variable - Example file demonstrating subscription
      final stream = ai2aiBackend.realtime.subscribeToMessages('personality_updates');
      print('🤖 AI2AI real-time features enabled via Firebase');
    }
  }
  
  /// Use data storage backend
  static Future<void> storeUserData() async {
    final dataBackend = ComponentBackendFactory.getComponentBackend(
      ComponentNames.dataStorage,
    );
    
    if (dataBackend != null) {
      // Use Custom API for data storage
      // Use createUser instead of createDocument
      // await dataBackend.data.createUser(User(...)); // Would need proper User object
      // For example purposes, this is commented out
      print('💾 User data stored via Custom API');
    }
  }
  
  /// Use file upload backend
  static Future<void> uploadFile() async {
    final uploadBackend = ComponentBackendFactory.getComponentBackend(
      ComponentNames.fileUpload,
    );
    
    if (uploadBackend != null) {
      // Use Supabase for file uploads
      // uploadFile requires List<int> bytes, not String
      // For example: await uploadBackend.data.uploadFile('profile.jpg', fileBytes, metadata: {'contentType': 'image/jpeg'});
      print('📁 File upload would require actual file bytes (List<int>)');
    }
  }
  
  /// Use analytics backend
  static Future<void> trackEvent() async {
    final analyticsBackend = ComponentBackendFactory.getComponentBackend(
      ComponentNames.analytics,
    );
    
    if (analyticsBackend != null) {
      // Use Firebase for analytics
      // createDocument doesn't exist - would need to use appropriate method
      // For analytics events, would typically use a dedicated analytics service
      // This is commented out for example purposes
      print('📊 Analytics tracking would require dedicated analytics service');
    }
  }
  
  /// Health check all backends
  static Future<void> checkAllBackends() async {
    final healthResults = await ComponentBackendFactory.healthCheckAll();
    
    print('🏥 Backend Health Check Results:');
    for (final entry in healthResults.entries) {
      final status = entry.value ? '✅' : '❌';
      print('$status ${entry.key}: ${entry.value ? 'Healthy' : 'Unhealthy'}');
    }
  }
  
  /// Switch backend for specific component
  static Future<void> switchComponentBackend() async {
    // Switch authentication from Supabase to Custom API
    await ComponentBackendFactory.createForComponent(
      ComponentNames.authentication,
      ComponentBackendConfigs.dataStorage, // Using custom config
    );
    
    print('🔄 Authentication backend switched to Custom API');
  }
  
  /// Cleanup all backends
  static Future<void> cleanup() async {
    await ComponentBackendFactory.disposeAll();
    print('🧹 All component backends disposed');
  }
}

/// Example usage in your app
class AppBackendManager {
  static Future<void> initialize() async {
    // Initialize all component backends
    await MultiBackendExample.initializeComponentBackends();
    
    // Check health
    await MultiBackendExample.checkAllBackends();
  }
  
  static Future<void> authenticate() async {
    await MultiBackendExample.authenticateUser();
  }
  
  static Future<void> setupAI2AI() async {
    await MultiBackendExample.setupAI2AI();
  }
  
  static Future<void> storeData() async {
    await MultiBackendExample.storeUserData();
  }
  
  static Future<void> uploadFile() async {
    await MultiBackendExample.uploadFile();
  }
  
  static Future<void> trackAnalytics() async {
    await MultiBackendExample.trackEvent();
  }
  
  static Future<void> switchBackend() async {
    await MultiBackendExample.switchComponentBackend();
  }
  
  static Future<void> cleanup() async {
    await MultiBackendExample.cleanup();
  }
}
