import 'package:flutter/widgets.dart';

enum Breakpoint { xs, sm, md, lg, xl }

class Responsive {
  static Breakpoint breakpointOf(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return Breakpoint.xs;
    if (width < 600) return Breakpoint.sm;
    if (width < 900) return Breakpoint.md;
    if (width < 1200) return Breakpoint.lg;
    return Breakpoint.xl;
  }

  static T value<T>({
    required BuildContext context,
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
  }) {
    final bp = breakpointOf(context);
    switch (bp) {
      case Breakpoint.xs:
        return xs;
      case Breakpoint.sm:
        return sm ?? xs;
      case Breakpoint.md:
        return md ?? sm ?? xs;
      case Breakpoint.lg:
        return lg ?? md ?? sm ?? xs;
      case Breakpoint.xl:
        return xl ?? lg ?? md ?? sm ?? xs;
    }
  }
}


