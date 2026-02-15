import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/business/brand_account.dart';
import 'package:avrai/core/models/sponsorship/sponsorship.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/brand/brand_stats_card.dart';
import 'package:avrai/presentation/widgets/brand/sponsorship_card.dart';
import 'package:avrai/presentation/pages/brand/brand_analytics_page.dart';
import 'package:avrai/presentation/pages/brand/brand_discovery_page.dart';
import 'package:avrai/presentation/pages/brand/sponsorship_management_page.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Brand Dashboard Page
///
/// Overview dashboard for brand accounts.
/// Shows brand info, active sponsorships, and analytics summary.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class BrandDashboardPage extends StatefulWidget {
  const BrandDashboardPage({super.key});

  @override
  State<BrandDashboardPage> createState() => _BrandDashboardPageState();
}

class _BrandDashboardPageState extends State<BrandDashboardPage> {
  // TODO: Get services when available (Agent 1, Week 11)
  // final _brandAccountService = GetIt.instance<BrandAccountService>();
  // final _brandAnalyticsService = GetIt.instance<BrandAnalyticsService>();
  // final _sponsorshipService = GetIt.instance<SponsorshipService>();
  // ignore: unused_field
  final _eventService = GetIt.instance<ExpertiseEventService>();

  BrandAccount? _brandAccount;
  List<Sponsorship> _activeSponsorships = [];
  bool _isLoading = true;

  // Mock analytics data
  final double _totalInvestment = 3200.0;
  final double _totalReturns = 1847.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    // ignore: unused_local_variable - Reserved for future user-specific dashboard data
    final userId = authState.user.id;

    setState(() => _isLoading = true);

    try {
      // TODO: Load brand account when service available
      // final brand = await _brandAccountService.getBrandAccountByUserId(userId);
      // if (brand == null) {
      //   setState(() => _isLoading = false);
      //   return;
      // }
      //
      // // Load analytics
      // final analytics = await _brandAnalyticsService.getBrandAnalytics(brand.id);
      //
      // // Load active sponsorships
      // final sponsorships = await _sponsorshipService.getSponsorshipsForBrand(brand.id);
      // final active = sponsorships.where((s) =>
      //   s.status == SponsorshipStatus.active ||
      //   s.status == SponsorshipStatus.locked ||
      //   s.status == SponsorshipStatus.approved
      // ).toList();

      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _brandAccount = BrandAccount(
          id: 'brand-mock-1',
          name: 'Premium Olive Oil Co.',
          brandType: 'Food & Beverage',
          categories: const ['Gourmet', 'Premium Products'],
          contactEmail: 'partnerships@premiumoil.com',
          verificationStatus: BrandVerificationStatus.verified,
          activeSponsorshipCount: 3,
          totalSponsorshipCount: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now(),
        );

        _activeSponsorships = [
          Sponsorship(
            id: 'sponsor-1',
            eventId: 'event-1',
            brandId: 'brand-mock-1',
            type: SponsorshipType.hybrid,
            contributionAmount: 1000.0,
            productValue: 500.0,
            status: SponsorshipStatus.active,
            revenueSharePercentage: 15.0,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now(),
          ),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        FeedbackPresenter.showSnack(
          context,
          message: 'Error loading dashboard: $e',
          kind: FeedbackKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AdaptivePlatformPageScaffold(
        title: 'Brand Dashboard',
        backgroundColor: AppColors.background,
        appBarBackgroundColor: AppTheme.primaryColor,
        appBarForegroundColor: AppColors.white,
        appBarElevation: 0,
        constrainBody: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_brandAccount == null) {
      return _buildNoBrandAccountState();
    }

    return AdaptivePlatformPageScaffold(
      title: 'Brand Dashboard',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            _buildBrandHeader(),

            SizedBox(height: context.spacing.lg),

            // Quick Stats
            _buildQuickStats(),

            SizedBox(height: context.spacing.lg),

            // Active Sponsorships
            _buildActiveSponsorshipsSection(),

            SizedBox(height: context.spacing.lg),

            // Analytics Section
            _buildAnalyticsSection(),

            SizedBox(height: context.spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      color: AppColors.surface,
      child: Row(
        children: [
          if (_brandAccount!.logoUrl != null)
            CircleAvatar(
              radius: context.spacing.xl,
              backgroundImage: NetworkImage(_brandAccount!.logoUrl!),
            )
          else
            CircleAvatar(
              radius: context.spacing.xl,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(
                Icons.business,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _brandAccount!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: context.spacing.xxs),
                Row(
                  children: [
                    Text(
                      _brandAccount!.brandType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (_brandAccount!.categories.isNotEmpty) ...[
                      Text(' • ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                      Text(
                        _brandAccount!.categories.join(', '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.spacing.xxs),
                if (_brandAccount!.isVerified)
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.electricGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified Brand',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.pending,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: context.spacing.xxs),
                      Text(
                        'Verification: ${_brandAccount!.verificationStatus.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      child: Row(
        children: [
          Expanded(
            child: BrandStatsCard(
              label: 'Total Investment',
              value: '\$${_totalInvestment.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: BrandStatsCard(
              label: 'Total Returns',
              value: '\$${_totalReturns.toStringAsFixed(0)}',
              icon: Icons.trending_up,
              color: AppColors.electricGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSponsorshipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Sponsorships',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (_activeSponsorships.isNotEmpty)
                TextButton(
                  onPressed: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const SponsorshipManagementPage(),
                    );
                  },
                  child: Text('View All'),
                ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.sm),
        if (_activeSponsorships.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.spacing.xxl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    'No active sponsorships',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    'Start sponsoring events to see them here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacing.md),
                  ElevatedButton(
                    onPressed: () {
                      AppNavigator.pushBuilder(
                        context,
                        builder: (context) => const BrandDiscoveryPage(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text('Discover Events'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._activeSponsorships.take(3).map((sponsorship) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.lg,
                  vertical: context.spacing.xs,
                ),
                child: SponsorshipCard(
                  sponsorship: sponsorship,
                  onTap: () {
                    AppNavigator.pushBuilder(
                      context,
                      builder: (context) => const SponsorshipManagementPage(),
                    );
                  },
                ),
              )),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    final roiPercentage =
        _totalInvestment > 0 ? ((_totalReturns / _totalInvestment) * 100) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      child: PortalSurface(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Performance Overview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: context.spacing.md),

            // Investment Breakdown
            _buildAnalyticsRow(
                'Total Investment', '\$${_totalInvestment.toStringAsFixed(0)}'),
            _buildAnalyticsRow(
                'Cash', '\$${(_totalInvestment * 0.625).toStringAsFixed(0)}',
                indent: true),
            _buildAnalyticsRow('Products',
                '\$${(_totalInvestment * 0.375).toStringAsFixed(0)}',
                indent: true),

            SizedBox(height: context.spacing.sm),
            const Divider(color: AppColors.grey300),
            SizedBox(height: context.spacing.sm),

            // Returns
            _buildAnalyticsRow(
                'Total Returns', '\$${_totalReturns.toStringAsFixed(0)}',
                isTotal: true),
            _buildAnalyticsRow(
                'Direct Revenue', '\$${_totalReturns.toStringAsFixed(0)}',
                indent: true),
            _buildAnalyticsRow(
                'Brand Value', '\$${(12400.0).toStringAsFixed(0)}',
                indent: true),

            SizedBox(height: context.spacing.sm),
            const Divider(color: AppColors.grey300),
            SizedBox(height: context.spacing.sm),

            // ROI
            _buildAnalyticsRow(
              'ROI',
              '${roiPercentage.toStringAsFixed(0)}%',
              isTotal: true,
              color:
                  roiPercentage > 0 ? AppColors.electricGreen : AppColors.error,
            ),

            SizedBox(height: context.spacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  AppNavigator.pushBuilder(
                    context,
                    builder: (context) => const BrandAnalyticsPage(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.grey300),
                ),
                child: Text('View Detailed Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value,
      {bool isTotal = false, bool indent = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(
          left: indent ? kSpaceMd : kSpaceNone, bottom: kSpaceXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    color: AppColors.textPrimary),
          ),
          Text(
            value,
            style: (isTotal
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ??
                        (isTotal
                            ? AppTheme.primaryColor
                            : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBrandAccountState() {
    return AdaptivePlatformPageScaffold(
      title: 'Brand Dashboard',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      appBarElevation: 0,
      constrainBody: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'No Brand Account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              'Create a brand account to start sponsoring events',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.xl),
            ElevatedButton(
              onPressed: () {
                // Navigate to create brand account page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppColors.white,
              ),
              child: Text('Create Brand Account'),
            ),
          ],
        ),
      ),
    );
  }
}
