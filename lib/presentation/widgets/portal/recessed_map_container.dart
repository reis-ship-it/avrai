import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';

/// A container that makes the map look like a "Recessed Instrument" or "Hole"
/// cut into the Glass Slate.
///
/// It applies:
/// 1. Rounded corners (R20)
/// 2. Inner Shadow (simulated via inverted overlay) to create depth
/// 3. Vignette (darkened edges) to blend the map into the hole
/// 4. Hardware Crosshairs overlay
class RecessedMapContainer extends StatelessWidget {
  final Widget child; // The Map Widget (GoogleMap or AppleMap)
  final bool isDark;

  const RecessedMapContainer({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final portal = context.portal;
    final cornerRadius = portal.recessedMapCornerRadius;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.1), // Subtle edge
          width: portal.recessedMapBorderWidth,
        ),
        // The "Recessed" Shadow effect
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.8), // Deep darkness
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 0), // Inner glow
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Stack(
          children: [
            // 1. The Map Widget
            Positioned.fill(child: child),

            // 2. The Vignette & Shadow Overlay (Simulating Inner Shadow)
            // Since Flutter doesn't have true 'inset' shadows in BoxShadow,
            // we use an overlay with a radial gradient.
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.black.withValues(
                        alpha: portal.recessedMapVignetteAlpha,
                      ),
                    ],
                    stops: const [0.7, 1.0], // Only darken the corners
                    radius: 1.0,
                  ),
                ),
              ),
            ),

            // 3. The "Hardware" Crosshairs (Scanner Vibe)
            Center(
              child: IgnorePointer(
                child: Icon(Icons.add,
                    color: AppColors.white.withValues(alpha: 0.3), size: 20),
              ),
            ),

            // Optional: Corner brackets or scanner lines could go here
          ],
        ),
      ),
    );
  }
}
