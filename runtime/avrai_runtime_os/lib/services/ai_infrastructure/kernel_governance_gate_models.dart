part of 'kernel_governance_gate.dart';

class _KernelValidationResult {
  const _KernelValidationResult({
    required this.isValid,
    required this.reasonCodes,
  });

  final bool isValid;
  final List<String> reasonCodes;
}

class _KernelGovernanceNativeEvaluation {
  const _KernelGovernanceNativeEvaluation({
    required this.wouldAllow,
    required this.servingAllowed,
    required this.shadowBypassApplied,
    required this.reasonCodes,
    required this.policyVersion,
  });

  final bool wouldAllow;
  final bool servingAllowed;
  final bool shadowBypassApplied;
  final List<String> reasonCodes;
  final String policyVersion;
}
