import 'dart:io' show Platform;

import 'dart:ui' show Color, Size;

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window setup. Guarded so mobile and web never touch window_manager,
/// which has no implementation there.
abstract final class WindowService {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static Future<void> configure() async {
    if (!isDesktop) return;
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 760),
      // Below this the ring and the side panel stop coexisting comfortably.
      minimumSize: Size(420, 620),
      center: true,
      title: 'Chronoflux',
      backgroundColor: Color(0xFF04060F),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
