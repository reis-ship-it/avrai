import 'package:avrai_admin_app/theme/colors.dart';
import 'package:flutter/material.dart';

class ImmersiveScrollPhysics extends BouncingScrollPhysics {
  const ImmersiveScrollPhysics({super.parent});

  @override
  ImmersiveScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ImmersiveScrollPhysics(parent: buildParent(ancestor));
  }
}

class ImmersiveScrollBehavior extends ScrollBehavior {
  const ImmersiveScrollBehavior({this.isDark = true});

  final bool isDark;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: isDark ? AppColors.grey300 : AppColors.grey700,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ImmersiveScrollPhysics();
  }
}
