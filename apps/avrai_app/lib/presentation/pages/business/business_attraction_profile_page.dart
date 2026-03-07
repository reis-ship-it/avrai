import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

/// Page for businesses to set explicit "who we want to attract" 12D profile.
///
/// When set, this overrides inferred dimensions from patron preferences.
/// Uses sliders for each of the 12 avrai dimensions.
class BusinessAttractionProfilePage extends StatefulWidget {
  const BusinessAttractionProfilePage({
    super.key,
    required this.business,
    required this.onSaved,
  });

  final BusinessAccount business;
  final VoidCallback onSaved;

  @override
  State<BusinessAttractionProfilePage> createState() =>
      _BusinessAttractionProfilePageState();
}

class _BusinessAttractionProfilePageState
    extends State<BusinessAttractionProfilePage> {
  late Map<String, double> _dimensions;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  BusinessAccountService get _businessAccountService =>
      GetIt.instance<BusinessAccountService>();

  @override
  void initState() {
    super.initState();
    _dimensions = Map<String, double>.from(
      widget.business.attractionDimensions ??
          {
            for (final d in VibeConstants.coreDimensions)
              d: VibeConstants.defaultDimensionValue,
          },
    );
    for (final d in VibeConstants.coreDimensions) {
      _dimensions.putIfAbsent(d, () => VibeConstants.defaultDimensionValue);
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _businessAccountService.updateBusinessAccount(
        widget.business,
        attractionDimensions: Map<String, double>.from(_dimensions),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = 'Attraction profile saved.';
      });
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _label(String key) {
    return (VibeConstants.dimensionDescriptions[key] ?? key)
        .replaceAll('_', ' ')
        .split(' ')
        .map((s) =>
            s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Attraction profile',
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set who you want to attract. Higher values on each dimension mean you want to attract people who seek that quality.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ...VibeConstants.coreDimensions.map((d) {
              final v = _dimensions[d] ?? 0.5;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _label(d),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        Text(
                          (v * 100).round().toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    Slider(
                      value: v,
                      onChanged: (nv) => setState(() => _dimensions[d] = nv),
                      min: 0,
                      max: 1,
                      divisions: 20,
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              );
            }),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _successMessage!,
                style: const TextStyle(color: AppColors.success),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save attraction profile'),
            ),
          ],
        ),
      ),
    );
  }
}
