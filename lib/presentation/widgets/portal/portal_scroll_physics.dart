import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

/// Custom scroll physics that replaces the standard "Stretch" or "Bounce"
/// with a "Solid Barrier" feel.
///
/// Use in conjunction with [PortalScrollBehavior] to add the edge glow.
class PortalScrollPhysics extends BouncingScrollPhysics {
  const PortalScrollPhysics({super.parent});

  @override
  PortalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PortalScrollPhysics(parent: buildParent(ancestor));
  }
}

/// A ScrollBehavior that applies the "Electric Edge Glow" (Day: White, Night: Electric Blue).
class PortalScrollBehavior extends ScrollBehavior {
  final bool isDark;

  const PortalScrollBehavior({this.isDark = true});

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Android/Custom Glow
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: isDark ? const Color(0xFFE0E0E0) : AppColors.electricGreen,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const PortalScrollPhysics();
  }
}
