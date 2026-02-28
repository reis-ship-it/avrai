// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/services/admin/admin_runtime_governance_service.dart';

export 'admin_runtime_governance_service.dart';

/// Legacy compatibility wrapper.
///
/// Use [AdminRuntimeGovernanceService] for all new development.
class AdminGodModeService extends AdminRuntimeGovernanceService {
  AdminGodModeService({
    required super.authService,
    required super.communicationService,
    required super.businessService,
    super.clubService,
    super.communityService,
    required super.predictiveAnalytics,
    required super.connectionMonitor,
    super.chatAnalyzer,
    super.supabaseService,
    super.expertiseService,
    super.networkAnalytics,
    super.federatedLearningSystem,
  });
}
