import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

/// A Scaffold wrapper that detects keyboard focus and enhances the environment.
///
/// Behavior:
/// - When keyboard opens:
///   - Blurs the background world x2 (Focus mode)
///   - Dims the lighting
/// - When keyboard closes:
///   - Restores normal ambiance
class FocusAwareScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color backgroundColor;

  const FocusAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor = Colors.transparent,
  });

  @override
  State<FocusAwareScaffold> createState() => _FocusAwareScaffoldState();
}

class _FocusAwareScaffoldState extends State<FocusAwareScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _blurAnimation;
  late Animation<double> _dimAnimation;
  
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _blurAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
    
    _dimAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    
    if (isKeyboardOpen != _isKeyboardVisible) {
      _isKeyboardVisible = isKeyboardOpen;
      if (_isKeyboardVisible) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        return Stack(
          children: [
            // 1. Focus Effect Layer (Background Blur enhancement)
            if (_focusController.value > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    color: AppColors.black.withValues(alpha: _dimAnimation.value),
                  ),
                ),
              ),
              
            // 2. The Actual Scaffold
            Scaffold(
              backgroundColor: widget.backgroundColor,
              appBar: widget.appBar,
              body: widget.body,
              floatingActionButton: widget.floatingActionButton,
            ),
          ],
        );
      },
    );
  }
}
