import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';

/// In-memory GetStorage implementation for testing
/// Uses mocktail to create a proper GetStorage mock that implements the interface
/// and uses an in-memory map for storage, avoiding platform channel requirements
class InMemoryGetStorage extends Mock implements GetStorage {
  final String boxName;
  final Map<String, dynamic> _storage;
  
  InMemoryGetStorage(this.boxName, [Map<String, dynamic>? initialData])
      : _storage = Map<String, dynamic>.from(initialData ?? {}) {
    // Set up default behavior for all GetStorage methods
    _setupDefaultBehavior();
  }
  
  void _setupDefaultBehavior() {
    // Write: store in map
    when(() => write(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1];
      _storage[key] = value;
    });
    
    // Remove: remove from map
    when(() => remove(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      _storage.remove(key);
    });
    
    // Erase: clear map
    when(() => erase()).thenAnswer((_) async {
      _storage.clear();
    });
    
    // HasData: check if key exists
    when(() => hasData(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return _storage.containsKey(key);
    });
    
    // GetKeys: return all keys (GetStorage.getKeys() returns List<String>)
    when(() => getKeys()).thenAnswer((_) {
      return _storage.keys.map((k) => k.toString()).toList();
    });
  }
  
  /// Override noSuchMethod to handle generic read&lt;T&gt;() calls
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Handle read<T>(key) calls
    if (invocation.memberName == #read && invocation.positionalArguments.length == 1) {
      final key = invocation.positionalArguments[0] as String;
      final value = _storage[key];
      
      // Get the return type from the type arguments
      final typeArgs = invocation.typeArguments;
      if (typeArgs.isNotEmpty) {
        final returnType = typeArgs[0];
        return _castValue(value, returnType);
      }
      
      return value;
    }
    
    // Fall back to super for other methods
    return super.noSuchMethod(invocation);
  }
  
  /// Cast value to the requested type
  dynamic _castValue(dynamic value, Type returnType) {
    if (value == null) return null;
    
    // Direct type match
    if (value.runtimeType == returnType) {
      return value;
    }
    
    // Type conversions
    if (returnType == String && value != null) {
      return value.toString();
    }
    if (returnType == int && value is num) {
      return value.toInt();
    }
    if (returnType == double && value is num) {
      return value.toDouble();
    }
    if (returnType == bool && value is bool) {
      return value;
    }
    if (returnType == List && value is List) {
      return value;
    }
    
    // Try to cast if possible
    try {
      return value as dynamic;
    } catch (e) {
      return null;
    }
  }
  
  /// Direct access to storage map (for testing/debugging)
  Map<String, dynamic> get storage => Map.unmodifiable(_storage);
}

/// Mock GetStorage implementation for testing
/// Provides in-memory storage instances that don't require platform channels
class MockGetStorage {
  static final Map<String, InMemoryGetStorage> _instances = {};
  static final Map<String, Map<String, dynamic>> _initialData = {};
  
  /// Get a GetStorage-compatible instance for testing
  /// Returns a mocktail-based mock that implements GetStorage interface
  /// and uses an in-memory map for storage, avoiding platform channel requirements
  /// 
  /// [boxName] - Optional box name, defaults to 'test_box'
  static GetStorage getInstance({String boxName = 'test_box'}) {
    if (!_instances.containsKey(boxName)) {
      final data = _initialData[boxName] ?? <String, dynamic>{};
      _instances[boxName] = InMemoryGetStorage(boxName, data);
    }
    return _instances[boxName]!;
  }
  
  /// Get the underlying InMemoryGetStorage instance (for advanced use)
  /// Use this if you need direct access to the storage map
  /// 
  /// [boxName] - Optional box name, defaults to 'test_box'
  static InMemoryGetStorage getInstanceAsInMemory({String boxName = 'test_box'}) {
    if (!_instances.containsKey(boxName)) {
      final data = _initialData[boxName] ?? <String, dynamic>{};
      _instances[boxName] = InMemoryGetStorage(boxName, data);
    }
    return _instances[boxName]!;
  }
  
  /// Reset all storage instances
  static void reset() {
    for (var instance in _instances.values) {
      instance.erase();
    }
    _instances.clear();
    _initialData.clear();
  }
  
  /// Clear all stored data for a specific box
  static void clear({String boxName = 'test_box'}) {
    _initialData[boxName]?.clear();
    _instances[boxName]?.erase();
  }
  
  /// Set initial data for a box
  static void setInitialData(String boxName, Map<String, dynamic> data) {
    _initialData[boxName] = Map<String, dynamic>.from(data);
    // Update existing instance if it exists
    if (_instances.containsKey(boxName)) {
      _instances[boxName]!.erase();
      for (final entry in data.entries) {
        _instances[boxName]!.write(entry.key, entry.value);
      }
    }
  }
}
