import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_page_header.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget child;
  final List<Widget>? actions;
  final bool scrollable;
  final bool showNavigationBar;
  final bool constrainBody;
  final EdgeInsetsGeometry? padding;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.child,
    this.actions,
    this.scrollable = true,
    this.showNavigationBar = true,
    this.constrainBody = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: title,
      actions: actions,
      constrainBody: constrainBody,
      showNavigationBar: showNavigationBar,
      body: scrollable
          ? SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: title,
                    subtitle: subtitle,
                    leadingIcon: leadingIcon,
                  ),
                  child,
                ],
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: title,
                    subtitle: subtitle,
                    leadingIcon: leadingIcon,
                  ),
                  child,
                ],
              ),
            ),
    );
  }
}
