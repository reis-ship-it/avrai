import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:reality_engine/reality_engine.dart';

class HierarchicalLocalityVibeProjector {
  HierarchicalLocalityVibeProjector({
    VibeKernel? vibeKernel,
    GovernanceKernelService? governanceKernel,
  })  : _vibeKernel = vibeKernel ?? VibeKernel(),
        _governanceKernel = governanceKernel ?? GovernanceKernelService();

  final VibeKernel _vibeKernel;
  final GovernanceKernelService _governanceKernel;

  static const Map<GeographicAgentLevel, double> _attenuationByLevel =
      <GeographicAgentLevel, double>{
    GeographicAgentLevel.locality: 1.0,
    GeographicAgentLevel.district: 0.82,
    GeographicAgentLevel.city: 0.68,
    GeographicAgentLevel.region: 0.54,
    GeographicAgentLevel.country: 0.42,
    GeographicAgentLevel.global: 0.32,
  };

  List<VibeUpdateReceipt> projectObservation({
    required GeographicVibeBinding binding,
    required Map<String, double> dimensions,
    required String source,
    List<String> provenanceTags = const <String>[],
  }) {
    final receipts = <VibeUpdateReceipt>[];
    for (final entry in _orderedSubjects(binding)) {
      final subjectRef = entry.$1;
      final attenuation = entry.$2;
      final governedDimensions = _attenuateDimensions(
        dimensions,
        attenuation: attenuation,
      );
      final mutationDecision = _governanceKernel.authorizeVibeMutation(
        subjectId: subjectRef.subjectId,
        governanceScope: _governanceScopeFor(subjectRef),
        evidence: _dimensionsToEvidence(
          subjectRef: subjectRef,
          dimensions: governedDimensions,
          source: source,
          provenanceTags: provenanceTags,
        ),
      );
      if (!mutationDecision.stateWriteAllowed) {
        continue;
      }
      receipts.add(
        _vibeKernel.ingestEcosystemObservation(
          subjectId: subjectRef.subjectId,
          subjectKind: subjectRef.kind.canonicalKind,
          source: source,
          dimensions: governedDimensions,
          provenanceTags: provenanceTags,
        ),
      );
    }
    return receipts;
  }

  List<(VibeSubjectRef, double)> _orderedSubjects(
      GeographicVibeBinding binding) {
    final subjects = <String, (VibeSubjectRef, double)>{
      binding.localityRef.subjectId: (
        VibeSubjectRef.locality(binding.stableKey),
        _attenuationByLevel[GeographicAgentLevel.locality]!,
      ),
      if ((binding.districtCode ?? '').trim().isNotEmpty)
        'district:${binding.districtCode}': (
          VibeSubjectRef.district(binding.districtCode!.trim()),
          _attenuationByLevel[GeographicAgentLevel.district]!,
        ),
      if ((binding.cityCode ?? '').trim().isNotEmpty)
        'city:${binding.cityCode}': (
          VibeSubjectRef.city(binding.cityCode!.trim()),
          _attenuationByLevel[GeographicAgentLevel.city]!,
        ),
      if ((binding.regionCode ?? '').trim().isNotEmpty)
        'region:${binding.regionCode}': (
          VibeSubjectRef.region(binding.regionCode!.trim()),
          _attenuationByLevel[GeographicAgentLevel.region]!,
        ),
      if ((binding.countryCode ?? '').trim().isNotEmpty)
        'country:${binding.countryCode}': (
          VibeSubjectRef.country(binding.countryCode!.trim()),
          _attenuationByLevel[GeographicAgentLevel.country]!,
        ),
      if ((binding.globalCode ?? '').trim().isNotEmpty)
        'global:${binding.globalCode}': (
          VibeSubjectRef.global(binding.globalCode!.trim()),
          _attenuationByLevel[GeographicAgentLevel.global]!,
        ),
    };

    for (final higherRef in binding.higherGeographicRefs) {
      final level = higherRef.effectiveGeographicLevel;
      if (level == null) {
        continue;
      }
      subjects.putIfAbsent(
        '${level.toWireValue()}:${higherRef.subjectId}',
        () => (
          VibeSubjectRef.fromJson(higherRef.toJson()),
          _attenuationByLevel[level] ?? 0.5,
        ),
      );
    }

    final ordered = subjects.values.toList(growable: false);
    ordered.sort((left, right) {
      final leftLevel =
          left.$1.effectiveGeographicLevel ?? GeographicAgentLevel.locality;
      final rightLevel =
          right.$1.effectiveGeographicLevel ?? GeographicAgentLevel.locality;
      return leftLevel.index.compareTo(rightLevel.index);
    });
    return ordered;
  }

  Map<String, double> _attenuateDimensions(
    Map<String, double> dimensions, {
    required double attenuation,
  }) {
    return <String, double>{
      for (final entry in dimensions.entries)
        entry.key: (entry.value * attenuation + (0.5 * (1 - attenuation)))
            .clamp(0.0, 1.0),
    };
  }

  VibeEvidence _dimensionsToEvidence({
    required VibeSubjectRef subjectRef,
    required Map<String, double> dimensions,
    required String source,
    required List<String> provenanceTags,
  }) {
    return VibeEvidence(
      summary:
          'Governed geographic observation for ${subjectRef.subjectId} from $source.',
      identitySignals: dimensions.entries
          .map(
            (entry) => VibeSignal(
              key: entry.key,
              kind: VibeSignalKind.identity,
              value: entry.value,
              confidence: 0.72,
              provenance: <String>[source, ...provenanceTags],
            ),
          )
          .toList(growable: false),
      pheromoneSignals: const <VibeSignal>[],
      behaviorSignals: const <VibeSignal>[],
      affectiveSignals: const <VibeSignal>[],
      styleSignals: const <VibeSignal>[],
    );
  }

  String _governanceScopeFor(VibeSubjectRef subjectRef) {
    final level =
        subjectRef.effectiveGeographicLevel?.toWireValue() ?? 'locality';
    return 'geographic:$level';
  }
}
