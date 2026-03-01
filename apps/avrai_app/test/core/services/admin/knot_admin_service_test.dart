// Unit tests for KnotAdminService
//
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/admin/knot_admin_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../../helpers/platform_channel_helper.dart';

/// Mock Rust API for testing
class MockRustLibApi implements RustLibApi {
  @override
  Float64List crateApiCalculateAlexanderPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, 0.0, -1.0]);
  }

  @override
  Float64List crateApiCalculateBoltzmannDistribution(
      {required List<double> energies, required double temperature}) {
    final sum = energies.fold<double>(0.0, (a, b) => a + b);
    return Float64List.fromList(energies.map((e) => e / sum).toList());
  }

  @override
  BigInt crateApiCalculateCrossingNumberFromBraid(
      {required List<double> braidData}) {
    return BigInt.from((braidData.length - 1) ~/ 2);
  }

  @override
  double crateApiCalculateEntropy({required List<double> probabilities}) {
    return 1.0;
  }

  @override
  double crateApiCalculateFreeEnergy(
      {required double energy,
      required double entropy,
      required double temperature}) {
    return energy - temperature * entropy;
  }

  @override
  Float64List crateApiCalculateJonesPolynomial(
      {required List<double> braidData}) {
    return Float64List.fromList([1.0, -1.0, 1.0]);
  }

  @override
  double crateApiCalculateKnotEnergyFromPoints(
      {required List<double> knotPoints}) {
    return 1.0;
  }

  @override
  double crateApiCalculateKnotStabilityFromPoints(
      {required List<double> knotPoints}) {
    return 0.5;
  }

  @override
  double crateApiCalculateTopologicalCompatibility(
      {required List<double> braidDataA, required List<double> braidDataB}) {
    final diff = (braidDataA.length - braidDataB.length).abs();
    return (1.0 - (diff / 10.0).clamp(0.0, 1.0));
  }

  @override
  int crateApiCalculateWritheFromBraid({required List<double> braidData}) {
    return (braidData.length - 1) ~/ 2;
  }

  @override
  double crateApiEvaluatePolynomial(
      {required List<double> coefficients, required double x}) {
    double result = 0.0;
    for (int i = 0; i < coefficients.length; i++) {
      result += coefficients[i] * (x * i);
    }
    return result;
  }

  @override
  KnotResult crateApiGenerateKnotFromBraid({required List<double> braidData}) {
    return KnotResult(
      knotData: Float64List.fromList([braidData[0]]),
      jonesPolynomial: Float64List.fromList([1.0, -1.0, 1.0]),
      alexanderPolynomial: Float64List.fromList([1.0, 0.0, -1.0]),
      crossingNumber: BigInt.from((braidData.length - 1) ~/ 2),
      writhe: (braidData.length - 1) ~/ 2,
      signature: 0,
      bridgeNumber: BigInt.from(1),
      braidIndex: BigInt.from(1),
      determinant: 1,
    );
  }

  @override
  double crateApiPolynomialDistance(
      {required List<double> coefficientsA,
      required List<double> coefficientsB}) {
    final maxLen = coefficientsA.length > coefficientsB.length
        ? coefficientsA.length
        : coefficientsB.length;
    double sumSq = 0.0;
    for (int i = 0; i < maxLen; i++) {
      final a = i < coefficientsA.length ? coefficientsA[i] : 0.0;
      final b = i < coefficientsB.length ? coefficientsB[i] : 0.0;
      sumSq += (a - b) * (a - b);
    }
    return sumSq;
  }
}

/// Mock AdminAuthService for testing
class MockAdminAuthService implements AdminAuthService {
  bool _isAuthenticated = true;

  MockAdminAuthService();

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
  }

  @override
  bool isAuthenticated() {
    return _isAuthenticated;
  }

  // Implement other required methods with minimal implementations
  // Note: These methods may not be used in the tests, but are required by the interface
  @override
  Future<AdminAuthResult> authenticate({
    required String username,
    required String password,
    String? twoFactorCode,
  }) async {
    // Return a simple result - the actual implementation details don't matter for these tests
    throw UnimplementedError('Mock authenticate not fully implemented');
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
  }

  String? getCurrentAdminId() => _isAuthenticated ? 'test_admin' : null;

  @override
  AdminSession? getCurrentSession() {
    return _isAuthenticated
        ? AdminSession(
            username: 'test_admin',
            loginTime: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 8)),
            accessLevel: AdminAccessLevel.godMode,
            permissions: AdminPermissions.all(),
          )
        : null;
  }

  @override
  bool hasPermission(AdminPermission permission) {
    return _isAuthenticated;
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
  }

  @override
  Future<void> extendSession() async {
    // No-op for mock
  }
}

void main() {
  group('KnotAdminService', () {
    late KnotAdminService adminService;
    late KnotStorageService storageService;
    late KnotDataAPI dataAPI;
    late PersonalityKnotService knotService;
    late MockAdminAuthService authService;

    setUpAll(() async {
      try {
        // Initialize Rust library for tests (mock mode)
        try {
          RustLib.initMock(api: MockRustLibApi());
        } catch (e) {
          // Already initialized, that's fine
        }

        // Ensure StorageService uses test storage (avoids path_provider / GetStorage.init).
        await setupTestStorage();

        // No-op: Sembast removed in Phase 26
      } catch (e) {
        // ignore: avoid_print
        print('Error in setUpAll: $e');
        rethrow;
      }
    });

    setUp(() {
      // Don't initialize DI - create services directly to avoid Supabase dependency
      storageService = KnotStorageService(
        storageService: StorageService.instance,
      );
      dataAPI = KnotDataAPI(
        knotStorageService: storageService,
        privacyService: KnotPrivacyService(),
      );
      knotService = PersonalityKnotService();
      authService = MockAdminAuthService();
      authService.setAuthenticated(true);

      adminService = KnotAdminService(
        knotStorageService: storageService,
        knotDataAPI: dataAPI,
        knotService: knotService,
        adminAuthService: authService,
      );
    });

    tearDown(() async {
      // No-op: Sembast removed in Phase 26
    });

    group('isAuthorized', () {
      test('should return true when admin is authenticated', () {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final isAuthorized = adminService.isAuthorized;

        // Assert
        expect(isAuthorized, isTrue);
      });

      test('should return false when admin is not authenticated', () {
        // Arrange
        authService.setAuthenticated(false);

        // Act
        final isAuthorized = adminService.isAuthorized;

        // Assert
        expect(isAuthorized, isFalse);
      });
    });

    group('getKnotDistributionData', () {
      test('should return distribution data when authorized', () async {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final distribution = await adminService.getKnotDistributionData();

        // Assert
        expect(distribution, isNotNull);
        expect(distribution.totalKnots, greaterThanOrEqualTo(0));
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);

        // Act & Assert
        expect(
          () => adminService.getKnotDistributionData(),
          throwsException,
        );
      });
    });

    group('getKnotPatternAnalysis', () {
      test('should return pattern analysis when authorized', () async {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final analysis = await adminService.getKnotPatternAnalysis(
          type: AnalysisType.weavingPatterns,
        );

        // Assert
        expect(analysis, isNotNull);
        expect(analysis.type, equals(AnalysisType.weavingPatterns));
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);

        // Act & Assert
        expect(
          () => adminService.getKnotPatternAnalysis(
            type: AnalysisType.weavingPatterns,
          ),
          throwsException,
        );
      });
    });

    group('getKnotPersonalityCorrelations', () {
      test('should return correlations when authorized', () async {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final correlations =
            await adminService.getKnotPersonalityCorrelations();

        // Assert
        expect(correlations, isNotNull);
        expect(correlations.correlationMatrix, isNotNull);
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);

        // Act & Assert
        expect(
          () => adminService.getKnotPersonalityCorrelations(),
          throwsException,
        );
      });
    });

    group('getUserKnot', () {
      test('should return knot when authorized and knot exists', () async {
        // Arrange
        authService.setAuthenticated(true);
        final testKnot = PersonalityKnot(
          agentId: 'test_user_1234567890',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        await storageService.saveKnot(testKnot.agentId, testKnot);

        // Act
        final knot = await adminService.getUserKnot(testKnot.agentId);

        // Assert
        expect(knot, isNotNull);
        expect(knot!.agentId, equals(testKnot.agentId));
      });

      test('should return null when knot does not exist', () async {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final knot =
            await adminService.getUserKnot('nonexistent_user_1234567890');

        // Assert
        expect(knot, isNull);
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);

        // Act & Assert
        expect(
          () => adminService.getUserKnot('test_user'),
          throwsException,
        );
      });
    });

    group('validateKnot', () {
      test('should return true for valid knot', () async {
        // Arrange
        authService.setAuthenticated(true);
        final validKnot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final isValid = await adminService.validateKnot(validKnot);

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for invalid knot (empty braid)', () async {
        // Arrange
        authService.setAuthenticated(true);
        final invalidKnot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act
        final isValid = await adminService.validateKnot(invalidKnot);

        // Assert
        expect(isValid, isFalse);
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);
        final knot = PersonalityKnot(
          agentId: 'test_user',
          braidData: [8.0, 1.0, 0.0, 2.0, 1.0],
          invariants: KnotInvariants(
            jonesPolynomial: [1.0, -1.0, 1.0],
            alexanderPolynomial: [1.0, 0.0, -1.0],
            crossingNumber: 3,
            writhe: 1,
            signature: 0,
            bridgeNumber: 1,
            braidIndex: 1,
            determinant: 1,
          ),
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => adminService.validateKnot(knot),
          throwsException,
        );
      });
    });

    group('getSystemKnotStatistics', () {
      test('should return statistics when authorized', () async {
        // Arrange
        authService.setAuthenticated(true);

        // Act
        final stats = await adminService.getSystemKnotStatistics();

        // Assert
        expect(stats, isNotNull);
        expect(stats['totalKnots'], isNotNull);
        expect(stats['averageCrossingNumber'], isNotNull);
        expect(stats['averageWrithe'], isNotNull);
      });

      test('should throw exception when not authorized', () async {
        // Arrange
        authService.setAuthenticated(false);

        // Act & Assert
        expect(
          () => adminService.getSystemKnotStatistics(),
          throwsException,
        );
      });
    });
  });
}
