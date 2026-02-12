import 'dart:async';

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/services/business/business_place_knot_service.dart';
import 'package:avrai/core/services/places/place_claim_service.dart';
import 'package:avrai/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Page for a business to claim a place by Google Place ID.
///
/// Flow: enter place ID (or search later) → optional verification method → Claim.
/// On success, returns to dashboard; claimed place appears in "Claimed places".
class ClaimPlacePage extends StatefulWidget {
  const ClaimPlacePage({super.key, required this.businessId});

  final String businessId;

  @override
  State<ClaimPlacePage> createState() => _ClaimPlacePageState();
}

class _ClaimPlacePageState extends State<ClaimPlacePage> {
  final _placeIdController = TextEditingController();
  final _searchController = TextEditingController();
  String? _verificationMethod;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _successMessage;
  List<Spot> _searchResults = [];
  Timer? _searchDebounce;

  PlaceClaimService get _placeClaimService =>
      GetIt.instance<PlaceClaimService>();

  HybridSearchUseCase? get _searchUseCase =>
      GetIt.instance.isRegistered<HybridSearchUseCase>()
          ? GetIt.instance<HybridSearchUseCase>()
          : null;

  @override
  void dispose() {
    _placeIdController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final useCase = _searchUseCase;
    if (useCase == null) return;
    setState(() => _isSearching = true);
    try {
      final result = await useCase.searchSpots(
        query: query,
        maxResults: 20,
        includeExternal: true,
      );
      if (!mounted) return;
      // Only include spots with googlePlaceId (required for claiming)
      final withPlaceId = result.spots
          .where((s) => s.googlePlaceId != null && s.googlePlaceId!.isNotEmpty)
          .toList();
      setState(() {
        _searchResults = withPlaceId;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectPlace(Spot spot) {
    if (spot.googlePlaceId != null) {
      _placeIdController.text = spot.googlePlaceId!;
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
    }
  }

  Future<void> _claim() async {
    final googlePlaceId = _placeIdController.text.trim();
    if (googlePlaceId.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a Google Place ID';
        _successMessage = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _placeClaimService.claim(
        businessId: widget.businessId,
        googlePlaceId: googlePlaceId,
        verificationMethod: _verificationMethod,
      );
      // Seed device-first knot for claimed place (optional)
      if (GetIt.instance.isRegistered<BusinessPlaceKnotService>()) {
        await GetIt.instance<BusinessPlaceKnotService>()
            .seedKnotForClaimedPlace(
          widget.businessId,
          googlePlaceId,
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage =
            'Place claimed successfully. This place\'s compatibility profile is now active.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Claim a place',
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Link a place to your business so it appears under "Events at your places" when events are held there.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (_searchUseCase != null) ...[
              Text(
                'Search by name or address',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blue Bottle Coffee, 123 Main St',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, i) {
                        final spot = _searchResults[i];
                        return ListTile(
                          title: Text(
                            spot.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: spot.address != null
                              ? Text(
                                  spot.address!,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                )
                              : null,
                          onTap: () => _selectPlace(spot),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Or enter Google Place ID manually',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _placeIdController,
              decoration: const InputDecoration(
                labelText: 'Google Place ID',
                hintText: 'e.g. ChIJ...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _verificationMethod,
              decoration: const InputDecoration(
                labelText: 'Verification method (optional)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(
                  value: 'email_pin',
                  child: Text('Email / PIN'),
                ),
                DropdownMenuItem(
                  value: 'google_business_profile',
                  child: Text('Google Business Profile'),
                ),
              ],
              onChanged: (v) => setState(() => _verificationMethod = v),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _successMessage!,
                style: const TextStyle(color: AppColors.success),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _claim,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Claim place'),
            ),
          ],
        ),
      ),
    );
  }
}
