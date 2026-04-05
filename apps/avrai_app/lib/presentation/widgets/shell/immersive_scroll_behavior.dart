import 'package:flutter/material.dart';

import 'package:avrai/theme/colors.dart';

class ImmersiveScrollPhysics extends BouncingScrollPhysics {
  const ImmersiveScrollPhysics({super.parent});

  @override
  ImmersiveScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ImmersiveScrollPhysics(parent: buildParent(ancestor));
  }
}

class ImmersiveScrollBehavior extends ScrollBehavior {
  final bool isDark;

  const ImmersiveScrollBehavior({this.isDark = true});

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
