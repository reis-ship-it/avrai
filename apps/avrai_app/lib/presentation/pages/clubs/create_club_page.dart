import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';

class CreateClubPage extends StatefulWidget {
  const CreateClubPage({super.key});

  @override
  State<CreateClubPage> createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateClubPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Club');
  final _localityController =
      TextEditingController(text: BhamBetaDefaults.defaultHomebase);
  final ClubService _clubService = ClubService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _localityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final club = await _clubService.createClub(
        founderId: authState.user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        originalLocality: _localityController.text.trim(),
        cityCode: 'BHAM',
        localityCode: _localityController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      context.go('/club/${club.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create club: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Create Club',
      body: AppSurface(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a structured Birmingham club directly for the beta instead of waiting on an upgrade path.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _nameController,
                label: 'Club name',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _descriptionController,
                label: 'What will this club organize?',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _categoryController,
                label: 'Category',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _localityController,
                label: 'Primary Birmingham locality',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Creating...' : 'Create club'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
