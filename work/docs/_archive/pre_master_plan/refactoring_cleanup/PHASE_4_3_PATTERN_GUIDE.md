# Pattern Usage Guide

**Date:** January 2025  
**Purpose:** Guide for developers on using common patterns in the SPOTS codebase

---

## 📋 **AVAILABLE PATTERNS**

### **1. Repository Patterns** ✅

**Location:** `lib/data/repositories/repository_patterns.dart`  
**Base Class:** `SimplifiedRepositoryBase`

#### **Usage:**

```dart
class MyRepository extends SimplifiedRepositoryBase implements MyRepositoryInterface {
  final MyLocalDataSource _localDataSource;
  final MyRemoteDataSource? _remoteDataSource;
  
  MyRepository({
    required Connectivity connectivity, // or null for local-only
    required MyLocalDataSource localDataSource,
    MyRemoteDataSource? remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       super(connectivity: connectivity);

  // Offline-first: Returns local immediately, syncs with remote if online
  @override
  Future<List<MyModel>> getAll() async {
    return executeOfflineFirst<List<MyModel>>(
      localOperation: () => _localDataSource.getAll(),
      remoteOperation: _remoteDataSource != null 
          ? () => _remoteDataSource!.getAll()
          : null,
      syncToLocal: (remoteData) async {
        // Sync remote data to local storage if needed
      },
    );
  }

  // Online-first: Tries remote first, falls back to local
  @override
  Future<MyModel?> getById(String id) async {
    return executeOnlineFirst<MyModel?>(
      remoteOperation: () => _remoteDataSource!.getById(id),
      localOperation: () => _localDataSource.getById(id),
      syncToLocal: (remoteData) async {
        // Save remote data to local
      },
    );
  }

  // Local-only: No network interaction
  @override
  Future<void> delete(String id) async {
    return executeLocalOnly(
      localOperation: () => _localDataSource.delete(id),
    );
  }

  // Remote-only: Requires network
  @override
  Future<MyModel> create(MyModel model) async {
    return executeRemoteOnly<MyModel>(
      remoteOperation: () => _remoteDataSource!.create(model),
    );
  }
}
```

#### **Patterns:**
- **`executeOfflineFirst<T>()`** - Local-first with remote sync (use for most read operations)
- **`executeOnlineFirst<T>()`** - Remote-first with local fallback (use for operations that need latest data)
- **`executeLocalOnly<T>()`** - Local operations only (use for offline-only features)
- **`executeRemoteOnly<T>()`** - Network-required operations (use for operations that must sync immediately)

#### **Connectivity:**
- Pass `Connectivity` to constructor for online/offline support
- Pass `null` for local-only repositories

---

### **2. Logging Pattern** ✅

**Location:** `lib/core/services/logger.dart`  
**Class:** `AppLogger`

#### **Usage:**

```dart
class MyService {
  static const String _logName = 'MyService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  Future<void> myMethod() async {
    _logger.debug('Starting operation', tag: _logName);
    
    try {
      // Operation code
      _logger.info('Operation completed', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      rethrow;
    }
  }
}
```

#### **Log Levels:**
- `debug()` - Detailed debug information
- `info()` - General information
- `warn()` / `warning()` - Warning messages
- `error()` - Error messages (includes error and stackTrace)

#### **Best Practices:**
- Use consistent tag names (service name)
- Include context in log messages
- Always log errors with stack traces
- Use appropriate log levels

---

### **3. Error Handling Patterns** ⚠️

**Domain-Specific Handlers:**
- `ActionErrorHandler` - For action execution errors
- `AnonymizationErrorHandler` - For anonymization/privacy errors

#### **General Service Error Handling:**

```dart
try {
  // Operation code
  return result;
} catch (e, stackTrace) {
  _logger.error(
    'Operation failed: ${operationDescription}',
    error: e,
    stackTrace: stackTrace,
    tag: _logName,
  );
  
  // Re-throw or return error result based on service needs
  rethrow;
  // OR
  return ErrorResult(error: e);
}
```

#### **Best Practices:**
- Always log errors with context
- Include stack traces for debugging
- Provide user-friendly error messages when appropriate
- Don't swallow errors silently

---

### **4. Connectivity Checking** ✅

**For Repositories:** Use `SimplifiedRepositoryBase.isOnline` getter

```dart
if (await isOnline) {
  // Online operations
} else {
  // Offline operations
}
```

**For Services:** Use `Connectivity` service directly (if needed)

```dart
class MyService {
  final Connectivity _connectivity;
  
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false; // Assume offline on error
    }
  }
}
```

**Note:** Most services should use repositories which handle connectivity automatically.

---

## ✅ **PATTERN DECISIONS**

### **When to Use Each Repository Pattern:**

| Pattern | Use Case | Example |
|---------|----------|---------|
| `executeOfflineFirst` | Most read operations | Get spots, get lists |
| `executeOnlineFirst` | Operations needing latest data | Get current user, auth operations |
| `executeLocalOnly` | Offline-only features | Tax profiles, decoherence patterns |
| `executeRemoteOnly` | Operations requiring sync | Password updates, critical writes |

### **When to Create New Patterns:**

Only extract patterns if:
- ✅ Used by 5+ services/components
- ✅ Significant code duplication (>10 lines)
- ✅ Clear, reusable pattern (not service-specific)
- ✅ High maintenance benefit

**Examples of patterns NOT worth extracting:**
- Service-specific initialization logic
- One-off retry implementations
- Domain-specific error handling (use domain handlers instead)

---

## 📚 **PATTERN REFERENCE**

### **Quick Reference:**

1. **Repository Operations:** Extend `SimplifiedRepositoryBase`, use pattern methods
2. **Logging:** Use `AppLogger` with consistent tags
3. **Error Handling:** Log with context, don't swallow errors
4. **Connectivity:** Use repository patterns (they handle connectivity)

### **Documentation:**
- Repository Patterns: `lib/data/repositories/repository_patterns.dart`
- Logging: `lib/core/services/logger.dart`
- Error Handlers: `lib/core/services/action_error_handler.dart`, `lib/core/services/anonymization_error_handler.dart`

---

**Last Updated:** January 2025
