import 'package:flutter/material.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/expertise/expertise_recognition_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Expertise Recognition Widget
/// Displays community recognition and appreciation
class ExpertiseRecognitionWidget extends StatelessWidget {
  final UnifiedUser expert;
  final Function(UnifiedUser)? onRecognize;

  Future<List<ExpertRecognition>> _getRecognitions() async {
    // Ensure the Future completes asynchronously so the loading state renders
    // for at least one frame (keeps UI/tests deterministic).
    await Future<void>.delayed(Duration.zero);
    return ExpertiseRecognitionService().getRecognitionsForExpert(expert);
  }

  const ExpertiseRecognitionWidget({
    super.key,
    required this.expert,
    this.onRecognize,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExpertRecognition>>(
      future: _getRecognitions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final recognitions = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, recognitions.length),
            const SizedBox(height: 8),
            if (recognitions.isEmpty)
              _buildEmptyState(context)
            else
              _buildRecognitionsList(context, recognitions),
            if (onRecognize != null) ...[
              const SizedBox(height: 16),
              _buildRecognizeButton(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Row(
      children: [
        Text(
          'Community Recognition',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kSpaceXs, vertical: kSpaceNano),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceLg),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No recognition yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to recognize this expert!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionsList(
      BuildContext context, List<ExpertRecognition> recognitions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recognitions.length,
      itemBuilder: (context, index) {
        return _buildRecognitionCard(context, recognitions[index]);
      },
    );
  }

  Widget _buildRecognitionCard(
      BuildContext context, ExpertRecognition recognition) {
    IconData icon;
    Color color;

    switch (recognition.type) {
      case RecognitionType.helpful:
        icon = Icons.help_outline;
        color = AppColors.electricGreen;
        break;
      case RecognitionType.inspiring:
        icon = Icons.lightbulb_outline;
        color = AppColors.warning;
        break;
      case RecognitionType.exceptional:
        icon = Icons.star;
        color = AppColors.electricGreen;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: kSpaceXxs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          recognition.recognizer.displayName ?? recognition.recognizer.email,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(recognition.reason),
            const SizedBox(height: 4),
            Text(
              _formatDate(recognition.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            recognition.type.name.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildRecognizeButton() {
    return ElevatedButton.icon(
      onPressed: () => onRecognize?.call(expert),
      icon: const Icon(Icons.favorite),
      label: Text('Recognize Expert'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricGreen,
        foregroundColor: AppColors.white,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Featured Expert Widget
class FeaturedExpertWidget extends StatelessWidget {
  final FeaturedExpert featuredExpert;

  const FeaturedExpertWidget({
    super.key,
    required this.featuredExpert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.electricGreen,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Featured Expert',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Expert Info
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.grey200,
                child: featuredExpert.expert.photoUrl != null
                    ? Image.network(featuredExpert.expert.photoUrl!)
                    : Text(
                        (featuredExpert.expert.displayName ??
                                featuredExpert.expert.email)[0]
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      featuredExpert.expert.displayName ??
                          featuredExpert.expert.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${featuredExpert.recognitionCount} recognitions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
