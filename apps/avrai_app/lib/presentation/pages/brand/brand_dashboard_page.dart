import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai_core/models/business/brand_account.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/brand/brand_stats_card.dart';
import 'package:avrai/presentation/widgets/brand/sponsorship_card.dart';
import 'package:avrai/presentation/pages/brand/brand_analytics_page.dart';
import 'package:avrai/presentation/pages/brand/brand_discovery_page.dart';
import 'package:avrai/presentation/pages/brand/sponsorship_management_page.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';

/// Brand Dashboard Page
///
/// Overview dashboard for brand accounts.
/// Shows brand info, active sponsorships, and analytics summary.
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppFlowScaffold(
        title: 'Brand Dashboard',
        backgroundColor: AppColors.background,
        appBarBackgroundColor: AppColors.surface,
        appBarForegroundColor: AppColors.textPrimary,
        appBarElevation: 0,
        constrainBody: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_brandAccount == null) {
      return _buildNoBrandAccountState();
    }

    return AppFlowScaffold(
      title: 'Brand Dashboard',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppColors.surface,
      appBarForegroundColor: AppColors.textPrimary,
      appBarElevation: 0,
      constrainBody: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            _buildBrandHeader(),

            const SizedBox(height: 20),

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 20),

            // Active Sponsorships
            _buildActiveSponsorshipsSection(),

            const SizedBox(height: 20),

            // Analytics Section
            _buildAnalyticsSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppSurface(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (_brandAccount!.logoUrl != null)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(_brandAccount!.logoUrl!),
              )
            else
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceMuted,
                child: const Icon(
                  Icons.business,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: _brandAccount!.name,
                    subtitle: _brandAccount!.brandType,
                    showDivider: false,
                  ),
                  Row(
                    children: [
                      if (_brandAccount!.categories.isNotEmpty) ...[
                        Text(
                          _brandAccount!.categories.join(', '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_brandAccount!.isVerified)
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Brand',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
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
                        const SizedBox(width: 4),
                        Text(
                          'Verification: ${_brandAccount!.verificationStatus.displayName}',
                          style: const TextStyle(
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          const SizedBox(width: 12),
          Expanded(
            child: BrandStatsCard(
              label: 'Total Returns',
              value: '\$${_totalReturns.toStringAsFixed(0)}',
              icon: Icons.trending_up,
              color: AppColors.success,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Sponsorships',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_activeSponsorships.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SponsorshipManagementPage(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_activeSponsorships.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No active sponsorships',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start sponsoring events to see them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrandDiscoveryPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceMuted,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Discover Events'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._activeSponsorships.take(3).map((sponsorship) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SponsorshipCard(
                  sponsorship: sponsorship,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SponsorshipManagementPage(),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Investment Breakdown
            _buildAnalyticsRow(
                'Total Investment', '\$${_totalInvestment.toStringAsFixed(0)}'),
            _buildAnalyticsRow(
                'Cash', '\$${(_totalInvestment * 0.625).toStringAsFixed(0)}',
                indent: true),
            _buildAnalyticsRow('Products',
                '\$${(_totalInvestment * 0.375).toStringAsFixed(0)}',
                indent: true),

            const SizedBox(height: 12),
            const Divider(color: AppColors.grey300),
            const SizedBox(height: 12),

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

            const SizedBox(height: 12),
            const Divider(color: AppColors.grey300),
            const SizedBox(height: 12),

            // ROI
            _buildAnalyticsRow(
              'ROI',
              '${roiPercentage.toStringAsFixed(0)}%',
              isTotal: true,
              color: roiPercentage > 0 ? AppColors.success : AppColors.error,
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrandAnalyticsPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.grey300),
                ),
                child: const Text('View Detailed Analytics'),
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
      padding: EdgeInsets.only(left: indent ? 16 : 0, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color ??
                  (isTotal ? AppColors.textPrimary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBrandAccountState() {
    return AppFlowScaffold(
      title: 'Brand Dashboard',
      backgroundColor: AppColors.background,
      appBarBackgroundColor: AppColors.surface,
      appBarForegroundColor: AppColors.textPrimary,
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
            const SizedBox(height: 16),
            const Text(
              'No Brand Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a brand account to start sponsoring events',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to create brand account page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceMuted,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Create Brand Account'),
            ),
          ],
        ),
      ),
    );
  }
}
