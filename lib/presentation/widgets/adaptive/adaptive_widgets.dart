// Adaptive Widgets Library
//
// Platform-adaptive widgets that use Cupertino design on iOS
// and Material design on Android.
//
// Features:
// - AdaptiveButton - CupertinoButton / ElevatedButton
// - AdaptiveSwitch - CupertinoSwitch / Switch
// - AdaptiveSlider - CupertinoSlider / Slider
// - AdaptiveDialog - CupertinoAlertDialog / AlertDialog
// - AdaptiveDatePicker - CupertinoDatePicker / DatePicker
// - AdaptiveActivityIndicator - CupertinoActivityIndicator / CircularProgressIndicator
// - AdaptiveTextField - CupertinoTextField / TextField
// - AdaptiveListTile - iOS-style / Material ListTile
//
// Usage:
//   AdaptiveButton(
//     child: Text('Press Me'),
//     onPressed: () {},
//   )

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/core/services/device/haptics_service.dart';

/// Platform-adaptive button widget.
///
/// Uses CupertinoButton on iOS, ElevatedButton on other platforms.
class AdaptiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final bool filled;
  final EdgeInsetsGeometry? padding;
  final double? minSize;
  final BorderRadius? borderRadius;

  const AdaptiveButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.filled = true,
    this.padding,
    this.minSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(
        color: filled ? (color ?? AppColors.electricGreen) : null,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        onPressed: onPressed != null
            ? () {
                HapticsService.light();
                onPressed!();
              }
            : null, minimumSize: Size(minSize ?? 44.0, minSize ?? 44.0),
        child: child,
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? (color ?? AppColors.electricGreen) : null,
        foregroundColor:
            filled ? AppColors.black : (color ?? AppColors.electricGreen),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: Size(minSize ?? 64, minSize ?? 44),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Platform-adaptive text button.
class AdaptiveTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;

  const AdaptiveTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed != null
            ? () {
                HapticsService.light();
                onPressed!();
              }
            : null,
        child: DefaultTextStyle(
          style: TextStyle(color: color ?? AppColors.electricGreen),
          child: child,
        ),
      );
    }

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.electricGreen,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Platform-adaptive switch widget.
///
/// Uses CupertinoSwitch on iOS, Switch on other platforms.
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        activeTrackColor: activeColor ?? AppColors.electricGreen,
        onChanged: onChanged != null
            ? (newValue) {
                HapticsService.selection();
                onChanged!(newValue);
              }
            : null,
      );
    }

    return Switch(
      value: value,
      activeThumbColor: activeColor ?? AppColors.electricGreen,
      onChanged: onChanged,
    );
  }
}

/// Platform-adaptive slider widget.
///
/// Uses CupertinoSlider on iOS, Slider on other platforms.
class AdaptiveSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;

  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor ?? AppColors.electricGreen,
        onChanged: onChanged != null
            ? (newValue) {
                if (divisions != null) {
                  HapticsService.slider();
                }
                onChanged!(newValue);
              }
            : null,
      );
    }

    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor ?? AppColors.electricGreen,
      onChanged: onChanged,
    );
  }
}

/// Platform-adaptive activity indicator.
///
/// Uses CupertinoActivityIndicator on iOS, CircularProgressIndicator on other platforms.
class AdaptiveActivityIndicator extends StatelessWidget {
  final double? radius;
  final Color? color;

  const AdaptiveActivityIndicator({
    super.key,
    this.radius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: radius ?? 10.0,
        color: color ?? AppColors.electricGreen,
      );
    }

    return SizedBox(
      width: (radius ?? 10.0) * 2,
      height: (radius ?? 10.0) * 2,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.electricGreen,
        ),
      ),
    );
  }
}

/// Platform-adaptive text field.
///
/// Uses CupertinoTextField on iOS, TextField on other platforms.
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        prefix: prefix,
        suffix: suffix,
        autofocus: autofocus,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: placeholder,
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}

/// Show a platform-adaptive dialog.
///
/// Uses CupertinoAlertDialog on iOS, AlertDialog on other platforms.
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  required List<AdaptiveDialogAction> actions,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: content != null ? Text(content) : null,
        actions: actions.map((action) {
          return CupertinoDialogAction(
            isDefaultAction: action.isDefault,
            isDestructiveAction: action.isDestructive,
            onPressed: () {
              HapticsService.light();
              action.onPressed?.call();
            },
            child: Text(action.label),
          );
        }).toList(),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: actions.map((action) {
        return TextButton(
          style: action.isDestructive
              ? TextButton.styleFrom(foregroundColor: AppColors.error)
              : null,
          onPressed: action.onPressed,
          child: Text(action.label),
        );
      }).toList(),
    ),
  );
}

/// Action for adaptive dialog
class AdaptiveDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;

  const AdaptiveDialogAction({
    required this.label,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });
}

/// Show a platform-adaptive date picker.
///
/// Uses CupertinoDatePicker on iOS, showDatePicker on other platforms.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
  CupertinoDatePickerMode mode = CupertinoDatePickerMode.date,
}) async {
  if (Platform.isIOS) {
    DateTime? selectedDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    HapticsService.selection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: mode,
                initialDateTime: initialDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                onDateTimeChanged: (date) {
                  HapticsService.selection();
                  selectedDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );

    return selectedDate ?? initialDate;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: minimumDate ?? DateTime(1900),
    lastDate: maximumDate ?? DateTime(2100),
  );
}

/// Show a platform-adaptive time picker.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  if (Platform.isIOS) {
    TimeOfDay? selectedTime;
    final initialDateTime = DateTime(
      2000,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    HapticsService.selection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (date) {
                  HapticsService.selection();
                  selectedTime =
                      TimeOfDay(hour: date.hour, minute: date.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );

    return selectedTime ?? initialTime;
  }

  return showTimePicker(
    context: context,
    initialTime: initialTime,
  );
}

/// Platform-adaptive list tile.
class AdaptiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing:
            trailing ?? (showChevron ? const CupertinoListTileChevron() : null),
        onTap: onTap != null
            ? () {
                HapticsService.light();
                onTap!();
              }
            : null,
      );
    }

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing:
          trailing ?? (showChevron ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

/// Platform-adaptive refresh indicator.
class AdaptiveRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AdaptiveRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS uses CustomScrollView with CupertinoSliverRefreshControl
      if (child is CustomScrollView) {
        return child;
      }

      // Wrap in CustomScrollView for iOS bounce
      return RefreshIndicator(
        onRefresh: () async {
          HapticsService.pullToRefresh();
          await onRefresh();
        },
        child: child,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Platform-adaptive scroll physics.
ScrollPhysics get adaptiveScrollPhysics {
  if (Platform.isIOS) {
    return const BouncingScrollPhysics();
  }
  return const ClampingScrollPhysics();
}

/// Platform-adaptive page transition builder.
PageTransitionsBuilder get adaptivePageTransitionsBuilder {
  if (Platform.isIOS) {
    return const CupertinoPageTransitionsBuilder();
  }
  return const ZoomPageTransitionsBuilder();
}
