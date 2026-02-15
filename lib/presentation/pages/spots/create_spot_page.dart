import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/design/design_system.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/widgets/common/success_animation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

class CreateSpotPage extends StatefulWidget {
  const CreateSpotPage({super.key});

  @override
  State<CreateSpotPage> createState() => _CreateSpotPageState();
}

class _CreateSpotPageState extends State<CreateSpotPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'Restaurant';
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;

  final List<String> _categories = [
    'Restaurant',
    'Cafe',
    'Bar',
    'Shop',
    'Park',
    'Museum',
    'Theater',
    'Hotel',
    'Landmark',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled';
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permissions are permanently denied';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Failed to get location: $e';
      });
    }
  }

  void _saveSpot() {
    if (_formKey.currentState!.validate()) {
      if (_latitude == null || _longitude == null) {
        context.showError('Please enable location services to create a spot');
        return;
      }

      final spot = Spot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        latitude: _latitude!,
        longitude: _longitude!,
        rating: 0.0,
        createdBy: 'demo_user_1', // For MVP without auth
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      context.read<SpotsBloc>().add(CreateSpot(spot));

      // Show success animation (it will auto-dismiss)
      SuccessAnimation.show(
        context,
        message: 'Spot created successfully!',
        icon: Icons.check_circle,
        duration: const Duration(milliseconds: 1500),
      );

      // Pop the page after a brief delay to let animation show
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && context.mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return AdaptivePlatformPageScaffold(
      title: 'Create Spot',
      actions: [
        IconButton(
          onPressed: _saveSpot,
          icon: const Icon(Icons.check),
          tooltip: 'Save spot',
        ),
      ],
      constrainBody: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spot Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Spot Name *',
                  hintText: 'Enter the name of the place',
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a spot name';
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.md),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: spacing.md),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about this place...',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: spacing.md),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter the address (optional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: spacing.lg),

              // Location Section
              PortalSurface(
                child: Padding(
                  padding: const EdgeInsets.all(kSpaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Location',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (_latitude != null && _longitude != null)
                            const Icon(Icons.check_circle,
                                color: AppTheme.successColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingLocation)
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Getting your location...'),
                          ],
                        )
                      else if (_locationError != null)
                        Row(
                          children: [
                            const Icon(Icons.error,
                                color: AppTheme.errorColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        )
                      else if (_latitude != null && _longitude != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${_latitude!.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Longitude: ${_longitude!.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh),
                        label: Text('Refresh Location'),
                        // Use global ElevatedButtonTheme
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveSpot,
                // Use global ElevatedButtonTheme; keep padding only
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: kSpaceMd)),
                child: Text(
                  'Create Spot',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
