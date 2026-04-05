import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/payment/stripe_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_event_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_runtime_os/services/payment/payout_service.dart';
import 'package:avrai_runtime_os/services/payment/refund_service.dart';
import 'package:avrai_runtime_os/services/events/cancellation_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/business_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_runtime_os/services/payment/product_sales_service.dart';
import 'package:avrai_runtime_os/services/business/brand_analytics_service.dart';
import 'package:avrai_runtime_os/services/business/brand_discovery_service.dart';
import 'package:avrai_runtime_os/services/payment/sales_tax_service.dart';
import 'package:avrai_runtime_os/config/stripe_config.dart';
import 'package:avrai_runtime_os/controllers/payment_processing_controller.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

/// Payment Services Registration Module
///
/// Registers all payment, revenue, and business-related services.
/// This includes:
/// - Payment processing (Stripe, PaymentService)
/// - Revenue sharing (RevenueSplitService, PayoutService)
/// - Business services (Partnership, Sponsorship, Business)
/// - Product tracking and brand analytics
Future<void> registerPaymentServices(GetIt sl) async {
  const logger =
      AppLogger(defaultTag: 'DI-Payment', minimumLevel: LogLevel.debug);
  logger.debug('💳 [DI-Payment] Registering payment services...');

  // Payment Processing Services - Agent 1: Payment Processing & Revenue
  // Register StripeConfig first (using test config for now)
  sl.registerLazySingleton<StripeConfig>(() => StripeConfig.test());

  // Register StripeService with StripeConfig
  sl.registerLazySingleton<StripeService>(
      () => StripeService(sl<StripeConfig>()));

  // Note: ExpertiseEventService is registered as a shared service in main container

  // Register PaymentService with StripeService and ExpertiseEventService
  sl.registerLazySingleton<PaymentService>(() => PaymentService(
        sl<StripeService>(),
        sl<ExpertiseEventService>(),
      ));

  // Register PaymentEventService (bridge between payment and event services)
  sl.registerLazySingleton<PaymentEventService>(() => PaymentEventService(
        sl<PaymentService>(),
        sl<ExpertiseEventService>(),
      ));

  // Register SalesTaxService (for tax calculation on events)
  sl.registerLazySingleton<SalesTaxService>(() => SalesTaxService(
        eventService: sl<ExpertiseEventService>(),
        paymentService: sl<PaymentService>(),
      ));

  // Note: BusinessService is registered as a shared service in main container

  // Truthful vibe compatibility service (quantum + knot).
  //
  // Registered here because Payment services (Partnership/Sponsorship) depend on it.
  // The instance is created lazily; dependencies (PersonalityLearning, knot services)
  // will be available after full container initialization.
  sl.registerLazySingleton<VibeCompatibilityService>(
    () => QuantumKnotVibeCompatibilityService(
      personalityLearning: sl<PersonalityLearning>(),
      personalityKnotService: sl<PersonalityKnotService>(),
      entityKnotService: sl<EntityKnotService>(),
    ),
  );

  // Register PartnershipService (required by RevenueSplitService)
  sl.registerLazySingleton<PartnershipService>(() => PartnershipService(
        eventService: sl<ExpertiseEventService>(),
        businessService: sl<BusinessService>(),
        vibeCompatibilityService: sl<VibeCompatibilityService>(),
        ledgerRecorder: sl<LedgerRecorderServiceV0>(),
      ));

  // Register SponsorshipService (required by ProductTrackingService and BrandAnalyticsService)
  sl.registerLazySingleton(() => SponsorshipService(
        eventService: sl<ExpertiseEventService>(),
        partnershipService: sl<PartnershipService>(),
        vibeCompatibilityService: sl<VibeCompatibilityService>(),
      ));

  // Register RevenueSplitService (required by PayoutService)
  sl.registerLazySingleton<RevenueSplitService>(() => RevenueSplitService(
        partnershipService: sl<PartnershipService>(),
        sponsorshipService: sl<SponsorshipService>(),
      ));

  // Register PayoutService
  sl.registerLazySingleton<PayoutService>(() => PayoutService(
        revenueSplitService: sl<RevenueSplitService>(),
      ));

  // Register RefundService (required by CancellationService)
  sl.registerLazySingleton<RefundService>(() => RefundService(
        paymentService: sl<PaymentService>(),
        stripeService: sl<StripeService>(),
      ));

  // Register CancellationService (required by EventCancellationController)
  sl.registerLazySingleton<CancellationService>(() => CancellationService(
        paymentService: sl<PaymentService>(),
        eventService: sl<ExpertiseEventService>(),
        refundService: sl<RefundService>(),
      ));

  // Product Tracking & Sales Services (required by BrandAnalyticsService)
  sl.registerLazySingleton(() => ProductTrackingService(
        sponsorshipService: sl<SponsorshipService>(),
        revenueSplitService: sl<RevenueSplitService>(),
      ));

  sl.registerLazySingleton(() => ProductSalesService(
        productTrackingService: sl<ProductTrackingService>(),
        revenueSplitService: sl<RevenueSplitService>(),
        paymentService: sl<PaymentService>(),
      ));

  // Brand Analytics Service
  sl.registerLazySingleton(() => BrandAnalyticsService(
        sponsorshipService: sl<SponsorshipService>(),
        productTrackingService: sl<ProductTrackingService>(),
        productSalesService: sl<ProductSalesService>(),
        revenueSplitService: sl<RevenueSplitService>(),
      ));

  // Brand Discovery Service
  sl.registerLazySingleton(() => BrandDiscoveryService(
        eventService: sl<ExpertiseEventService>(),
        sponsorshipService: sl<SponsorshipService>(),
      ));

  // Payment Processing Controller (Phase 8.11)
  if (!sl.isRegistered<PaymentProcessingController>()) {
    sl.registerLazySingleton<PaymentProcessingController>(
        () => PaymentProcessingController(
              salesTaxService: sl<SalesTaxService>(),
              paymentEventService: sl<PaymentEventService>(),
            ));
  }

  logger.debug('✅ [DI-Payment] Payment services registered');
}
