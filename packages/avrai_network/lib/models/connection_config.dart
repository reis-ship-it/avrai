import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connection_config.g.dart';

/// Backend configuration for different backend types
@JsonSerializable()
class BackendConfig extends Equatable {
  final BackendType type;
  final String name;
  final Map<String, dynamic> config;
  final bool isDefault;
  final DateTime createdAt;
  
  const BackendConfig({
    required this.type,
    required this.name,
    required this.config,
    this.isDefault = false,
    required this.createdAt,
  });
  
  /// Create Firebase configuration
  factory BackendConfig.firebase({
    required String projectId,
    required String apiKey,
    required String appId,
    String? messagingSenderId,
    String? storageBucket,
    String? authDomain,
    String name = 'Firebase',
    bool isDefault = false,
  }) {
    return BackendConfig(
      type: BackendType.firebase,
      name: name,
      config: {
        'projectId': projectId,
        'apiKey': apiKey,
        'appId': appId,
        'messagingSenderId': messagingSenderId,
        'storageBucket': storageBucket,
        'authDomain': authDomain,
      },
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }
  
  /// Create Supabase configuration
  factory BackendConfig.supabase({
    required String url,
    required String anonKey,
    String? serviceRoleKey,
    String name = 'Supabase',
    bool isDefault = false,
  }) {
    return BackendConfig(
      type: BackendType.supabase,
      name: name,
      config: {
        'url': url,
        'anonKey': anonKey,
        'serviceRoleKey': serviceRoleKey,
      },
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }
  
  /// Create custom backend configuration
  factory BackendConfig.custom({
    required String baseUrl,
    required String apiKey,
    Map<String, String>? headers,
    Duration? timeout,
    String name = 'Custom API',
    bool isDefault = false,
  }) {
    return BackendConfig(
      type: BackendType.custom,
      name: name,
      config: {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'headers': headers ?? {},
        'timeout': timeout?.inSeconds ?? 30,
      },
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }
  
  /// Get Firebase project ID
  String? get firebaseProjectId => config['projectId'] as String?;
  
  /// Get Supabase URL
  String? get supabaseUrl => config['url'] as String?;
  
  /// Get custom API base URL
  String? get customBaseUrl => config['baseUrl'] as String?;
  
  /// Get API key for any backend type
  String? get apiKey => config['apiKey'] as String? ?? config['anonKey'] as String?;
  
  /// Check if configuration is valid
  bool get isValid {
    switch (type) {
      case BackendType.firebase:
        return config['projectId'] != null && config['apiKey'] != null;
      case BackendType.supabase:
        return config['url'] != null && config['anonKey'] != null;
      case BackendType.custom:
        return config['baseUrl'] != null;
    }
  }
  
  /// Get timeout duration
  Duration get timeout {
    final seconds = config['timeout'] as int? ?? 30;
    return Duration(seconds: seconds);
  }
  
  /// Get headers for custom backend
  Map<String, String> get headers {
    return Map<String, String>.from(config['headers'] as Map? ?? {});
  }
  
  factory BackendConfig.fromJson(Map<String, dynamic> json) => 
      _$BackendConfigFromJson(json);
  Map<String, dynamic> toJson() => _$BackendConfigToJson(this);
  
  BackendConfig copyWith({
    BackendType? type,
    String? name,
    Map<String, dynamic>? config,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return BackendConfig(
      type: type ?? this.type,
      name: name ?? this.name,
      config: config ?? this.config,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [type, name, config, isDefault, createdAt];
}

/// Supported backend types
enum BackendType {
  firebase,
  supabase,
  custom,
}

extension BackendTypeExtension on BackendType {
  String get displayName {
    switch (this) {
      case BackendType.firebase:
        return 'Firebase';
      case BackendType.supabase:
        return 'Supabase';
      case BackendType.custom:
        return 'Custom API';
    }
  }
  
  String get description {
    switch (this) {
      case BackendType.firebase:
        return 'Google Firebase Backend-as-a-Service';
      case BackendType.supabase:
        return 'Supabase Open Source Backend';
      case BackendType.custom:
        return 'Custom REST API Backend';
    }
  }
  
  List<String> get requiredFields {
    switch (this) {
      case BackendType.firebase:
        return ['projectId', 'apiKey', 'appId'];
      case BackendType.supabase:
        return ['url', 'anonKey'];
      case BackendType.custom:
        return ['baseUrl'];
    }
  }
}
