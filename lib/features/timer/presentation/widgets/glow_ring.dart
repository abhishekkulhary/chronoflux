import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/neon_palette.dart';

/// The circular progress indicator: a dim track, a lit arc that sweeps through
/// the phase gradient, a soft bloom beneath it, and a bright head at the tip.
class GlowRing extends StatelessWidget {
  const GlowRing({
    super.key,
    required this.progress,
    required this.palette,
    this.pulse = 0,
    this.strokeWidth = 14,
    this.child,
  });

  /// 0 at the start of the interval, 1 at the end.
  final double progress;

  final PhasePalette palette;

  /// 0..1 breathing value; widens the bloom slightly while running so the ring
  /// reads as alive rather than a static gauge.
  final double pulse;

  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowRingPainter(
        progress: progress.clamp(0.0, 1.0),
        palette: palette,
        pulse: pulse,
        strokeWidth: strokeWidth,
      ),
      child: Center(child: child),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  _GlowRingPainter({
    required this.progress,
    required this.palette,
    required this.pulse,
    required this.strokeWidth,
  });

  final double progress;
  final PhasePalette palette;
  final double pulse;
  final double strokeWidth;

  /// Twelve o'clock, so the sweep starts where people expect a clock to.
  static const _startAngle = -math.pi / 2;
  static const _tickCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * progress;

    _paintTicks(canvas, center, radius);

    // Track: the unlit remainder of the circle.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    if (progress <= 0) return;

    final shader = SweepGradient(
      startAngle: _startAngle,
      endAngle: _startAngle + 2 * math.pi,
      colors: [palette.start, palette.end, palette.start],
      stops: const [0, 0.65, 1],
      transform: GradientRotation(_startAngle),
    ).createShader(rect);

    // Bloom first, so the crisp arc sits on top of its own halo.
    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round
        ..color = palette.glow.withValues(alpha: 0.30 + 0.16 * pulse)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          14 + 8 * pulse,
        ),
    );

    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    _paintHead(canvas, center, radius, sweep);
  }

  /// Minute ticks around the dial; the ones already passed light up.
  void _paintTicks(Canvas canvas, Offset center, double radius) {
    final tickRadius = radius + strokeWidth * 0.5 + 9;
    final passed = (progress * _tickCount).floor();
    for (var i = 0; i < _tickCount; i++) {
      final angle = _startAngle + 2 * math.pi * (i / _tickCount);
      final isMajor = i % 5 == 0;
      final length = isMajor ? 7.0 : 3.5;
      final lit = progress > 0 && i <= passed;

      final outer = Offset(
        center.dx + math.cos(angle) * tickRadius,
        center.dy + math.sin(angle) * tickRadius,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (tickRadius - length),
        center.dy + math.sin(angle) * (tickRadius - length),
      );

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = isMajor ? 2 : 1
          ..strokeCap = StrokeCap.round
          ..color = lit
              ? palette.glow.withValues(alpha: isMajor ? 0.85 : 0.55)
              : Colors.white.withValues(alpha: isMajor ? 0.16 : 0.08),
      );
    }
  }

  /// Bright dot riding the leading edge of the arc.
  void _paintHead(Canvas canvas, Offset center, double radius, double sweep) {
    final angle = _startAngle + sweep;
    final head = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    canvas.drawCircle(
      head,
      strokeWidth * 0.95,
      Paint()
        ..color = palette.glow.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 6 * pulse),
    );
    canvas.drawCircle(
      head,
      strokeWidth * 0.34,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) =>
      old.progress != progress ||
      old.palette != palette ||
      old.pulse != pulse ||
      old.strokeWidth != strokeWidth;
}
