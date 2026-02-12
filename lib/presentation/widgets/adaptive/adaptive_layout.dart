import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:avrai/core/theme/responsive.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

class AdaptivePageScaffold extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;

  const AdaptivePageScaffold({
    super.key,
    required this.child,
    this.scrollable = false,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final contentPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.value(
            context: context,
            xs: spacing.md,
            sm: spacing.lg,
            md: spacing.xl,
            lg: spacing.xl,
            xl: spacing.xxl,
          ),
          vertical: spacing.lg,
        );

    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.value(
            context: context,
            xs: context.portal.maxPhoneContentWidth,
            sm: context.portal.maxPhoneContentWidth,
            md: context.portal.maxTabletContentWidth,
            lg: context.portal.maxDesktopContentWidth,
            xl: context.portal.maxDesktopContentWidth,
          ),
        ),
        child: Padding(
          padding: contentPadding,
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}

class AdaptivePaneLayout extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;
  final double secondaryFlex;
  final double gap;

  const AdaptivePaneLayout({
    super.key,
    required this.primary,
    this.secondary,
    this.secondaryFlex = 0.8,
    this.gap = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (secondary == null) return primary;
    final bp = Responsive.breakpointOf(context);
    final isMultiPane = bp == Breakpoint.lg || bp == Breakpoint.xl;
    if (!isMultiPane) return primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: primary),
        SizedBox(width: gap),
        Expanded(flex: (secondaryFlex * 10).round(), child: secondary!),
      ],
    );
  }
}

class AdaptivePlatformPageScaffold extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool scrollable;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool constrainBody;
  final bool showNavigationBar;
  final PreferredSizeWidget? materialBottom;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final double? appBarElevation;

  const AdaptivePlatformPageScaffold({
    super.key,
    required this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.scrollable = false,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
    this.constrainBody = true,
    this.showNavigationBar = true,
    this.materialBottom,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.appBarElevation,
  });

  bool _isCupertinoPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final content = constrainBody
        ? AdaptivePageScaffold(
            scrollable: scrollable,
            useSafeArea: useSafeArea,
            padding: padding,
            child: body,
          )
        : (useSafeArea ? SafeArea(child: body) : body);

    if (_isCupertinoPlatform(platform)) {
      final hasBackStack = Navigator.of(context).canPop();
      final resolvedLeading = leading ??
          (automaticallyImplyLeading && hasBackStack
              ? CupertinoNavigationBarBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null);

      if (showNavigationBar && materialBottom == null) {
        return CupertinoPageScaffold(
          backgroundColor: backgroundColor,
          navigationBar: CupertinoNavigationBar(
            middle: titleWidget ?? Text(title),
            leading: resolvedLeading,
            trailing: actions == null || actions!.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
          ),
          child: content,
        );
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showNavigationBar
          ? AppBar(
              title: titleWidget ?? Text(title),
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
              actions: actions,
              bottom: materialBottom,
              backgroundColor: appBarBackgroundColor,
              foregroundColor: appBarForegroundColor,
              elevation: appBarElevation,
            )
          : null,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
