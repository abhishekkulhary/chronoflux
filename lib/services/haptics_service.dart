import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper that keeps platform checks out of the UI. Desktop and web have
/// no haptics, so every call is a no-op there.
abstract final class HapticsService {
  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Light tap for ordinary controls.
  static void tap() {
    if (_supported) HapticFeedback.selectionClick();
  }

  /// Heavier confirmation for start/pause.
  static void impact() {
    if (_supported) HapticFeedback.mediumImpact();
  }

  /// The end of an interval deserves to be felt, not just heard.
  static void complete() {
    if (_supported) HapticFeedback.heavyImpact();
  }
}
