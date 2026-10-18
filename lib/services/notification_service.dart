import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/timer/domain/session_phase.dart';

/// Schedules the end-of-interval alert with the operating system.
///
/// Deliberately *not* fired by the in-app timer: the process may well be
/// suspended when the interval ends, and an alert you only get if the app
/// happens to be awake is worse than none. Scheduling ahead means the OS
/// delivers it either way, and the app cancels it if you pause first.
class NotificationService {
  NotificationService(this._plugin);

  static const _alertId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;
  bool _permitted = false;

  bool get canNotify => _ready && _permitted;

  static Future<NotificationService> create() async {
    final service = NotificationService(FlutterLocalNotificationsPlugin());
    await service._init();
    return service;
  }

  static const _initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    // Permission is requested on first start, not at launch, so the prompt
    // arrives when its purpose is obvious.
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
    macOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
    linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    windows: WindowsInitializationSettings(
      appName: 'Chronoflux',
      appUserModelId: 'com.abhishek.pomodoroTimers',
      guid: '6d6f4d43-3a0e-4f3a-9d2b-1f7c8ba4e510',
    ),
    web: WebInitializationSettings(),
  );

  Future<void> _init() async {
    try {
      tzdata.initializeTimeZones();
      // tz.local defaults to UTC, which is fine: alerts are scheduled from
      // absolute instants, and an instant is the same moment in any zone.

      // On web, initialize() is what raises the browser permission prompt, so
      // it is deferred to requestPermission() instead of running at launch.
      if (!kIsWeb) {
        await _plugin.initialize(settings: _initSettings);
      }
      _ready = true;
    } catch (error, stack) {
      // A missing notification backend must never stop the timer working.
      debugPrint('Notifications unavailable: $error\n$stack');
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready || _permitted) return _permitted;
    try {
      if (kIsWeb) {
        _permitted = await _plugin.initialize(settings: _initSettings) ?? false;
      } else if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        _permitted = await android?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        _permitted =
            await ios?.requestPermissions(alert: true, sound: true) ?? false;
      } else if (Platform.isMacOS) {
        final macos = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        _permitted =
            await macos?.requestPermissions(alert: true, sound: true) ?? false;
      } else {
        _permitted = true; // Linux and Windows do not gate this.
      }
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      _permitted = false;
    }
    return _permitted;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pomodoro_intervals',
      'Interval alerts',
      channelDescription: 'Tells you when a focus session or break ends.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    linux: LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical),
  );

  Future<void> scheduleCompletion({
    required SessionPhase phase,
    required DateTime endsAt,
  }) async {
    if (!canNotify) return;
    await cancelAll();

    final (title, body) = switch (phase) {
      SessionPhase.focus => ('Focus complete', 'Nice work — time for a break.'),
      SessionPhase.shortBreak => ('Break over', 'Ready for the next session?'),
      SessionPhase.longBreak => ('Long break over', 'Back when you are ready.'),
    };

    final when = tz.TZDateTime.from(endsAt, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id: _alertId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Could not schedule notification: $error');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _alertId);
    } catch (error) {
      debugPrint('Could not cancel notification: $error');
    }
  }
}
