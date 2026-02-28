part of 'kernel_governance_gate.dart';

class _KernelValidationResult {
  const _KernelValidationResult({
    required this.isValid,
    required this.reasonCodes,
  });

  final bool isValid;
  final List<String> reasonCodes;
}
