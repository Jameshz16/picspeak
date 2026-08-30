import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

/// Neo-Brutalism animation library.
///
/// These widgets mirror the hard, snappy, physical feel of the Stitch
/// "PicSpeak Neo-Brutalism" screens: elements sink into the page when
/// pressed (hard shadow shrinks), pop in with a bounce, and bounce
/// indefinitely when they need attention.

/// Signature neo-brutalism press effect: on tap-down the child sinks
/// 2px down and its hard shadow shrinks from 4px to 2px; on release it
/// snaps back. Wraps any widget (buttons, cards, tiles).
///
/// The press animation is driven by raw pointer events ([Listener]), so
/// it works even when the child (e.g. an [ElevatedButton]) handles its
/// own tap. Pass [onTap] only for widgets that have no tap handler of
/// their own (cards, tiles).
class NbPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const NbPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<NbPressable> createState() => _NbPressableState();
}

class _NbPressableState extends State<NbPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _press;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _press = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
    final press = _press.value;

    final animated = AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        // Shadow offset shrinks as the element sinks down.
        final shadowOffset = 4.0 - (2.0 * press);
        return Transform.translate(
          offset: Offset(2 * press, 2 * press),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NbRadius.xs),
              boxShadow: [
                BoxShadow(
                  color: NbColors.outline,
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? widget.onTap : null,
              child: animated,
            )
          : animated,
    );
  }
}

/// Pop-in entrance: fades in and scales from 0.9 → 1.0 with a bouncy
/// overshoot. Optional [delay] enables staggered list entrances.
class NbPopIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double fromScale;

  const NbPopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.fromScale = 0.9,
  });

  @override
  State<NbPopIn> createState() => _NbPopInState();
}

class _NbPopInState extends State<NbPopIn>
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
      curve: Curves.easeOutBack,
    ).drive(
      Tween(begin: widget.fromScale, end: 1.0),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ).drive(
      Tween(begin: 0.0, end: 1.0),
    );

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

/// Infinite bounce for attention-grabbing CTAs and decorative elements.
class NbBounce extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;

  const NbBounce({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<NbBounce> createState() => _NbBounceState();
}

class _NbBounceState extends State<NbBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _offset = CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        final dy = -widget.amplitude * _offset.value;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Neo-brutalist loading block: a hard-shadow square that jumps and
/// lands with a bounce, replacing generic circular spinners.
class NbLoadingBlock extends StatefulWidget {
  final double size;
  final Color color;

  const NbLoadingBlock({
    super.key,
    this.size = 32,
    this.color = NbColors.primary,
  });

  @override
  State<NbLoadingBlock> createState() => _NbLoadingBlockState();
}

class _NbLoadingBlockState extends State<NbLoadingBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Jump: rises during first third, falls with bounce.
        final t = _controller.value;
        final phase = (t * 3).clamp(0.0, 1.0);
        final dy = -28 * Curves.easeOut.transform(
              (phase * 1.4).clamp(0.0, 1.0),
            ) +
            28 * Curves.bounceOut.transform((phase * 1.4 - 0.3).clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(NbRadius.xs),
          border: Border.all(color: NbColors.outline, width: 2),
          boxShadow: const [
            BoxShadow(
              color: NbColors.outline,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hard neo-brutalist route transition: the incoming page slides in
/// from the right with a slight overshoot while the outgoing page
/// slides out left. Snappy (240ms). Returns a [Page] so it can be used
/// directly as a go_router `pageBuilder`.
Page<void> nbHardRouteTransition(Widget page) {
  return CustomTransitionPage<void>(
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    child: page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved);
      final secondary = Tween<double>(
        begin: 0.0,
        end: 0.2,
      ).animate(secondaryAnimation);

      return SlideTransition(
        position: offset,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.2, 0),
          ).animate(secondary),
          child: child,
        ),
      );
    },
  );
}

/// Typewriter text reveal: shows text character by character with a
/// blinking cursor. Skippable with tap. Fast by default (300ms).
///
/// Usage:
/// ```dart
/// NbTypewriter(
///   text: 'Hello World',
///   style: TextStyle(fontSize: 24),
///   onComplete: () => print('done'),
/// )
/// ```
class NbTypewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool skippable;

  const NbTypewriter({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 300),
    this.onComplete,
    this.skippable = true,
  });

  @override
  State<NbTypewriter> createState() => _NbTypewriterState();
}

class _NbTypewriterState extends State<NbTypewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _visibleChars = 0;
  bool _isComplete = false;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
          Text(
            displayedText,
            style: widget.style,
          ),
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
      duration: const Duration(milliseconds: 500),
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
        color: (widget.style?.color ?? Colors.black).withValues(alpha: 0.6),
        fontWeight: FontWeight.w100,
      ),
    );
  }
}