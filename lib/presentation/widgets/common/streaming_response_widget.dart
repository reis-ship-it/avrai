/// Streaming Response Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
/// Displays AI responses with typing animation as they stream in.
/// 
/// Features:
/// - Character-by-character typing animation
/// - Streaming text from LLM responses
/// - Cursor blink effect
/// - Speed control (fast/normal/slow)
/// - Auto-scroll as text appears
/// - Stop streaming button
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:avrai/core/theme/colors.dart';

/// Widget that displays streaming text with typing animation
class StreamingResponseWidget extends StatefulWidget {
  final Stream<String> textStream;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final VoidCallback? onStop;
  final bool autoScroll;
  
  const StreamingResponseWidget({
    super.key,
    required this.textStream,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.showCursor = true,
    this.onComplete,
    this.onStop,
    this.autoScroll = true,
  });
  
  @override
  State<StreamingResponseWidget> createState() => _StreamingResponseWidgetState();
}

class _StreamingResponseWidgetState extends State<StreamingResponseWidget> with SingleTickerProviderStateMixin {
  final StringBuffer _buffer = StringBuffer();
  String _displayedText = '';
  bool _isStreaming = true;
  bool _cursorVisible = true;
  
  StreamSubscription<String>? _streamSubscription;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startCursorBlink();
    _listenToStream();
  }
  
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _fadeController.forward();
  }
  
  void _startCursorBlink() {
    if (!widget.showCursor) return;
    
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (timer) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });
  }
  
  void _listenToStream() {
    _streamSubscription = widget.textStream.listen(
      (chunk) {
        if (mounted && _isStreaming) {
          _buffer.write(chunk);
          _processBuffer();
        }
      },
      onDone: () {
        if (mounted) {
          _finishStreaming();
        }
      },
      onError: (error) {
        developer.log('Stream error: $error', name: 'StreamingResponseWidget');
        if (mounted) {
          _finishStreaming();
        }
      },
    );
  }
  
  void _processBuffer() {
    // Process buffer character by character with typing effect
    if (_typingTimer != null && _typingTimer!.isActive) {
      return; // Already processing
    }
    
    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted || !_isStreaming) {
        timer.cancel();
        return;
      }
      
      final bufferText = _buffer.toString();
      if (_displayedText.length < bufferText.length) {
        setState(() {
          _displayedText = bufferText.substring(0, _displayedText.length + 1);
        });
        
        if (widget.autoScroll) {
          _scrollToBottom();
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _finishStreaming() {
    setState(() {
      _isStreaming = false;
      _displayedText = _buffer.toString();
    });
    
    _typingTimer?.cancel();
    widget.onComplete?.call();
  }
  
  void _stopStreaming() {
    if (!_isStreaming) return;
    
    setState(() {
      _isStreaming = false;
      _displayedText = _buffer.toString();
    });
    
    _streamSubscription?.cancel();
    _typingTimer?.cancel();
    widget.onStop?.call();
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText.rich(
                  TextSpan(
                    text: _displayedText,
                    style: widget.textStyle ??
                        const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                    children: [
                      if (_isStreaming && widget.showCursor && _cursorVisible)
                        const TextSpan(
                          text: '▊',
                          style: TextStyle(
                            color: AppColors.electricGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isStreaming && widget.onStop != null)
            _buildStopButton(),
        ],
      ),
    );
  }
  
  Widget _buildStopButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
      ),
      child: OutlinedButton.icon(
        onPressed: _stopStreaming,
        icon: const Icon(Icons.stop_circle_outlined, size: 18),
        label: const Text('Stop Generating'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
    );
  }
}

/// Simple text widget that types out text character by character
class TypingTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration typingSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  
  const TypingTextWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.typingSpeed = const Duration(milliseconds: 50),
    this.showCursor = true,
    this.onComplete,
  });
  
  @override
  State<TypingTextWidget> createState() => _TypingTextWidgetState();
}

class _TypingTextWidgetState extends State<TypingTextWidget> {
  String _displayedText = '';
  bool _cursorVisible = true;
  bool _isTyping = true;
  
  Timer? _typingTimer;
  Timer? _cursorTimer;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _startTyping();
    _startCursorBlink();
  }
  
  void _startTyping() {
    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _currentIndex++;
          _displayedText = widget.text.substring(0, _currentIndex);
        });
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
        widget.onComplete?.call();
      }
    });
  }
  
  void _startCursorBlink() {
    if (!widget.showCursor) return;
    
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (timer) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: _displayedText,
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
        children: [
          if (_isTyping && widget.showCursor && _cursorVisible)
            const TextSpan(
              text: '▊',
              style: TextStyle(
                color: AppColors.electricGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated typing indicator (dots)
class TypingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  
  const TypingIndicator({
    super.key,
    this.color = AppColors.electricGreen,
    this.size = 8.0,
  });
  
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = (value < 0.5) 
                ? (value * 2).clamp(0.3, 1.0)
                : (2 - value * 2).clamp(0.3, 1.0);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

