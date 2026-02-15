import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/business_expert_preferences.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/business/business_expert_preferences_widget.dart';
import 'package:avrai/presentation/widgets/business/business_patron_preferences_widget.dart';
import 'package:avrai/presentation/widgets/business/business_verification_widget.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Business Account Form Widget
/// Allows businesses to create accounts
class BusinessAccountFormWidget extends StatefulWidget {
  final UnifiedUser creator;
  final Function(BusinessAccount)? onAccountCreated;

  const BusinessAccountFormWidget({
    super.key,
    required this.creator,
    this.onAccountCreated,
  });

  @override
  State<BusinessAccountFormWidget> createState() =>
      _BusinessAccountFormWidgetState();
}

class _BusinessAccountFormWidgetState extends State<BusinessAccountFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _service = BusinessAccountService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedBusinessType = 'Restaurant';
  final List<String> _selectedCategories = [];
  final List<String> _selectedExpertise = [];
  final List<String> _selectedCommunities = [];

  String? _preferredLocation;
  int? _minExpertLevel;
  BusinessExpertPreferences? _expertPreferences;
  BusinessPatronPreferences? _patronPreferences;

  bool _isLoading = false;
  bool _showExpertPreferences = false;
  bool _showPatronPreferences = false;

  static const List<String> _businessTypes = [
    'Restaurant',
    'Retail',
    'Service',
    'Cafe',
    'Bar',
    'Entertainment',
    'Other',
  ];

  static const List<String> _commonCategories = [
    'Coffee',
    'Food',
    'Dining',
    'Beverages',
    'Retail',
    'Service',
    'Entertainment',
    'Nightlife',
  ];

  static const List<String> _expertiseCategories = [
    'Coffee',
    'Restaurants',
    'Bars',
    'Pastry',
    'Wine',
    'Cocktails',
    'Food',
    'Dining',
    'Retail',
    'Shopping',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final account = await _service.createBusinessAccount(
        creator: widget.creator,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        businessType: _selectedBusinessType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        categories: _selectedCategories,
        requiredExpertise: _selectedExpertise,
        preferredCommunities: _selectedCommunities,
        expertPreferences: _expertPreferences,
        patronPreferences: _patronPreferences,
        preferredLocation: _preferredLocation,
        minExpertLevel: _minExpertLevel,
      );

      if (mounted) {
        context.showSuccess('Business account created successfully!');

        widget.onAccountCreated?.call(account);

        // Reset form
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _descriptionController.clear();
        _websiteController.clear();
        _locationController.clear();
        _phoneController.clear();
        setState(() {
          _selectedCategories.clear();
          _selectedExpertise.clear();
          _selectedCommunities.clear();
          _preferredLocation = null;
          _minExpertLevel = null;
          _expertPreferences = null;
          _patronPreferences = null;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showError('Error creating account: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceMd),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Business Account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with experts based on community, expertise, and AI suggestions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // Business Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Business Type
            DropdownButtonFormField<String>(
              initialValue: _selectedBusinessType,
              decoration: const InputDecoration(
                labelText: 'Business Type *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _businessTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusinessType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Categories
            _buildSectionTitle('Business Categories'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Required Expertise
            _buildSectionTitle('Required Expertise'),
            Text(
              'Select expertise categories you need from experts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _expertiseCategories.map((category) {
                final isSelected = _selectedExpertise.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedExpertise.add(category);
                      } else {
                        _selectedExpertise.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Preferred Location for Experts
            TextFormField(
              onChanged: (value) {
                setState(() {
                  _preferredLocation =
                      value.trim().isEmpty ? null : value.trim();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Preferred Expert Location (optional)',
                hintText: 'e.g., Brooklyn, NYC',
                prefixIcon: Icon(Icons.person_pin_circle),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Expert Preferences Section
            Card(
              child: ExpansionTile(
                title: Text(
                  'Advanced Expert Matching Preferences',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _expertPreferences == null
                      ? 'Set detailed preferences for AI/ML matching'
                      : _expertPreferences!.getSummary(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                leading: const Icon(Icons.tune),
                initiallyExpanded: _showExpertPreferences,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showExpertPreferences = expanded;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kSpaceMd),
                    child: BusinessExpertPreferencesWidget(
                      initialPreferences: _expertPreferences,
                      onPreferencesChanged: (preferences) {
                        setState(() {
                          _expertPreferences = preferences;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patron Preferences Section
            Card(
              child: ExpansionTile(
                title: Text(
                  'Patron Preferences',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _patronPreferences == null
                      ? 'Set preferences for the types of patrons you want to attract'
                      : _patronPreferences!.getSummary(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                leading: const Icon(Icons.people),
                initiallyExpanded: _showPatronPreferences,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showPatronPreferences = expanded;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kSpaceMd),
                    child: BusinessPatronPreferencesWidget(
                      initialPreferences: _patronPreferences,
                      onPreferencesChanged: (preferences) {
                        setState(() {
                          _patronPreferences = preferences;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verification Section
            Card(
              child: ExpansionTile(
                title: Text(
                  'Business Verification',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Verify your business to build trust with users and experts',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                leading: const Icon(Icons.verified_user),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(kSpaceMd),
                    child: BusinessVerificationWidget(
                      business: BusinessAccount(
                        id: 'temp',
                        name: _nameController.text.trim().isEmpty
                            ? 'Your Business'
                            : _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        businessType: _selectedBusinessType,
                        location: _locationController.text.trim().isEmpty
                            ? null
                            : _locationController.text.trim(),
                        phone: _phoneController.text.trim().isEmpty
                            ? null
                            : _phoneController.text.trim(),
                        website: _websiteController.text.trim().isEmpty
                            ? null
                            : _websiteController.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        createdBy: widget.creator.id,
                      ),
                      onVerificationSubmitted: (verification) {
                        // Verification can be submitted after account creation
                        context.showSuccess(
                          'Verification submitted! You can complete verification after creating your account.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: AppColors.grey100,
              child: Padding(
                padding: EdgeInsets.all(kSpaceMd),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How Business Accounts Work',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1. Create your account with basic business information\n'
                            '2. Set preferences for experts and patrons\n'
                            '3. Verify your business (optional but recommended)\n'
                            '4. Connect with experts and attract matching patrons',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      'Create Business Account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceXs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
