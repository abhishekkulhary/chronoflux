import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronoflux/core/theme/neon_theme.dart';
import 'package:chronoflux/data/session_repository.dart';
import 'package:chronoflux/data/settings_repository.dart';
import 'package:chronoflux/features/history/history_screen.dart';
import 'package:chronoflux/features/settings/settings_screen.dart';
import 'package:chronoflux/features/timer/application/timer_providers.dart';
import 'package:chronoflux/features/timer/domain/session_phase.dart';
import 'package:chronoflux/features/timer/domain/session_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSessionStore implements SessionStore {
  FakeSessionStore([List<SessionRecord>? seed])
      : records = [...?seed];

  final List<SessionRecord> records;

  @override
  Future<void> add(SessionRecord record) async => records.add(record);

  @override
  List<SessionRecord> all() =>
      List.of(records)..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  @override
  List<SessionRecord> focusSessions() =>
      all().where((r) => r.phase == SessionPhase.focus).toList();

  @override
  Future<void> clear() async => records.clear();
}

// Note: these screens never reach a settled state — the aurora backdrop
// animates continuously — so the tests pump explicit frames rather than
// calling pumpAndSettle, which would time out.
void main() {
  late SettingsRepository settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsRepository.open();
  });

  Widget harness(Widget screen, {SessionStore? store}) => ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settings),
          sessionRepositoryProvider
              .overrideWithValue(store ?? FakeSessionStore()),
        ],
        child: MaterialApp(theme: NeonTheme.build(), home: screen),
      );

  group('settings', () {
    testWidgets('shows the current durations', (tester) async {
      await tester.pumpWidget(harness(const SettingsScreen()));
      await tester.pump();

      expect(find.text('25 min'), findsOneWidget); // focus
      expect(find.text('5 min'), findsOneWidget); // short break
      expect(find.text('15 min'), findsOneWidget); // long break
      expect(find.text('Auto-start breaks'), findsOneWidget);
    });

    testWidgets('toggling a switch persists the change', (tester) async {
      await tester.pumpWidget(harness(const SettingsScreen()));
      await tester.pump();

      // Auto-start focus is off by default; turning it on must survive a
      // reload of the repository. It sits below the fold, so scroll first.
      await tester.scrollUntilVisible(find.text('Auto-start focus'), 220);
      await tester.pump();

      final toggle = find.ancestor(
        of: find.text('Auto-start focus'),
        matching: find.byType(Row),
      );
      await tester.tap(
        find.descendant(of: toggle.first, matching: find.byType(Switch)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(settings.loadConfig().autoStartFocus, isTrue);
    });

    testWidgets('restore defaults puts the durations back', (tester) async {
      await settings.saveConfig(
        settings.loadConfig().copyWith(focusDuration: const Duration(minutes: 50)),
      );
      await tester.pumpWidget(harness(const SettingsScreen()));
      await tester.pump();
      expect(find.text('50 min'), findsOneWidget);

      await tester.tap(find.text('Restore defaults'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('25 min'), findsOneWidget);
      expect(settings.loadConfig().focusDuration, const Duration(minutes: 25));
    });
  });

  group('history', () {
    testWidgets('invites you to finish a session when empty', (tester) async {
      await tester.pumpWidget(harness(const HistoryScreen()));
      await tester.pump();

      expect(find.text('No sessions yet'), findsOneWidget);
      // Nothing to clear, so the destructive action is not offered.
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('summarises recorded focus sessions', (tester) async {
      final now = DateTime.now();
      final store = FakeSessionStore([
        SessionRecord(
          phase: SessionPhase.focus,
          length: const Duration(minutes: 25),
          endedAt: now.subtract(const Duration(hours: 2)),
        ),
        SessionRecord(
          phase: SessionPhase.focus,
          length: const Duration(minutes: 25),
          endedAt: now.subtract(const Duration(hours: 1)),
        ),
        // Breaks are recorded but must not count as focus time.
        SessionRecord(
          phase: SessionPhase.shortBreak,
          length: const Duration(minutes: 5),
          endedAt: now.subtract(const Duration(minutes: 90)),
        ),
      ]);

      await tester.pumpWidget(
        harness(const HistoryScreen(), store: store),
      );
      await tester.pump();

      expect(find.text('2'), findsWidgets); // session count
      expect(find.text('50m'), findsOneWidget); // focused time, breaks excluded
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}
