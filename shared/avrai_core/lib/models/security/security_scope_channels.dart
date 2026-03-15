import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class SecurityScopeChannels {
  const SecurityScopeChannels({
    required this.observationScope,
    required this.interventionScope,
    required this.promotionScope,
    required this.propagationScope,
  });

  final TruthScopeDescriptor observationScope;
  final TruthScopeDescriptor interventionScope;
  final TruthScopeDescriptor promotionScope;
  final TruthScopeDescriptor propagationScope;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'observationScope': observationScope.toJson(),
      'interventionScope': interventionScope.toJson(),
      'promotionScope': promotionScope.toJson(),
      'propagationScope': propagationScope.toJson(),
    };
  }

  factory SecurityScopeChannels.fromJson(Map<String, dynamic> json) {
    return SecurityScopeChannels(
      observationScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['observationScope'] as Map? ?? const {},
        ),
      ),
      interventionScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['interventionScope'] as Map? ?? const {},
        ),
      ),
      promotionScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['promotionScope'] as Map? ?? const {},
        ),
      ),
      propagationScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['propagationScope'] as Map? ?? const {},
        ),
      ),
    );
  }
}
