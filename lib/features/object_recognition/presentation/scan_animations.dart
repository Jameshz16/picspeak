import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Neo-Brutalism scanning line that sweeps top → bottom over the photo,
/// mirroring the `scan` keyframe from the Stitch "Reconocimiento" screen:
/// 0% top: 0 → 50% top: 100% → 100% top: 0, 3s ease-in-out infinite.
class ScanLineOverlay extends StatefulWidget {
  /// Height of the sweeping line.
  final double lineHeight;

  /// Duration of one full sweep (down and back).
  final Duration duration;

  const ScanLineOverlay({
    super.key,
    this.lineHeight = 3,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    // 0 → 1 → 0, matching the CSS keyframe (down then back up).
    _progress = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxTop = constraints.maxHeight - widget.lineHeight;
              final top = _progress.value * maxTop;
              return Stack(
                children: [
                  Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: widget.lineHeight,
                      decoration: BoxDecoration(
                        color: NbColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: NbColors.primary.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Floating elevation effect that mirrors the `float` keyframe from the
/// Stitch "Reconocimiento" screen: translateY 0 → -10px → 0, 3s infinite.
class FloatingLabel extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final Duration delay;

  const FloatingLabel({
    super.key,
    required this.child,
    this.amplitude = 10,
    this.duration = const Duration(seconds: 3),
    this.delay = Duration.zero,
  });

  @override
  State<FloatingLabel> createState() => _FloatingLabelState();
}

class _FloatingLabelState extends State<FloatingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.repeat();
      });
    } else {
      _controller.repeat();
    }
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        final dy = -widget.amplitude * math.sin(_offset.value * math.pi);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}