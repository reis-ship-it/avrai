import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/widgets/portal/glass_slate.dart';
import 'package:avrai/presentation/widgets/portal/portal_shader_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// The root layout for the Portal Design System.
///
/// It stacks the 3D World Background, the Negative Border logic,
/// and the Floating Glass Slate into a single wrapper.
///
/// Wrap your MaterialApp.builder or Router outlet with this.
class AvraiPortalLayout extends StatelessWidget {
  final Widget child;
  final bool isDark; // Controlled by Theme or System

  const AvraiPortalLayout({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final portal = context.portal;
    return AdaptivePlatformPageScaffold(
      title: '',
      showNavigationBar: false,
      constrainBody: false,
      backgroundColor: AppColors.transparent,
      body: Stack(
        children: [
          // LAYER 1: The Infinite Dream World (Background)
          // Fills the entire screen including notch/status bar area
          const Positioned.fill(
            child: PortalShaderWidget(),
          ),

          // LAYER 2: The Floating Window (UI)
          // Wrapped in SafeArea so it floats inside the hardware boundaries
          SafeArea(
            child: Padding(
              // THE NEGATIVE BORDER
              // 12px gap on all sides so the world is visible 360 degrees
              padding: EdgeInsets.all(portal.edgePadding),

              // THE GLASS SLATE
              child: GlassSlate(
                isDark: isDark,
                child: child, // The app navigation lives inside here
              ),
            ),
          ),
        ],
      ),
    );
  }
}
