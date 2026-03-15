import 'package:reality_engine/reality_engine.dart';

class CanonicalVibeRuntimePolicy {
  const CanonicalVibeRuntimePolicy._();

  static bool get isCanonicalAuthorityActive =>
      VibeKernelRuntimeBindings.persistenceBridge != null;
}
