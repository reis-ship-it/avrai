import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

abstract class FunctionalKernelOs {
  Future<WhoKernelSnapshot> resolveWho(KernelEventEnvelope envelope);
  Future<WhatKernelSnapshot> resolveWhat(KernelEventEnvelope envelope);
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope);
  Future<WhereKernelSnapshot> resolveWhere(KernelEventEnvelope envelope);
  Future<HowKernelSnapshot> resolveHow(KernelEventEnvelope envelope);
  Future<KernelContextBundle> resolveKernelContext(
      KernelEventEnvelope envelope);
  Future<KernelBundleRecord> resolveAndExplain({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
  WhyKernelSnapshot explainWhy(KernelWhyRequest request);
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  });
}
