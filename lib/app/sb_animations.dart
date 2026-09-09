import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'sb_colors.dart';
import 'sb_radius.dart';

/// Soft Blue Design System — Animation Library
///
/// Subtle, fluid animations replacing the snappy Neo-Brutalism effects.
/// All animations use easeOutCubic for a natural, calming feel.

/// Press effect: scales to 0.97 on press, 150ms easeOutCubic.
///
/// Wraps any widget to add a soft press feedback. Works with both
/// self-handling widgets (buttons) and standalone elements (cards, tiles).
class SbPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const SbPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<SbPressable> createState() => _SbPressableState();
}

class _SbPressableState extends State<SbPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabled) _controller.forward();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? widget.onTap : null,
              child: ScaleTransition(scale: _scale, child: widget.child),
            )
          : ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Fade-in entrance: fades + scales from 0.95 → 1.0 over 300ms.
///
/// Optional [delay] enables staggered list entrances.
class SbFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double fromScale;

  const SbFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.fromScale = 0.95,
  });

  @override
  State<SbFadeIn> createState() => _SbFadeInState();
}

class _SbFadeInState extends State<SbFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: widget.fromScale, end: 1.0));
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Subtle pulse animation for CTAs — gentle scale pulse, 2000ms cycle.
class SbPulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const SbPulse({
    super.key,
    required this.child,
    this.minScale = 0.98,
    this.maxScale = 1.02,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<SbPulse> createState() => _SbPulseState();
}

class _SbPulseState extends State<SbPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Three-dot wave loading indicator — 600ms per dot cycle.
class SbLoadingDots extends StatefulWidget {
  final double dotSize;
  final Color color;
  final Duration dotDuration;

  const SbLoadingDots({
    super.key,
    this.dotSize = 8,
    this.color = SbColors.activeBlue,
    this.dotDuration = const Duration(milliseconds: 600),
  });

  @override
  State<SbLoadingDots> createState() => _SbLoadingDotsState();
}

class _SbLoadingDotsState extends State<SbLoadingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: widget.dotDuration,
      );
    });
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the animations
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -8 * _animations[index].value),
              child: child,
            );
          },
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            margin: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.4),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

/// Soft route transition: slide + fade, 250ms.
///
/// Returns a [Page] for use with go_router `pageBuilder`.
Page<void> sbRouteTransition(Widget page) {
  return CustomTransitionPage<void>(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    child: page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(curved);
      final opacity = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curved);

      return FadeTransition(
        opacity: opacity,
        child: SlideTransition(
          position: offset,
          child: child,
        ),
      );
    },
  );
}

/// Typewriter text reveal: shows text character by character.
///
/// 50ms per character with a blinking cursor. Skippable with tap.
///
/// Usage:
/// ```dart
/// SbTypewriter(
///   text: 'Hello World',
///   style: TextStyle(fontSize: 24),
///   onComplete: () => print('done'),
/// )
/// ```
class SbTypewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;
  final bool skippable;

  const SbTypewriter({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 50),
    this.onComplete,
    this.skippable = true,
  });

  @override
  State<SbTypewriter> createState() => _SbTypewriterState();
}

class _SbTypewriterState extends State<SbTypewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _visibleChars = 0;
  bool _isComplete = false;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.charDuration * widget.text.length;
    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );
    _controller.addListener(_onTick);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    final newChars = (_controller.value * widget.text.length).floor();
    if (newChars != _visibleChars) {
      setState(() {
        _visibleChars = newChars;
      });
    }
    if (_controller.isCompleted && !_isComplete) {
      _isComplete = true;
      _showCursor = false;
      widget.onComplete?.call();
    }
  }

  void _skip() {
    if (!widget.skippable || _isComplete) return;
    _controller.stop();
    setState(() {
      _visibleChars = widget.text.length;
      _isComplete = true;
      _showCursor = false;
    });
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final displayedText = widget.text.substring(0, _visibleChars);

    return GestureDetector(
      onTap: _skip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayedText, style: widget.style),
          if (_showCursor && !_isComplete)
            _BlinkingCursor(style: widget.style),
        ],
      ),
    );
  }
}

/// Blinking cursor that appears during typewriter animation.
class _BlinkingCursor extends StatefulWidget {
  final TextStyle? style;

  const _BlinkingCursor({this.style});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _controller.addListener(() {
      setState(() {
        _visible = _controller.value > 0.5;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Text(
      '|',
      style: (widget.style ?? const TextStyle()).copyWith(
        color: (widget.style?.color ?? SbColors.primaryText)
            .withValues(alpha: 0.6),
        fontWeight: FontWeight.w100,
      ),
    );
  }
}
