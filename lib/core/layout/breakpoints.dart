import 'package:flutter/widgets.dart';

/// Three layout bands, shared by every screen.
enum LayoutSize { compact, medium, expanded }

extension LayoutSizing on BuildContext {
  LayoutSize get layoutSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 600) return LayoutSize.compact;
    if (w < 1000) return LayoutSize.medium;
    return LayoutSize.expanded;
  }

  bool get isCompact => layoutSize == LayoutSize.compact;

  /// At this width the timer and a side panel sit comfortably side by side.
  bool get isWide => layoutSize == LayoutSize.expanded;
}
