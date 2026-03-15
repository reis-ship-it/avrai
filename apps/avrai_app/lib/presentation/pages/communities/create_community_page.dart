import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Community');
  final _localityController =
      TextEditingController(text: BhamBetaDefaults.defaultHomebase);
  final CommunityService _communityService = CommunityService();

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
      final community = await _communityService.createCommunity(
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
      context.go('/community/${community.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create community: $error')),
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
      title: 'Create Community',
      body: AppSurface(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start a direct Birmingham community without waiting for an event upgrade.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _nameController,
                label: 'Community name',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _descriptionController,
                label: 'What is this community for?',
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
                  child: Text(
                    _isSubmitting ? 'Creating...' : 'Create community',
                  ),
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
