import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';

class HeadlessAvraiOsHostState {
  const HeadlessAvraiOsHostState({
    required this.started,
    required this.startedAtUtc,
    required this.localityContainedInWhere,
    required this.summary,
  });

  final bool started;
  final DateTime startedAtUtc;
  final bool localityContainedInWhere;
  final String summary;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'started': started,
        'started_at_utc': startedAtUtc.toUtc().toIso8601String(),
        'locality_contained_in_where': localityContainedInWhere,
        'summary': summary,
      };

  factory HeadlessAvraiOsHostState.fromJson(Map<String, dynamic> json) {
    return HeadlessAvraiOsHostState(
      started: json['started'] as bool? ?? false,
      startedAtUtc:
          DateTime.tryParse(json['started_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      localityContainedInWhere:
          json['locality_contained_in_where'] as bool? ?? false,
      summary: json['summary'] as String? ?? 'Headless AVRAI OS state restored',
    );
  }
}

abstract class HeadlessAvraiOsHost {
  Future<HeadlessAvraiOsHostState> start();
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  });
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
  Future<List<KernelHealthReport>> healthCheck();
}

class DefaultHeadlessAvraiOsHost implements HeadlessAvraiOsHost {
  DefaultHeadlessAvraiOsHost({
    required this.modelTruthPort,
    required this.runtimeExecutionPort,
    required this.trustGovernancePort,
    required this.whoKernel,
    required this.whatKernel,
    required this.whenKernel,
    required this.whereKernel,
    required this.howKernel,
    required this.whyKernel,
  });

  final ModelTruthPort modelTruthPort;
  final RuntimeExecutionPort runtimeExecutionPort;
  final TrustGovernancePort trustGovernancePort;
  final WhoKernelContract whoKernel;
  final WhatKernelContract whatKernel;
  final WhenKernelContract whenKernel;
  final WhereKernelContract whereKernel;
  final HowKernelContract howKernel;
  final WhyKernelContract whyKernel;

  HeadlessAvraiOsHostState? _state;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    _state ??= HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.now().toUtc(),
      localityContainedInWhere: true,
      summary: 'Headless AVRAI OS host started with locality inside where',
    );
    return _state!;
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    await start();
    return modelTruthPort.buildRealityKernelFusionInput(
      envelope: envelope,
      whyRequest: whyRequest,
    );
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) async {
    await start();
    return runtimeExecutionPort.resolveRuntimeExecution(envelope: envelope);
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    await start();
    return trustGovernancePort.inspectTrustGovernance(
      envelope: envelope,
      whyRequest: whyRequest,
    );
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async {
    await start();
    return <KernelHealthReport>[
      await whoKernel.diagnoseWho(),
      await whatKernel.diagnoseWhat(),
      await whenKernel.diagnoseWhen(),
      await whereKernel.diagnoseWhere(),
      await howKernel.diagnoseHow(),
      await whyKernel.diagnoseWhy(),
    ];
  }
}
