import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';

/// Preferred runtime name for the legacy text-generation router.
///
/// The kernel stack owns interpretation, boundary, and expression semantics.
/// This service remains the low-level model/runtime adapter while remaining
/// legacy `LLMService` consumers are migrated in controlled slices.
class LanguageRuntimeService extends LLMService {
  LanguageRuntimeService(
    super.client, {
    super.connectivity,
    super.cloudBackend,
    super.localBackend,
    super.bertSquadBackend,
    super.shouldUseLocalOverride,
    super.isOnlineOverride,
  });
}

typedef LanguageTurnMessage = ChatMessage;
typedef LanguageTurnRole = ChatRole;
typedef LanguageRuntimeContext = LLMContext;
typedef LanguageRoutingPolicy = LLMDispatchPolicy;
typedef LanguageBackend = LlmBackend;
typedef LanguageRuntimeOfflineException = OfflineException;
typedef LanguageRuntimeDataCenterFailureException = DataCenterFailureException;
