import 'dart:async';

import 'package:avrai_core/avra_core.dart';

abstract class VibeKernelPersistenceBridge {
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  });
}

class VibeKernelRuntimeBindings {
  static VibeKernelPersistenceBridge? persistenceBridge;

  static final StreamController<TrajectoryMutationRecord>
      _mutationReceiptController =
      StreamController<TrajectoryMutationRecord>.broadcast();

  static Stream<TrajectoryMutationRecord> get mutationReceipts =>
      _mutationReceiptController.stream;

  static void publishMutationReceipt(TrajectoryMutationRecord record) {
    if (!_mutationReceiptController.isClosed) {
      _mutationReceiptController.add(record);
    }
  }
}
