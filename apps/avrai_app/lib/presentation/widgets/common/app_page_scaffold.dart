import 'package:flutter/material.dart';

import 'package:avrai/presentation/widgets/common/app_page_header.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

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
  final Key? scrollViewKey;

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
    this.scrollViewKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: title,
      actions: actions,
      scrollable: false,
      constrainBody: constrainBody,
      showNavigationBar: showNavigationBar,
      body: scrollable
          ? SingleChildScrollView(
              key: scrollViewKey,
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
                  Expanded(child: child),
                ],
              ),
            ),
    );
  }
}
