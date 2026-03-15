import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

abstract class BhamReplaySourceAdapter {
  const BhamReplaySourceAdapter();

  String get adapterId;

  bool supports(ReplayIngestionSourcePlan plan);

  Future<List<ReplaySourceRecord>> adapt({
    required ReplayIngestionSourcePlan plan,
    required List<Map<String, dynamic>> rawRecords,
    required TemporalKernel temporalKernel,
  });
}
