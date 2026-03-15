import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';

class ForecastResolutionService {
  const ForecastResolutionService({
    required ForecastSkillLedger skillLedger,
  }) : _skillLedger = skillLedger;

  final ForecastSkillLedger _skillLedger;

  Future<void> recordResolution(ForecastResolutionRecord resolution) {
    return _skillLedger.recordResolution(resolution);
  }
}
