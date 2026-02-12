/// Stripe Configuration
/// 
/// Manages Stripe API keys and configuration for payment processing.
/// 
/// **Usage:**
/// ```dart
/// final config = StripeConfig();
/// await Stripe.publishableKey = config.publishableKey;
/// ```
/// 
/// **Environment Variables:**
/// - Use environment variables for production keys
/// - Store test keys in development config
class StripeConfig {
  /// Stripe publishable key
  /// 
  /// In production, this should come from environment variables.
  /// For development, use Stripe test keys.
  final String publishableKey;
  
  /// Stripe secret key (for backend operations)
  /// 
  /// **WARNING:** Never expose this in client-side code.
  /// This should only be used in secure backend services.
  final String? secretKey;
  
  /// Merchant identifier (for Apple Pay)
  final String? merchantIdentifier;
  
  /// Whether to use test mode
  final bool isTestMode;
  
  const StripeConfig({
    required this.publishableKey,
    this.secretKey,
    this.merchantIdentifier,
    this.isTestMode = true,
  });
  
  /// Create Stripe config from environment variables
  /// 
  /// In production, use:
  /// ```dart
  /// StripeConfig.fromEnvironment(
  ///   publishableKey: Platform.environment['STRIPE_PUBLISHABLE_KEY'] ?? '',
  ///   secretKey: Platform.environment['STRIPE_SECRET_KEY'],
  /// )
  /// ```
  factory StripeConfig.fromEnvironment({
    required String publishableKey,
    String? secretKey,
    String? merchantIdentifier,
    bool isTestMode = true,
  }) {
    return StripeConfig(
      publishableKey: publishableKey,
      secretKey: secretKey,
      merchantIdentifier: merchantIdentifier,
      isTestMode: isTestMode,
    );
  }
  
  /// Default test configuration
  /// 
  /// **Note:** Replace with actual test keys from Stripe dashboard
  factory StripeConfig.test() {
    return const StripeConfig(
      publishableKey: 'pk_test_your_test_key_here',
      isTestMode: true,
    );
  }
  
  /// Production configuration
  /// 
  /// **Note:** Use environment variables in production
  factory StripeConfig.production({
    required String publishableKey,
    String? merchantIdentifier,
  }) {
    return StripeConfig(
      publishableKey: publishableKey,
      merchantIdentifier: merchantIdentifier,
      isTestMode: false,
    );
  }
  
  /// Validate configuration
  bool get isValid => publishableKey.isNotEmpty;
  
  @override
  String toString() => 'StripeConfig(isTestMode: $isTestMode, isValid: $isValid)';
}

