import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timers/features/timer/application/pomodoro_engine.dart';
import 'package:pomodoro_timers/features/timer/application/session_effects.dart';
import 'package:pomodoro_timers/features/timer/application/ticker.dart';
import 'package:pomodoro_timers/features/timer/domain/pomodoro_config.dart';
import 'package:pomodoro_timers/features/timer/domain/session_phase.dart';
import 'package:pomodoro_timers/features/timer/domain/timer_status.dart';

class RecordingEffects implements SessionEffects {
  final List<({SessionPhase phase, DateTime endsAt})> scheduled = [];
  final List<({SessionPhase phase, Duration length, DateTime endedAt})> recorded = [];
  final List<({SessionPhase phase, bool fresh})> announced = [];
  int cancels = 0;

  @override
  void scheduleCompletionAlert({
    required SessionPhase phase,
    required DateTime endsAt,
  }) =>
      scheduled.add((phase: phase, endsAt: endsAt));

  @override
  void cancelCompletionAlerts() => cancels++;

  @override
  void announceCompletion(SessionPhase completed, {required bool fresh}) =>
      announced.add((phase: completed, fresh: fresh));

  @override
  void recordSession({
    required SessionPhase phase,
    required Duration length,
    required DateTime endedAt,
  }) =>
      recorded.add((phase: phase, length: length, endedAt: endedAt));
}

void main() {
  final t0 = DateTime(2026, 1, 1, 9);
  const config = PomodoroConfig(
    focusDuration: Duration(minutes: 25),
    shortBreakDuration: Duration(minutes: 5),
    longBreakDuration: Duration(minutes: 15),
    sessionsBeforeLongBreak: 4,
  );

  late FakeClock clock;
  late FakeTicker ticker;
  late RecordingEffects effects;

  PomodoroEngine build([PomodoroConfig cfg = config]) => PomodoroEngine(
        config: cfg,
        clock: clock,
        ticker: ticker,
        effects: effects,
      );

  setUp(() {
    clock = FakeClock(t0);
    ticker = FakeTicker();
    effects = RecordingEffects();
  });

  group('basics', () {
    test('starts idle on a full focus interval', () {
      final e = build();
      expect(e.state.phase, SessionPhase.focus);
      expect(e.state.status, TimerStatus.idle);
      expect(e.state.remaining, const Duration(minutes: 25));
      expect(e.state.progress, 0);
    });

    test('start anchors an absolute endsAt and schedules the OS alert', () {
      final e = build()..start();
      expect(e.state.status, TimerStatus.running);
      expect(e.state.endsAt, t0.add(const Duration(minutes: 25)));
      expect(effects.scheduled.single.phase, SessionPhase.focus);
      expect(effects.scheduled.single.endsAt, t0.add(const Duration(minutes: 25)));
    });

    test('remaining is derived from the clock, not decremented per tick', () {
      final e = build()..start();
      // Ten minutes of real time pass but only a single tick is delivered.
      clock.advance(const Duration(minutes: 10));
      ticker.pump();
      expect(e.state.remaining, const Duration(minutes: 15));

      // Many ticks with no time passing must not advance the countdown.
      for (var i = 0; i < 50; i++) {
        ticker.pump();
      }
      expect(e.state.remaining, const Duration(minutes: 15));
    });

    test('pause freezes remaining and cancels the pending alert', () {
      final e = build()..start();
      clock.advance(const Duration(minutes: 4));
      e.pause();

      expect(e.state.status, TimerStatus.paused);
      expect(e.state.remaining, const Duration(minutes: 21));
      expect(e.state.endsAt, isNull);
      expect(effects.cancels, 1);

      // Time passing while paused must not consume the interval.
      clock.advance(const Duration(hours: 3));
      expect(e.state.remaining, const Duration(minutes: 21));
    });

    test('resuming after a pause re-anchors from the moment of resume', () {
      final e = build()..start();
      clock.advance(const Duration(minutes: 4));
      e.pause();
      clock.advance(const Duration(hours: 3));
      e.start();

      expect(e.state.endsAt, clock.now().add(const Duration(minutes: 21)));
    });

    test('reset restores the full interval', () {
      final e = build()..start();
      clock.advance(const Duration(minutes: 4));
      e.reset();
      expect(e.state.status, TimerStatus.idle);
      expect(e.state.remaining, const Duration(minutes: 25));
      expect(e.state.endsAt, isNull);
    });
  });

  group('cycle', () {
    test('a long break replaces the short one after the 4th focus', () {
      final e = build();
      final seen = <SessionPhase>[];

      // Run eight intervals: focus/break alternating through a full set.
      for (var i = 0; i < 8; i++) {
        seen.add(e.state.phase);
        e.start();
        clock.advance(e.state.remaining + const Duration(seconds: 1));
        ticker.pump();
      }

      expect(seen, [
        SessionPhase.focus,
        SessionPhase.shortBreak,
        SessionPhase.focus,
        SessionPhase.shortBreak,
        SessionPhase.focus,
        SessionPhase.shortBreak,
        SessionPhase.focus,
        SessionPhase.longBreak,
      ]);
      // The long break closes the set and the counter starts over.
      expect(e.state.phase, SessionPhase.focus);
      expect(e.state.focusCompletedInCycle, 0);
      expect(e.state.completedToday, 4);
    });

    test('skip advances without counting or recording the session', () {
      final e = build()..start();
      e.skip();
      expect(e.state.phase, SessionPhase.shortBreak);
      expect(e.state.status, TimerStatus.idle);
      expect(e.state.completedToday, 0);
      expect(effects.recorded, isEmpty);
    });

    test('only focus sessions are counted toward the daily tally', () {
      final e = build(const PomodoroConfig(
        focusDuration: Duration(minutes: 1),
        shortBreakDuration: Duration(minutes: 1),
      ));
      e.start();
      // Stop mid-break: far enough to finish the focus, not the break.
      clock.advance(const Duration(seconds: 90));
      ticker.pump();
      expect(e.state.completedToday, 1);
      expect(e.state.phase, SessionPhase.shortBreak);
    });
  });

  group('suspension', () {
    test('a gap with no ticks still completes the interval on the next look', () {
      // Auto-start off, so exactly one interval can come due.
      final e = build(const PomodoroConfig(autoStartBreaks: false))..start();

      // The app is suspended: the clock moves well past endsAt, no ticks fire.
      clock.advance(const Duration(minutes: 40));
      expect(e.state.remaining, const Duration(minutes: 25),
          reason: 'state is stale until something observes the clock');

      e.sync(); // what an app-resume triggers
      expect(e.state.phase, SessionPhase.shortBreak);
      expect(effects.recorded.single.phase, SessionPhase.focus);
    });

    test('a long gap replays every interval that elapsed, on the real timeline',
        () {
      // Both auto-starts on, so the cycle would have kept moving unattended.
      final e = build(const PomodoroConfig(
        focusDuration: Duration(minutes: 25),
        shortBreakDuration: Duration(minutes: 5),
        sessionsBeforeLongBreak: 4,
        autoStartBreaks: true,
        autoStartFocus: true,
      ))
        ..start();

      // Away 58m: focus(25) + break(5) + focus(25) = 55m elapse, landing
      // three minutes into the second short break.
      clock.advance(const Duration(minutes: 58));
      e.sync();

      expect(effects.recorded.map((r) => r.phase).toList(), [
        SessionPhase.focus,
        SessionPhase.shortBreak,
        SessionPhase.focus,
      ]);
      expect(e.state.phase, SessionPhase.shortBreak);
      expect(e.state.completedToday, 2);
      // The second break started at 55m and runs to 60m: two minutes left.
      expect(e.state.remaining, const Duration(minutes: 2));

      // Sessions are recorded against when they actually ended, not on return.
      expect(effects.recorded.first.endedAt, t0.add(const Duration(minutes: 25)));
    });

    test('a completion discovered late is not announced as fresh', () {
      final e = build(const PomodoroConfig(autoStartBreaks: false))..start();
      clock.advance(const Duration(minutes: 30));
      e.sync();
      expect(effects.announced.single.fresh, isFalse);
    });

    test('a completion caught as it happens is announced as fresh', () {
      build().start();
      clock.advance(const Duration(minutes: 25));
      ticker.pump();
      expect(effects.announced.single.fresh, isTrue);
    });

    test('catch-up is bounded when the system clock jumps absurdly far', () {
      final e = build(const PomodoroConfig(
        focusDuration: Duration(minutes: 1),
        shortBreakDuration: Duration(minutes: 1),
        autoStartBreaks: true,
        autoStartFocus: true,
      ))
        ..start();

      clock.advance(const Duration(days: 365));
      e.sync(); // must terminate rather than spin
      expect(effects.recorded.length, lessThanOrEqualTo(100));
    });
  });

  group('restore', () {
    test('a session running at cold start resumes against the wall clock', () {
      final first = build()..start();
      final saved = first.state;

      // Process dies; six minutes later the app is relaunched.
      clock.advance(const Duration(minutes: 6));
      final revived = build()..restore(saved);

      expect(revived.state.status, TimerStatus.running);
      expect(revived.state.remaining, const Duration(minutes: 19));
    });

    test('a session that ended while the app was dead completes on restore', () {
      final first = build()..start();
      final saved = first.state;

      clock.advance(const Duration(minutes: 26));
      final revived = build()..restore(saved);

      expect(revived.state.phase, SessionPhase.shortBreak);
    });
  });

  group('config changes', () {
    test('editing a duration re-lengths the current interval when idle', () {
      final e = build();
      e.updateConfig(config.copyWith(focusDuration: const Duration(minutes: 50)));
      expect(e.state.remaining, const Duration(minutes: 50));
    });

    test('editing a duration leaves a running interval alone', () {
      final e = build()..start();
      e.updateConfig(config.copyWith(focusDuration: const Duration(minutes: 50)));
      expect(e.state.totalDuration, const Duration(minutes: 25));
      expect(e.state.endsAt, t0.add(const Duration(minutes: 25)));
    });
  });
}
