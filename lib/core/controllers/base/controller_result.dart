import 'package:equatable/equatable.dart';

/// Base result class for all controller results
/// 
/// All controller workflows return a result that extends this base class.
/// This provides consistent structure for success/error states and metadata.
abstract class ControllerResult extends Equatable {
  /// Whether the operation succeeded
  final bool success;

  /// Error message if operation failed
  final String? error;

  /// Error code for programmatic error handling
  final String? errorCode;

  /// Additional metadata about the operation
  final Map<String, dynamic>? metadata;

  const ControllerResult({
    required this.success,
    this.error,
    this.errorCode,
    this.metadata,
  });

  /// Check if result has an error
  bool get hasError => !success && error != null;

  /// Check if result is successful
  bool get isSuccess => success && error == null;

  @override
  List<Object?> get props => [success, error, errorCode, metadata];
}

/// Validation result for input validation
/// 
/// Used by controllers to return validation results before
/// executing workflows. Contains field-level errors and
/// overall validation status.
class ValidationResult extends Equatable {
  /// Whether validation passed
  final bool isValid;

  /// Field-level validation errors
  /// Key: field name, Value: error message
  final Map<String, String> fieldErrors;

  /// General validation errors (not field-specific)
  final List<String> generalErrors;

  /// Validation warnings (non-blocking)
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
    this.generalErrors = const [],
    this.warnings = const [],
  });

  /// Create a valid validation result
  factory ValidationResult.valid({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Create an invalid validation result
  factory ValidationResult.invalid({
    Map<String, String>? fieldErrors,
    List<String>? generalErrors,
  }) {
    return ValidationResult(
      isValid: false,
      fieldErrors: fieldErrors ?? const {},
      generalErrors: generalErrors ?? const [],
    );
  }

  /// Get all errors (field + general) as a single list
  List<String> get allErrors {
    return [
      ...fieldErrors.values,
      ...generalErrors,
    ];
  }

  /// Get first error message (useful for simple error display)
  String? get firstError {
    if (fieldErrors.isNotEmpty) {
      return fieldErrors.values.first;
    }
    if (generalErrors.isNotEmpty) {
      return generalErrors.first;
    }
    return null;
  }

  @override
  List<Object?> get props => [isValid, fieldErrors, generalErrors, warnings];
}

