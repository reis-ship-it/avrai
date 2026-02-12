import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Manages network connectivity status and monitoring
class ConnectivityManager {
  static ConnectivityManager? _instance;
  static ConnectivityManager get instance => _instance ??= ConnectivityManager._();
  
  ConnectivityManager._();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  bool _isInitialized = false;
  
  /// Get current connectivity status
  bool get isConnected => _isConnected;
  
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _statusController.stream;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check initial connectivity
    await _updateConnectivityStatus();
    
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        developer.log('ConnectivityManager error: $error', name: 'ConnectivityManager');
      },
    );
    
    _isInitialized = true;
  }
  
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
    _isInitialized = false;
  }
  
  /// Manually check connectivity
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return _isConnected;
  }
  
  /// Test actual internet connectivity (not just network interface)
  Future<bool> testInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get detailed connectivity information
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasInternet = await testInternetConnectivity();
    
    return ConnectivityInfo(
      hasConnection: connectivityResults.isNotEmpty && 
                    !connectivityResults.contains(ConnectivityResult.none),
      hasInternet: hasInternet,
      connectionTypes: connectivityResults,
      lastChecked: DateTime.now(),
    );
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivityStatus();
  }
  
  /// Update connectivity status
  Future<void> _updateConnectivityStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final wasConnected = _isConnected;
      
      _isConnected = connectivityResults.isNotEmpty && 
                    !connectivityResults.contains(ConnectivityResult.none);
      
      // Only emit if status changed
      if (wasConnected != _isConnected) {
        _statusController.add(_isConnected);
      }
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'ConnectivityManager', error: e);
      _isConnected = false;
      _statusController.add(false);
    }
  }
}

/// Detailed connectivity information
class ConnectivityInfo {
  final bool hasConnection;
  final bool hasInternet;
  final List<ConnectivityResult> connectionTypes;
  final DateTime lastChecked;
  
  const ConnectivityInfo({
    required this.hasConnection,
    required this.hasInternet,
    required this.connectionTypes,
    required this.lastChecked,
  });
  
  /// Check if connected via WiFi
  bool get isWiFi => connectionTypes.contains(ConnectivityResult.wifi);
  
  /// Check if connected via mobile data
  bool get isMobile => connectionTypes.contains(ConnectivityResult.mobile);
  
  /// Check if connected via ethernet
  bool get isEthernet => connectionTypes.contains(ConnectivityResult.ethernet);
  
  /// Get primary connection type
  ConnectivityResult? get primaryConnectionType =>
      connectionTypes.isNotEmpty ? connectionTypes.first : null;
  
  /// Get human-readable connection description
  String get connectionDescription {
    if (!hasConnection) return 'No connection';
    
    final types = <String>[];
    if (isWiFi) types.add('WiFi');
    if (isMobile) types.add('Mobile');
    if (isEthernet) types.add('Ethernet');
    
    if (types.isEmpty) return 'Unknown connection';
    
    final description = types.join(' + ');
    return hasInternet ? description : '$description (No Internet)';
  }
  
  @override
  String toString() {
    return 'ConnectivityInfo(hasConnection: $hasConnection, '
           'hasInternet: $hasInternet, types: $connectionTypes, '
           'lastChecked: $lastChecked)';
  }
}

/// Connectivity status helper
class ConnectivityHelper {
  /// Wait for connectivity to be restored
  static Future<void> waitForConnectivity({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final manager = ConnectivityManager.instance;
    
    if (manager.isConnected) return;
    
    final completer = Completer<void>();
    StreamSubscription<bool>? subscription;
    Timer? timeoutTimer;
    
    subscription = manager.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    
    timeoutTimer = Timer(timeout, () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const ConnectivityTimeoutException('Connectivity timeout'));
      }
    });
    
    return completer.future;
  }
  
  /// Execute operation with connectivity check
  static Future<T> withConnectivity<T>(Future<T> Function() operation) async {
    final manager = ConnectivityManager.instance;
    
    if (!manager.isConnected) {
      throw const ConnectivityException();
    }
    
    return await operation();
  }
  
  /// Execute operation with automatic retry on connectivity issues
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await withConnectivity(operation);
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) rethrow;
        
        // Wait for connectivity if needed
        if (e is ConnectivityException) {
          try {
            await waitForConnectivity(timeout: retryDelay);
          } catch (_) {
            // Continue to next attempt even if timeout
          }
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }
    
    throw StateError('Should not reach here');
  }
}

/// Exception thrown when no internet connection is available
class ConnectivityException implements Exception {
  final String message;
  
  const ConnectivityException([this.message = 'No internet connection']);
  
  @override
  String toString() => 'ConnectivityException: $message';
}

/// Exception thrown when connectivity operation times out
class ConnectivityTimeoutException implements Exception {
  final String message;
  
  const ConnectivityTimeoutException([this.message = 'Operation timed out']);
  
  @override
  String toString() => 'ConnectivityTimeoutException: $message';
}
