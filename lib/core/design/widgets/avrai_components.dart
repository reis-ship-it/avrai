import 'package:flutter/material.dart';
import 'package:avrai/core/design/design_system.dart';
import 'package:avrai/core/theme/colors.dart';

enum AvraiTextRole { display, heading, title, body, caption, button }

class AvraiButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool outlined;

  const AvraiButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

class AvraiInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const AvraiInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class AvraiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AvraiCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: padding ?? EdgeInsets.all(context.spacing.md),
        child: child,
      ),
    );
  }
}

class AvraiStatusPill extends StatelessWidget {
  final String text;
  final Color? color;

  const AvraiStatusPill({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.electricGreen;
    final spacing = context.spacing;
    final radii = context.radii;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radii.xl * 2),
      ),
      child: Text(
        text,
        style: context.text.labelMedium?.copyWith(
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AvraiText extends StatelessWidget {
  final String value;
  final AvraiTextRole role;
  final TextAlign? textAlign;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;

  const AvraiText(
    this.value, {
    super.key,
    this.role = AvraiTextRole.body,
    this.textAlign,
    this.color,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final type = context.typography;
    final base = switch (role) {
      AvraiTextRole.display => context.text.headlineMedium ?? const TextStyle(),
      AvraiTextRole.heading => context.text.titleLarge ?? const TextStyle(),
      AvraiTextRole.title => context.text.titleMedium ?? const TextStyle(),
      AvraiTextRole.body => context.text.bodyMedium ?? const TextStyle(),
      AvraiTextRole.caption => context.text.bodySmall ?? const TextStyle(),
      AvraiTextRole.button => context.text.labelLarge ?? const TextStyle(),
    };

    final size = switch (role) {
      AvraiTextRole.display => type.display,
      AvraiTextRole.heading => type.heading,
      AvraiTextRole.title => type.title,
      AvraiTextRole.body => type.body,
      AvraiTextRole.caption => type.caption,
      AvraiTextRole.button => type.button,
    };

    return Text(
      value,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: base.copyWith(
        fontSize: size,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}
