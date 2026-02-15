import 'package:flutter/material.dart';
import 'package:avrai/core/design/component_tokens.dart';
import 'package:avrai/core/design/design_system.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/design/motion_presets.dart';
import 'package:avrai/core/design/widgets/avrai_components.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// In-app catalog for design token and component verification.
class DesignPlaygroundPage extends StatelessWidget {
  const DesignPlaygroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.text;
    final type = context.typography;
    final buttons =
        Theme.of(context).extension<ButtonTokens>() ?? const ButtonTokens();
    final inputs =
        Theme.of(context).extension<InputTokens>() ?? const InputTokens();
    final cards =
        Theme.of(context).extension<CardTokens>() ?? const CardTokens();
    final chips =
        Theme.of(context).extension<ChipTokens>() ?? const ChipTokens();
    final icons =
        Theme.of(context).extension<IconTokens>() ?? const IconTokens();
    final feedback =
        Theme.of(context).extension<FeedbackTokens>() ?? const FeedbackTokens();

    return AdaptivePlatformPageScaffold(
      title: 'Design Playground',
      scrollable: true,
      body: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Token Snapshot',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              PortalSurface(
                child: Text(
                  'Button radius ${buttons.cornerRadius}, min height ${buttons.minHeight}\n'
                  'Input radius ${inputs.cornerRadius}, focused width ${inputs.focusedBorderWidth}\n'
                  'Card radius ${cards.cornerRadius}, chip radius ${chips.radius}\n'
                  'Icon sizes xs/sm/md/lg: ${icons.xs}/${icons.sm}/${icons.md}/${icons.lg}',
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                'Typography',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              PortalSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AvraiText(
                      'Display Sample',
                      role: AvraiTextRole.display,
                    ),
                    SizedBox(height: spacing.xs),
                    const AvraiText(
                      'Heading Sample',
                      role: AvraiTextRole.heading,
                    ),
                    SizedBox(height: spacing.xs),
                    const AvraiText(
                      'Body sample text for design consistency and readability.',
                      role: AvraiTextRole.body,
                    ),
                    SizedBox(height: spacing.xs),
                    const AvraiText(
                      'Caption sample',
                      role: AvraiTextRole.caption,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      'Scale: display ${type.display}, heading ${type.heading}, body ${type.body}, caption ${type.caption}',
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                'Controls',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              PortalSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AvraiInput(
                      label: 'Tokenized input',
                      hint: 'Uses global InputDecorationTheme',
                    ),
                    SizedBox(height: spacing.md),
                    Wrap(
                      spacing: spacing.xs,
                      runSpacing: spacing.xs,
                      children: const [
                        Chip(label: Text('Default')),
                        Chip(label: Text('Portal')),
                        Chip(label: Text('Adaptive')),
                      ],
                    ),
                    SizedBox(height: spacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 360;
                        final first = AvraiButton(
                          onPressed: () => FeedbackPresenter.showSnack(
                            context,
                            message: 'Success feedback',
                            kind: FeedbackKind.success,
                          ),
                          child: const Text('Primary'),
                        );
                        final second = AvraiButton(
                          outlined: true,
                          onPressed: () => FeedbackPresenter.showSnack(
                            context,
                            message: 'Warning feedback',
                            kind: FeedbackKind.warning,
                          ),
                          child: const Text('Outlined'),
                        );
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              first,
                              SizedBox(height: spacing.xs),
                              second,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: first),
                            SizedBox(width: spacing.sm),
                            Expanded(child: second),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                'State Patterns',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              const AvraiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvraiStatusPill(text: 'Loading'),
                    SizedBox(height: 8),
                    Text(
                      'Use this section as baseline for loading/empty/error states.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                'Feedback Colors',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              PortalSurface(
                child: Column(
                  children: [
                    _feedbackRow('Info', feedback.infoColor),
                    _feedbackRow('Success', feedback.successColor),
                    _feedbackRow('Warning', feedback.warningColor),
                    _feedbackRow('Error', feedback.errorColor),
                  ],
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                'Motion Sample',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.sm),
              _MotionSampleCard(
                duration: MotionPresets.normal(context),
                curve: MotionPresets.emphasized,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpaceXsTight),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _MotionSampleCard extends StatefulWidget {
  final Duration duration;
  final Curve curve;

  const _MotionSampleCard({
    required this.duration,
    required this.curve,
  });

  @override
  State<_MotionSampleCard> createState() => _MotionSampleCardState();
}

class _MotionSampleCardState extends State<_MotionSampleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PortalSurface(
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          height: _expanded ? 148 : 72,
          color: _expanded
              ? AppColors.electricGreen.withValues(alpha: 0.12)
              : AppColors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(kSpaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tap to animate'),
                  const SizedBox(height: 4),
                  Text(_expanded ? 'Expanded' : 'Collapsed'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
