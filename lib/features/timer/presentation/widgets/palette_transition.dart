import 'package:flutter/material.dart';

import '../../../../core/theme/neon_palette.dart';

class PhasePaletteTween extends Tween<PhasePalette> {
  PhasePaletteTween({super.begin, super.end});

  @override
  PhasePalette lerp(double t) => PhasePalette.lerp(begin!, end!, t);
}

/// Glides the whole interface between phase colours instead of snapping, so
/// finishing a session reads as a transition rather than a jump cut.
class PaletteTransition extends StatelessWidget {
  const PaletteTransition({
    super.key,
    required this.palette,
    required this.builder,
  });

  final PhasePalette palette;
  final Widget Function(BuildContext context, PhasePalette palette) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<PhasePalette>(
        tween: PhasePaletteTween(begin: palette, end: palette),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOut,
        builder: (context, value, _) => builder(context, value),
      );
}
