import 'package:flutter/material.dart';

class AppSettingRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget control;
  final IconData? leadingIcon;

  const AppSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.control,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingIcon == null ? null : Icon(leadingIcon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: control,
    );
  }
}
