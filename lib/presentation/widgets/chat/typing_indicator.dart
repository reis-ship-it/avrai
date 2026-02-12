/// Typing Indicator Widget
/// 
/// Shows animated typing indicator for chat
/// 
/// Phase 3 Enhancement: Typing Indicators
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

class TypingIndicator extends StatefulWidget {
  final String? senderName;
  
  const TypingIndicator({
    super.key,
    this.senderName,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.grey300,
            child: Icon(
              Icons.person,
              size: 16,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDot(0),
                        const SizedBox(width: 4),
                        _buildDot(0.3),
                        const SizedBox(width: 4),
                        _buildDot(0.6),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.senderName != null) ...[
            const SizedBox(width: 8),
            Text(
              '${widget.senderName} is typing...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        final opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

