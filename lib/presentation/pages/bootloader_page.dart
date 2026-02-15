import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

import 'package:avrai/core/services/device/world_orientation_service.dart';
import 'package:avrai/presentation/widgets/portal/turbine_loader.dart';
import 'dart:developer' as developer;

/// The first screen user sees.
/// It pre-compiles shaders, warms up sensors, and fades in the Portal.
class BootloaderPage extends StatefulWidget {
  final Widget child; // The actual app (Navigator/Router)

  const BootloaderPage({required this.child, super.key});

  @override
  State<BootloaderPage> createState() => _BootloaderPageState();
}

class _BootloaderPageState extends State<BootloaderPage>
    with SingleTickerProviderStateMixin {
  bool _isReady = false;
  late AnimationController _fadeController;
  late Animation<double> _logoOpacity;
  late Animation<double> _uiOpacity;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Sequence:
    // 0.0 - 0.5: Loading (Logo Visible)
    // 0.5 - 1.0: Fade In UI (Logo Fades Out)

    _logoOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Compile Shader
      // Just loading it caches it in the engine
      await ui.FragmentProgram.fromAsset('shaders/portal_world.frag');

      // 2. Warm up Sensors
      // Start the service so it has a value ready
      await WorldOrientationService().start();

      // 3. Pre-load heavy fonts/assets if needed
      // (Fonts handled by flutter engine automatically if declared)

      // Add artificial delay if too fast (prevent flash)
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _fadeController.forward();
      }
    } catch (e) {
      developer.log('Bootloader error: $e', name: 'BootloaderPage');
      // Proceed anyway to avoid locking user out
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _fadeController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The App (Portal + UI)
        // Hidden initially, fades in
        if (_isReady)
          AnimatedBuilder(
            animation: _uiOpacity,
            builder: (context, child) {
              return Opacity(
                opacity: _uiOpacity.value,
                child: widget.child,
              );
            },
          ),

        // 2. The Boot Screen (Logo)
        // Fades out
        AnimatedBuilder(
          animation: _logoOpacity,
          builder: (context, child) {
            if (_logoOpacity.value <= 0) return const SizedBox.shrink();

            return Opacity(
              opacity: _logoOpacity.value,
              child: Container(
                color: const Color(0xFF0A1A2F), // Deep Night Background
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Placeholder (Turbine for now)
                      const TurbineLoader(size: 80, isDark: false),
                      const SizedBox(height: 24),
                      Text(
                        'AVRAI',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
