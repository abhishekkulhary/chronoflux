import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'neon_palette.dart';

abstract final class NeonTheme {
  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF22E1FF),
      secondary: Color(0xFFFF4FD8),
      surface: NeonSurfaces.canvasElevated,
      onSurface: NeonSurfaces.textPrimary,
      error: NeonSurfaces.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NeonSurfaces.canvas,
      canvasColor: NeonSurfaces.canvas,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.body,
      // The aurora backdrop supplies all the depth; opaque bars would cover it.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: NeonSurfaces.textPrimary,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: NeonSurfaces.canvasElevated,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: NeonSurfaces.glassBorder,
        thumbColor: Colors.white,
        overlayColor: scheme.primary.withValues(alpha: 0.16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : NeonSurfaces.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.55)
              : NeonSurfaces.glassFill,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll(NeonSurfaces.glassBorder),
      ),
      dividerTheme: const DividerThemeData(
        color: NeonSurfaces.glassBorder,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: NeonSurfaces.canvasElevated,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(
          fontFamily: AppTypography.body,
          color: NeonSurfaces.textPrimary,
          fontSize: 13,
        ),
      ),
    );
  }
}
