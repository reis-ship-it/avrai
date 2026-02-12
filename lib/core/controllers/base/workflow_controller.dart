import 'package:avrai/core/controllers/base/controller_result.dart';

/// Base interface for all workflow controllers
/// 
/// Controllers orchestrate complex multi-step workflows that coordinate
/// multiple services. They provide a clean abstraction for business logic
/// that is too complex for simple BLoC operations.
/// 
/// **When to Use Controllers:**
/// - ✅ Multi-step workflows (3+ steps)
/// - ✅ Multiple services coordinated
/// - ✅ Complex validation logic
/// - ✅ Error handling across services
/// - ✅ Rollback/compensation needed
/// 
/// **When NOT to Use Controllers:**
/// - ❌ Simple CRUD operations (use BLoC directly)
/// - ❌ Single service calls (use BLoC directly)
/// - ❌ Simple state management (use BLoC directly)
/// 
/// **Architecture Pattern:**
/// ```
/// UI → BLoC → Controller → Multiple Services/Use Cases → Repository
/// ```
abstract class WorkflowController<TInput, TResult extends ControllerResult> {
  /// Execute the workflow
  /// 
  /// Takes input data and orchestrates the complete workflow,
  /// returning a unified result that includes success/error state
  /// and any relevant data or error information.
  Future<TResult> execute(TInput input);

  /// Validate input before execution
  /// 
  /// Performs validation checks on input data before executing
  /// the workflow. Returns validation result with any errors found.
  ValidationResult validate(TInput input);

  /// Rollback changes if workflow fails (optional)
  /// 
  /// If a workflow fails partway through, this method can be
  /// called to rollback any changes that were made. Not all
  /// controllers need to implement this - only those that make
  /// state changes that need to be undone.
  Future<void> rollback(TResult result) async {
    // Default implementation: no rollback needed
    // Controllers can override if rollback is required
  }
}

