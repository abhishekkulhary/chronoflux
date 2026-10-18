import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/neon_palette.dart';

/// Frosted pill button. [primary] gives it the phase gradient and a bloom;
/// the rest stay glass so the main action is never ambiguous.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.palette,
    this.primary = false,
    this.width,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PhasePalette? palette;
  final bool primary;
  final double? width;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? PhasePalette.focus;
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            // A small, quick squash gives the press a physical feel.
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: widget.width,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: widget.primary
                    ? LinearGradient(colors: [palette.start, palette.end])
                    : null,
                color: widget.primary ? null : NeonSurfaces.glassFill,
                border: Border.all(
                  color: widget.primary
                      ? Colors.white.withValues(alpha: 0.28)
                      : (_hovered
                          ? palette.glow.withValues(alpha: 0.55)
                          : NeonSurfaces.glassBorder),
                ),
                boxShadow: widget.primary && enabled
                    ? [
                        BoxShadow(
                          color: palette.glow
                              .withValues(alpha: _hovered ? 0.55 : 0.38),
                          blurRadius: _hovered ? 30 : 22,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Opacity(
                    opacity: enabled ? 1 : 0.4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: widget.primary
                                ? const Color(0xFF04060F)
                                : NeonSurfaces.textPrimary,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.icon == null ? 26 : 4,
                          ),
                          child: Text(
                            widget.label.toUpperCase(),
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: widget.primary
                                  ? const Color(0xFF04060F)
                                  : NeonSurfaces.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.icon != null) const SizedBox(width: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact circular glass button for secondary actions (reset, skip, settings).
class NeonIconButton extends StatelessWidget {
  const NeonIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.palette,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final PhasePalette? palette;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: NeonSurfaces.glassFill,
            shape: const CircleBorder(
              side: BorderSide(color: NeonSurfaces.glassBorder),
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  icon,
                  size: 22,
                  color: onPressed == null
                      ? NeonSurfaces.textFaint
                      : NeonSurfaces.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
