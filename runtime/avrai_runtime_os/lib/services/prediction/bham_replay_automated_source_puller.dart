import 'package:avrai_core/avra_core.dart';

abstract class BhamReplayAutomatedSourcePuller {
  const BhamReplayAutomatedSourcePuller();

  String get pullerId;

  bool supports(ReplaySourcePullPlan plan);

  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  });
}
