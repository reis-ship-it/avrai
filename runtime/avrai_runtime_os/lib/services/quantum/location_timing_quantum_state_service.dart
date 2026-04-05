/// Compatibility export for quantum services.
///
/// The quantum services were migrated into the `avrai_quantum` package.
/// Some legacy code/tests still import via:
/// `package:avrai_runtime_os/services/quantum/...`
library;

export 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
