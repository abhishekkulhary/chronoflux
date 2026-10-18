import 'package:flutter/material.dart';

import '../../features/timer/domain/session_phase.dart';

/// The accent ramp for one phase. Every glowing element on screen — ring,
/// bloom, buttons, ambient blobs — pulls from here, so advancing the cycle
/// re-tints the whole interface at once.
class PhasePalette {
  const PhasePalette({
    required this.start,
    required this.end,
    required this.glow,
    required this.ambient,
  });

  /// Sweep-gradient endpoints for the progress arc.
  final Color start;
  final Color end;

  /// Colour of the outer bloom around lit elements.
  final Color glow;

  /// Tint of the drifting background blobs.
  final Color ambient;

  Gradient get sweep => LinearGradient(colors: [start, end]);

  static PhasePalette of(SessionPhase phase) => switch (phase) {
        SessionPhase.focus => focus,
        SessionPhase.shortBreak => shortBreak,
        SessionPhase.longBreak => longBreak,
      };

  /// Cool and electric — reads as "switched on".
  static const focus = PhasePalette(
    start: Color(0xFF22E1FF),
    end: Color(0xFF4C6BFF),
    glow: Color(0xFF22E1FF),
    ambient: Color(0xFF1B4BFF),
  );

  /// Green-mint, unmistakably not the focus colour at a glance.
  static const shortBreak = PhasePalette(
    start: Color(0xFF5FFFC9),
    end: Color(0xFF14C7A8),
    glow: Color(0xFF5FFFC9),
    ambient: Color(0xFF0FA88F),
  );

  /// The reward colour: richer and warmer than either working state.
  static const longBreak = PhasePalette(
    start: Color(0xFFFF4FD8),
    end: Color(0xFF8B5CFF),
    glow: Color(0xFFFF6BE0),
    ambient: Color(0xFF7B3BFF),
  );

  /// Interpolate between palettes so phase changes glide rather than snap.
  static PhasePalette lerp(PhasePalette a, PhasePalette b, double t) =>
      PhasePalette(
        start: Color.lerp(a.start, b.start, t)!,
        end: Color.lerp(a.end, b.end, t)!,
        glow: Color.lerp(a.glow, b.glow, t)!,
        ambient: Color.lerp(a.ambient, b.ambient, t)!,
      );
}

/// Fixed surface colours. The canvas stays near-black at every phase so the
/// neon has something to burn against.
abstract final class NeonSurfaces {
  static const canvas = Color(0xFF04060F);
  static const canvasElevated = Color(0xFF080C1A);

  /// Frosted panel fill and hairline border, layered over the blurred canvas.
  static const glassFill = Color(0x14FFFFFF);
  static const glassFillStrong = Color(0x1FFFFFFF);
  static const glassBorder = Color(0x24FFFFFF);

  static const textPrimary = Color(0xFFEAF2FF);
  static const textSecondary = Color(0xFF93A4C4);
  static const textFaint = Color(0xFF5D6C8A);

  static const danger = Color(0xFFFF5C7A);

  /// Blur radius for frosted panels.
  static const glassBlur = 18.0;
}
