import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/neon_palette.dart';

/// Slow-drifting coloured haze behind everything else.
///
/// Painted as a handful of soft radial gradients rather than a blurred layer:
/// [BackdropFilter] over a full-screen animation is expensive on web and low-end
/// mobile, while radial falloff gives the same impression for almost nothing.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    required this.palette,
    this.intensity = 1,
    this.child,
  });

  final PhasePalette palette;

  /// Scales blob opacity: brighter while a session runs, dimmer when idle.
  final double intensity;

  final Widget? child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    // Deliberately long: the movement should be barely perceptible, never
    // something that pulls attention away from the work.
    duration: const Duration(seconds: 48),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, child) => CustomPaint(
          painter: _AuroraPainter(
            t: _drift.value,
            palette: widget.palette,
            intensity: widget.intensity,
          ),
          isComplex: true,
          willChange: true,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.palette,
    required this.intensity,
  });

  final double t;
  final PhasePalette palette;
  final double intensity;

  /// Each blob: colour source, relative radius, drift speed and phase offset.
  static const _blobs = [
    (0, 0.85, 1.0, 0.0),
    (1, 0.62, -0.7, 2.1),
    (2, 0.70, 0.45, 4.2),
    (0, 0.45, -1.3, 1.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = NeonSurfaces.canvas);

    final short = size.shortestSide;
    for (final (colorIndex, radiusFactor, speed, offset) in _blobs) {
      final angle = 2 * math.pi * (t * speed) + offset;
      final center = Offset(
        size.width * (0.5 + 0.34 * math.cos(angle)),
        size.height * (0.44 + 0.30 * math.sin(angle * 0.8 + offset)),
      );
      final radius = short * radiusFactor;

      final color = switch (colorIndex) {
        0 => palette.ambient,
        1 => palette.start,
        _ => palette.end,
      };

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.30 * intensity),
              color.withValues(alpha: 0.10 * intensity),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Vignette: pulls the eye back to the centre where the ring sits.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            NeonSurfaces.canvas.withValues(alpha: 0.75),
          ],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t != t || old.palette != palette || old.intensity != intensity;
}
