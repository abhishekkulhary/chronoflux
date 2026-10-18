import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoflux/data/session_repository.dart';
import 'package:chronoflux/data/settings_repository.dart';
import 'package:chronoflux/features/timer/domain/session_phase.dart';
import 'package:chronoflux/features/timer/domain/session_record.dart';
import 'package:chronoflux/features/timer/application/ticker.dart';
import 'package:chronoflux/features/timer/application/timer_providers.dart';
import 'package:chronoflux/features/timer/presentation/timer_screen.dart';
import 'package:chronoflux/core/theme/neon_theme.dart';
import 'package:chronoflux/services/notification_service.dart';
import 'package:chronoflux/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the widget tests off the audio platform channels.
class SilentSound extends SoundService {
  @override
  Future<void> playFor(_) async {}
}

/// In-memory history, so widget tests never touch the disk. Real file IO does
/// not resolve under the fake async a widget test runs in.
class FakeSessionStore implements SessionStore {
  final List<SessionRecord> records = [];

  @override
  Future<void> add(SessionRecord record) async => records.add(record);

  @override
  List<SessionRecord> all() => List.of(records.reversed);

  @override
  List<SessionRecord> focusSessions() =>
      all().where((r) => r.phase == SessionPhase.focus).toList();

  @override
  Future<void> clear() async => records.clear();
}

void main() {
  late SettingsRepository settings;
  late FakeSessionStore sessions;
  late FakeClock clock;
  late FakeTicker ticker;

  final t0 = DateTime(2026, 3, 2, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsRepository.open();
    sessions = FakeSessionStore();
    clock = FakeClock(t0);
    ticker = FakeTicker();
  });

  Widget harness() => ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          sessionRepositoryProvider.overrideWithValue(sessions),
          // Never initialised, so every notification call is an inert no-op.
          notificationServiceProvider.overrideWithValue(
            NotificationService(FlutterLocalNotificationsPlugin()),
          ),
          soundServiceProvider.overrideWith((ref) => SilentSound()),
          clockProvider.overrideWithValue(clock),
          tickerProvider.overrideWithValue(ticker),
        ],
        child: MaterialApp(
          theme: NeonTheme.build(),
          home: const TimerScreen(),
        ),
      );

  testWidgets('opens on a full focus interval', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('FOCUS'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('starting counts down against the clock', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.text('PAUSE'), findsOneWidget);

    clock.advance(const Duration(minutes: 3));
    ticker.pump();
    await tester.pump();

    expect(find.text('22:00'), findsOneWidget);
  });

  testWidgets('a finished focus session advances the UI to the break',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    await tester.tap(find.text('START'));
    await tester.pump();

    // The whole interval elapses while only one tick is delivered — the shape
    // of a suspended app or a throttled tab.
    clock.advance(const Duration(minutes: 25));
    ticker.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('BREAK'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    // Breaks auto-start by default, so it is already counting.
    expect(find.text('PAUSE'), findsOneWidget);
    expect(sessions.focusSessions(), hasLength(1));
  });

  testWidgets('pause freezes the display', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(minutes: 5));
    ticker.pump();
    await tester.pump();

    await tester.tap(find.text('PAUSE'));
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);

    clock.advance(const Duration(hours: 2));
    await tester.pump();
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
  });

  testWidgets('skip moves to the next phase without recording a session',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    await tester.tap(find.byTooltip('Skip to next phase (S)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('BREAK'), findsOneWidget);
    expect(sessions.focusSessions(), isEmpty);
  });

  group('layout', () {
    // The Start button falling below the fold on a short window is an easy
    // regression to introduce and an easy one to miss by only testing phones.
    const viewports = <String, Size>{
      'small phone': Size(360, 640),
      'phone': Size(375, 812),
      'short desktop window': Size(800, 740),
      'wide desktop': Size(1400, 900),
      'very short window': Size(900, 560),
      'extremely short window': Size(900, 460),
    };

    for (final entry in viewports.entries) {
      testWidgets('keeps the primary control on screen: ${entry.key}',
          (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = entry.value;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(harness());
        await tester.pump();

        final start = find.text('START');
        expect(start, findsOneWidget);

        final rect = tester.getRect(start);
        expect(rect.bottom, lessThanOrEqualTo(entry.value.height),
            reason: 'Start button is below the fold on ${entry.key}');
        expect(rect.top, greaterThanOrEqualTo(0.0));
        expect(rect.right, lessThanOrEqualTo(entry.value.width));

        // The countdown is the whole point of the screen; it must be visible
        // too, not squeezed out by the controls.
        final clock = tester.getRect(find.text('25:00'));
        expect(clock.top, greaterThanOrEqualTo(0.0));
        expect(clock.bottom, lessThanOrEqualTo(entry.value.height));
      });
    }
  });
}
