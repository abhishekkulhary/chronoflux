import 'package:flutter/material.dart';

import '../../../../core/theme/neon_palette.dart';

/// One dot per focus session in the current set; filled dots are done.
/// Shows at a glance how close the long break is.
class CycleDots extends StatelessWidget {
  const CycleDots({
    super.key,
    required this.completed,
    required this.total,
    required this.palette,
  });

  final int completed;
  final int total;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$completed of $total focus sessions complete in this set',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final done = i < completed;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: done ? 26 : 9,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: done
                  ? palette.glow
                  : Colors.white.withValues(alpha: 0.16),
              boxShadow: done
                  ? [
                      BoxShadow(
                        color: palette.glow.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
