import 'package:equatable/equatable.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';

class LocalityAdminDiagnosticsProbe extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime occurredAtUtc;
  final bool includePrediction;

  const LocalityAdminDiagnosticsProbe({
    required this.latitude,
    required this.longitude,
    required this.occurredAtUtc,
    this.includePrediction = true,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
        'audience': LocalityProjectionAudience.admin.name,
        'includeGeometry': true,
        'includeAttribution': true,
        'includePrediction': includePrediction,
      };

  @override
  List<Object?> get props =>
      [latitude, longitude, occurredAtUtc, includePrediction];
}

class LocalityAdminTopLocality extends Equatable {
  final String label;
  final int count;

  const LocalityAdminTopLocality({
    required this.label,
    required this.count,
  });

  factory LocalityAdminTopLocality.fromJson(Map<String, dynamic> json) {
    return LocalityAdminTopLocality(
      label: (json['label'] as String?) ?? 'unresolved',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [label, count];
}

class LocalityAdminDiagnosticsReport extends Equatable {
  final String executionPath;
  final bool nativeAvailable;
  final bool nativeRequired;
  final int nativeHandledCount;
  final int fallbackUnavailableCount;
  final int fallbackDeferredCount;
  final List<LocalityPointResolution> resolutions;
  final int resolutionCount;
  final List<LocalityAdminTopLocality> topLocalities;
  final int nearBoundaryCount;
  final int highConfidenceCount;
  final int advisoryActiveCount;
  final int predictiveChangeCount;
  final Map<String, int> predictiveBreakdown;
  final Map<String, int> stabilityBreakdown;
  final LocalityPointResolution? sampleResolution;
  final LocalityZeroReliabilityReport zeroLocalityReport;
  final String cityProfile;
  final Map<String, dynamic> stateStore;

  const LocalityAdminDiagnosticsReport({
    required this.executionPath,
    required this.nativeAvailable,
    required this.nativeRequired,
    required this.nativeHandledCount,
    required this.fallbackUnavailableCount,
    required this.fallbackDeferredCount,
    required this.resolutions,
    required this.resolutionCount,
    required this.topLocalities,
    required this.nearBoundaryCount,
    required this.highConfidenceCount,
    required this.advisoryActiveCount,
    required this.predictiveChangeCount,
    required this.predictiveBreakdown,
    required this.stabilityBreakdown,
    required this.sampleResolution,
    required this.zeroLocalityReport,
    required this.cityProfile,
    required this.stateStore,
  });

  factory LocalityAdminDiagnosticsReport.fromJson(Map<String, dynamic> json) {
    final sampleResolutionJson = json['sampleResolution'];
    return LocalityAdminDiagnosticsReport(
      executionPath: (json['executionPath'] as String?) ?? 'unknown',
      nativeAvailable: json['nativeAvailable'] as bool? ?? false,
      nativeRequired: json['nativeRequired'] as bool? ?? false,
      nativeHandledCount: (json['nativeHandledCount'] as num?)?.toInt() ?? 0,
      fallbackUnavailableCount:
          (json['fallbackUnavailableCount'] as num?)?.toInt() ?? 0,
      fallbackDeferredCount:
          (json['fallbackDeferredCount'] as num?)?.toInt() ?? 0,
      resolutions: (json['resolutions'] as List?)
              ?.map(
                (entry) => LocalityPointResolution.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const <LocalityPointResolution>[],
      resolutionCount: (json['resolutionCount'] as num?)?.toInt() ?? 0,
      topLocalities: (json['topLocalities'] as List?)
              ?.map(
                (entry) => LocalityAdminTopLocality.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const <LocalityAdminTopLocality>[],
      nearBoundaryCount: (json['nearBoundaryCount'] as num?)?.toInt() ?? 0,
      highConfidenceCount: (json['highConfidenceCount'] as num?)?.toInt() ?? 0,
      advisoryActiveCount: (json['advisoryActiveCount'] as num?)?.toInt() ?? 0,
      predictiveChangeCount:
          (json['predictiveChangeCount'] as num?)?.toInt() ?? 0,
      predictiveBreakdown: (json['predictiveBreakdown'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toInt() ?? 0,
            ),
          ) ??
          const <String, int>{},
      stabilityBreakdown: (json['stabilityBreakdown'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toInt() ?? 0,
            ),
          ) ??
          const <String, int>{},
      sampleResolution: sampleResolutionJson is Map
          ? LocalityPointResolution.fromJson(
              Map<String, dynamic>.from(sampleResolutionJson),
            )
          : null,
      zeroLocalityReport: LocalityZeroReliabilityReport.fromJson(
        Map<String, dynamic>.from(
          json['zeroLocalityReport'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      cityProfile: (json['cityProfile'] as String?) ?? 'unknown',
      stateStore: Map<String, dynamic>.from(
        json['stateStore'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  bool get servedNatively => executionPath == 'native';

  int get totalFallbackCount =>
      fallbackUnavailableCount + fallbackDeferredCount;

  @override
  List<Object?> get props => [
        executionPath,
        nativeAvailable,
        nativeRequired,
        nativeHandledCount,
        fallbackUnavailableCount,
        fallbackDeferredCount,
        resolutions,
        resolutionCount,
        topLocalities,
        nearBoundaryCount,
        highConfidenceCount,
        advisoryActiveCount,
        predictiveChangeCount,
        predictiveBreakdown,
        stabilityBreakdown,
        sampleResolution,
        zeroLocalityReport,
        cityProfile,
        stateStore,
      ];
}

class LocalityNativeAdminDiagnosticsBridge {
  final LocalityNativeInvocationBridge nativeBridge;
  final LocalityWhereProviderFallbackSurface fallbackKernel;
  final LocalityNativeExecutionPolicy policy;
  final LocalityNativeFallbackAudit? audit;

  const LocalityNativeAdminDiagnosticsBridge({
    required this.nativeBridge,
    required this.fallbackKernel,
    this.policy = const LocalityNativeExecutionPolicy(),
    this.audit,
  });

  Future<LocalityAdminDiagnosticsReport> diagnose({
    required List<LocalityAdminDiagnosticsProbe> probes,
    String? cityProfile,
    String modelFamily = 'reality_kernel',
  }) async {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(
        syscall: 'diagnose_locality_admin',
        payload: {
          'probes': probes.map((probe) => probe.toJson()).toList(),
          if (cityProfile != null) 'cityProfile': cityProfile,
          'modelFamily': modelFamily,
        },
      );
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        final payload = Map<String, dynamic>.from(response['payload'] as Map);
        return LocalityAdminDiagnosticsReport.fromJson(
          _decorateExecutionMetadata(
            payload,
            executionPath: 'native',
          ),
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: 'diagnose_locality_admin',
        reason: LocalityNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: 'diagnose_locality_admin',
        reason: LocalityNativeFallbackReason.unavailable,
      );
    }

    final resolutions = await Future.wait<LocalityPointResolution>(
      probes.map(
        (probe) => fallbackKernel.resolvePoint(
          LocalityPointQuery(
            latitude: probe.latitude,
            longitude: probe.longitude,
            occurredAtUtc: probe.occurredAtUtc,
            audience: LocalityProjectionAudience.admin,
            includeGeometry: true,
            includeAttribution: true,
            includePrediction: probe.includePrediction,
          ),
        ),
      ),
    );
    final topLocalities = <String, int>{};
    final predictiveBreakdown = <String, int>{};
    final stabilityBreakdown = <String, int>{};
    var nearBoundaryCount = 0;
    var highConfidenceCount = 0;
    var advisoryActiveCount = 0;
    var predictiveChangeCount = 0;
    for (final resolution in resolutions) {
      final projection = resolution.projection;
      final metadata = projection.metadata;
      topLocalities.update(
        projection.primaryLabel,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (projection.nearBoundary) {
        nearBoundaryCount += 1;
      }
      if (projection.confidenceBucket == 'high') {
        highConfidenceCount += 1;
      }
      if (metadata['advisoryStatus'] == 'active') {
        advisoryActiveCount += 1;
      }
      final predictiveTrend =
          (metadata['predictiveTrend'] as String?) ?? 'stable';
      predictiveBreakdown.update(
        predictiveTrend,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (predictiveTrend != 'stable') {
        predictiveChangeCount += 1;
      }
      final stabilityClass = (metadata['stabilityClass'] as String?) ?? 'watch';
      stabilityBreakdown.update(
        stabilityClass,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final sortedTopLocalities = topLocalities.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final sampleResolution = resolutions.isEmpty
        ? null
        : (resolutions.toList()
              ..sort(
                (left, right) =>
                    right.state.confidence.compareTo(left.state.confidence),
              ))
            .first;
    final derivedCityProfile = cityProfile ??
        sampleResolution?.cityCode ??
        sampleResolution?.displayName ??
        sampleResolution?.projection.primaryLabel ??
        'birmingham_alabama';
    final zeroLocalityReport =
        await fallbackKernel.evaluateZeroLocalityReadiness(
      cityProfile: derivedCityProfile,
      modelFamily: modelFamily,
      localityCount: resolutions.length < 12 ? 12 : resolutions.length,
    );

    return LocalityAdminDiagnosticsReport(
      executionPath: 'fallback',
      nativeAvailable: nativeBridge.isAvailable,
      nativeRequired: policy.requireNative,
      nativeHandledCount: audit?.nativeHandledCount ?? 0,
      fallbackUnavailableCount: audit?.fallbackUnavailableCount ?? 0,
      fallbackDeferredCount: audit?.fallbackDeferredCount ?? 0,
      resolutions: resolutions,
      resolutionCount: resolutions.length,
      topLocalities: sortedTopLocalities
          .map(
            (entry) => LocalityAdminTopLocality(
              label: entry.key,
              count: entry.value,
            ),
          )
          .toList(),
      nearBoundaryCount: nearBoundaryCount,
      highConfidenceCount: highConfidenceCount,
      advisoryActiveCount: advisoryActiveCount,
      predictiveChangeCount: predictiveChangeCount,
      predictiveBreakdown: predictiveBreakdown,
      stabilityBreakdown: stabilityBreakdown,
      sampleResolution: sampleResolution,
      zeroLocalityReport: zeroLocalityReport,
      cityProfile: derivedCityProfile,
      stateStore: const <String, dynamic>{'schemaVersion': 0},
    );
  }

  Map<String, dynamic> _decorateExecutionMetadata(
    Map<String, dynamic> payload, {
    required String executionPath,
  }) {
    return <String, dynamic>{
      ...payload,
      'executionPath': executionPath,
      'nativeAvailable': nativeBridge.isAvailable,
      'nativeRequired': policy.requireNative,
      'nativeHandledCount': audit?.nativeHandledCount ?? 0,
      'fallbackUnavailableCount': audit?.fallbackUnavailableCount ?? 0,
      'fallbackDeferredCount': audit?.fallbackDeferredCount ?? 0,
    };
  }
}
