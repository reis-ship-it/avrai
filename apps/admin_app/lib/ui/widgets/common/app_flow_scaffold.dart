import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppFlowScaffold extends StatelessWidget {
  const AppFlowScaffold({
    super.key,
    this.title = '',
    this.titleWidget,
    required this.body,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.scrollable = false,
    this.useSafeArea = true,
    this.padding,
    this.constrainBody = true,
    this.backgroundColor = Colors.transparent,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.materialBottom,
    this.showNavigationBar = true,
    this.appBarElevation,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool scrollable;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final bool constrainBody;
  final Color backgroundColor;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final PreferredSizeWidget? materialBottom;
  final bool showNavigationBar;
  final double? appBarElevation;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;

  bool _isCupertinoPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  Widget _buildConstrainedContent(BuildContext context) {
    final contentPadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        );

    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: contentPadding,
          child: body,
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

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final content = constrainBody
        ? _buildConstrainedContent(context)
        : (useSafeArea ? SafeArea(child: body) : body);

    if (_isCupertinoPlatform(platform)) {
      final navigator = Navigator.maybeOf(context);
      final hasBackStack = navigator?.canPop() ?? false;
      final resolvedLeading = leading ??
          (automaticallyImplyLeading && hasBackStack
              ? CupertinoNavigationBarBackButton(
                  onPressed: () => navigator?.maybePop(),
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
