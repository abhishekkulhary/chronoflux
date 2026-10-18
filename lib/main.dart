import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/session_repository.dart';
import 'data/settings_repository.dart';
import 'features/timer/application/timer_providers.dart';
import 'services/notification_service.dart';
import 'services/window_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WindowService.configure();
  await Hive.initFlutter();

  // Opened up front so the providers can be synchronous, which lets the timer
  // screen build with restored state already in place — no loading flash.
  final settings = await SettingsRepository.open();
  final sessions = await SessionRepository.open();
  final notifications = await NotificationService.create();

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        sessionRepositoryProvider.overrideWithValue(sessions),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const ChronofluxApp(),
    ),
  );
}
