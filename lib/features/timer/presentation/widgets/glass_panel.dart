import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/neon_palette.dart';

/// Frosted panel: blurs whatever aurora sits behind it, then lays a translucent
/// fill and a hairline border over the top.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.strong = false,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Slightly more opaque, for panels that carry dense content.
  final bool strong;

  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        color: strong ? NeonSurfaces.glassFillStrong : NeonSurfaces.glassFill,
        border: Border.all(
          color: borderColor ?? NeonSurfaces.glassBorder,
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    return ClipRRect(
      borderRadius: border,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: NeonSurfaces.glassBlur,
          sigmaY: NeonSurfaces.glassBlur,
        ),
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: border,
                  child: content,
                ),
              ),
      ),
    );
  }
}
