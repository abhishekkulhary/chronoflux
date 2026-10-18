
import 'package:flutter/material.dart';

import 'neon_palette.dart';

/// Orbitron for numerals and display text, Rajdhani for everything else.
/// Orbitron ships as a variable font, so weights come from [FontVariation]
/// rather than from separate asset files.
abstract final class AppTypography {
  static const display = 'Orbitron';
  static const body = 'Rajdhani';

  static List<FontVariation> _wght(double w) => [FontVariation('wght', w)];

  /// The clock face. Tabular figures stop the layout jittering as digits
  /// change — without them the countdown visibly twitches every second.
  static TextStyle clock(double size) => TextStyle(
        fontFamily: display,
        fontSize: size,
        height: 1,
        fontVariations: _wght(600),
        letterSpacing: size * 0.02,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: NeonSurfaces.textPrimary,
      );

  static TextStyle displaySmall(double size, {double weight = 600}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontVariations: _wght(weight),
        letterSpacing: 1.2,
        color: NeonSurfaces.textPrimary,
      );

  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontFamily: body,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: NeonSurfaces.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: body,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: NeonSurfaces.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: body,
      fontSize: 17,
      color: NeonSurfaces.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: body,
      fontSize: 15,
      color: NeonSurfaces.textSecondary,
    ),
    bodySmall: TextStyle(
      fontFamily: body,
      fontSize: 13,
      color: NeonSurfaces.textFaint,
    ),
    labelLarge: TextStyle(
      fontFamily: body,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: NeonSurfaces.textPrimary,
    ),
  );

  /// Spaced-out uppercase used for phase labels and section headers.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.4,
    color: NeonSurfaces.textSecondary,
  );
}
