import 'dart:io';

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Step 2: Profile Basics page.
///
/// Collects:
/// - Display name (required)
/// - Profile photo (optional, triggers camera/photos permission contextually)
class ProfileBasicsPage extends StatefulWidget {
  /// Initial display name
  final String? initialDisplayName;

  /// Initial profile photo path
  final String? initialPhotoPath;

  /// Callback when display name changes
  final ValueChanged<String?> onDisplayNameChanged;

  /// Callback when profile photo changes
  final ValueChanged<String?> onPhotoChanged;

  const ProfileBasicsPage({
    super.key,
    this.initialDisplayName,
    this.initialPhotoPath,
    required this.onDisplayNameChanged,
    required this.onPhotoChanged,
  });

  @override
  State<ProfileBasicsPage> createState() => _ProfileBasicsPageState();
}

class _ProfileBasicsPageState extends State<ProfileBasicsPage> {
  late TextEditingController _nameController;
  String? _photoPath;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
    _photoPath = widget.initialPhotoPath;

    _nameController.addListener(() {
      widget.onDisplayNameChanged(_nameController.text.trim());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, 'library'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'remove') {
      setState(() {
        _photoPath = null;
      });
      widget.onPhotoChanged(null);
      return;
    }

    await _pickPhoto(
        result == 'camera' ? ImageSource.camera : ImageSource.gallery);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPickingPhoto) return;

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      // Check and request permission based on source
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;

      final status = await permission.status;

      if (!status.isGranted) {
        final result = await permission.request();

        if (!result.isGranted) {
          if (mounted) {
            _showPermissionDeniedDialog(source);
          }
          return;
        }
      }

      // Pick the image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _photoPath = pickedFile.path;
        });
        widget.onPhotoChanged(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog(ImageSource source) {
    final permissionName =
        source == ImageSource.camera ? 'Camera' : 'Photo Library';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Access Required'),
        content: Text(
          'To add a profile photo, please allow $permissionName access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            'Set Up Your Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us what to call you. You can add a photo if you'd like.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Profile Photo
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    image: _photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoPath == null
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _photoPath != null ? Icons.edit : Icons.add_a_photo,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
                if (_isPickingPhoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add photo (optional)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 40),

          // Display Name Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This is how you'll appear to others in the app.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 50,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Info card
          PortalSurface(
            color: AppColors.grey600.withValues(alpha: 0.1),
            borderColor: AppColors.grey600.withValues(alpha: 0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.grey600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your name helps others recognize you at events and communities. '
                    'You can change it anytime in settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
