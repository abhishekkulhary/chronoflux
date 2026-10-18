import '../domain/cycle.dart';
import '../domain/pomodoro_config.dart';
import '../domain/session_phase.dart';
import '../domain/timer_state.dart';
import '../domain/timer_status.dart';
import 'session_effects.dart';
import 'ticker.dart';

/// Wall-clock Pomodoro engine.
///
/// The contract that makes this correct everywhere: while running, the only
/// authority on how much time is left is [TimerState.endsAt] compared against
/// [Clock.now]. Ticks never decrement anything — they just prompt a recompute.
/// A tick that is late, throttled to once a minute, or missing entirely for
/// twenty minutes therefore cannot desynchronise the timer; the next
/// observation simply reports the truth.
class PomodoroEngine {
  PomodoroEngine({
    required PomodoroConfig config,
    this._clock = const SystemClock(),
    this._ticker = const SystemTicker(),
    this._effects = const NoopSessionEffects(),
    TimerState? initialState,
  })  : _config = config,
        _state = initialState ?? TimerState.initial(config);

  /// 200ms keeps the progress ring visually smooth without meaningful cost;
  /// accuracy does not depend on it.
  static const tickInterval = Duration(milliseconds: 200);

  /// Ceiling on how many intervals a single catch-up may replay, so a wildly
  /// wrong system clock cannot spin the loop.
  static const _maxCatchUpSteps = 100;

  final Clock _clock;
  final Ticker _ticker;
  SessionEffects _effects;
  PomodoroConfig _config;

  TimerState _state;
  void Function()? _cancelTicker;

  /// Notified on every state change.
  void Function(TimerState)? onChanged;

  TimerState get state => _state;
  PomodoroConfig get config => _config;

  set effects(SessionEffects value) => _effects = value;

  void _emit(TimerState next) {
    _state = next;
    onChanged?.call(next);
  }

  // ---------------------------------------------------------------- commands

  void start() {
    if (_state.status.isRunning) return;
    final now = _clock.now();
    final remaining =
        _state.remaining > Duration.zero ? _state.remaining : _state.totalDuration;
    final endsAt = now.add(remaining);

    _emit(_state.copyWith(
      status: TimerStatus.running,
      remaining: remaining,
      endsAt: endsAt,
    ));
    _effects.scheduleCompletionAlert(phase: _state.phase, endsAt: endsAt);
    _startTicking();
  }

  void pause() {
    if (!_state.status.isRunning) return;
    _stopTicking();
    _effects.cancelCompletionAlerts();
    // Freeze the derived remaining so resuming picks up exactly here.
    final remaining = _remainingAt(_clock.now());
    _emit(_state.copyWith(
      status: TimerStatus.paused,
      remaining: remaining,
      clearEndsAt: true,
    ));
  }

  void toggle() => _state.status.isRunning ? pause() : start();

  /// Restart the current phase from full.
  void reset() {
    _stopTicking();
    _effects.cancelCompletionAlerts();
    final full = _config.durationFor(_state.phase);
    _emit(_state.copyWith(
      status: TimerStatus.idle,
      remaining: full,
      totalDuration: full,
      clearEndsAt: true,
    ));
  }

  /// Jump to the next phase without completing this one. A skipped focus
  /// session is deliberately not counted or recorded — it was not done.
  void skip() {
    _stopTicking();
    _effects.cancelCompletionAlerts();
    final step = advanceCycle(
      completed: _state.phase,
      focusCompletedInCycle: _state.focusCompletedInCycle,
      config: _config,
    );
    final full = _config.durationFor(step.nextPhase);
    _emit(_state.copyWith(
      phase: step.nextPhase,
      focusCompletedInCycle: step.focusCompletedInCycle,
      status: TimerStatus.idle,
      remaining: full,
      totalDuration: full,
      clearEndsAt: true,
    ));
  }

  /// Recompute against the wall clock. Call on app resume, on tab visibility
  /// change, and whenever state might be stale.
  void sync() => _tick();

  void updateConfig(PomodoroConfig config) {
    final previous = _config;
    _config = config;
    // Re-length the current interval only when idle; rescaling a running timer
    // under the user would be surprising.
    if (_state.status.isIdle) {
      final full = config.durationFor(_state.phase);
      if (full != previous.durationFor(_state.phase)) {
        _emit(_state.copyWith(remaining: full, totalDuration: full));
      }
    }
  }

  void dispose() {
    _stopTicking();
    onChanged = null;
  }

  // ----------------------------------------------------------------- ticking

  void _startTicking() {
    _cancelTicker ??= _ticker.start(tickInterval, _tick);
  }

  void _stopTicking() {
    _cancelTicker?.call();
    _cancelTicker = null;
  }

  Duration _remainingAt(DateTime now) {
    final endsAt = _state.endsAt;
    if (endsAt == null) return _state.remaining;
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final s = _state;
    if (!s.status.isRunning || s.endsAt == null) return;

    final now = _clock.now();
    if (now.isBefore(s.endsAt!)) {
      _emit(s.copyWith(remaining: s.endsAt!.difference(now)));
      return;
    }
    _resolveElapsed(now);
  }

  /// Replay every interval that finished at or before [now].
  ///
  /// More than one can be due at once: if the app was suspended for half an
  /// hour, a focus session and its auto-started break may both have run their
  /// course. Each next interval is backdated to the instant the previous one
  /// actually ended, so the reconstructed timeline matches what would have
  /// happened had the app stayed awake.
  void _resolveElapsed(DateTime now) {
    var s = _state;
    var steps = 0;
    SessionPhase? lastCompleted;
    DateTime? lastCompletedAt;

    while (s.status.isRunning &&
        s.endsAt != null &&
        !now.isBefore(s.endsAt!) &&
        steps++ < _maxCatchUpSteps) {
      final completedAt = s.endsAt!;
      final completedPhase = s.phase;
      lastCompleted = completedPhase;
      lastCompletedAt = completedAt;

      _effects.recordSession(
        phase: completedPhase,
        length: s.totalDuration,
        endedAt: completedAt,
      );

      final step = advanceCycle(
        completed: completedPhase,
        focusCompletedInCycle: s.focusCompletedInCycle,
        config: _config,
      );
      final nextDuration = _config.durationFor(step.nextPhase);
      final autoStart = _config.autoStartFor(step.nextPhase);

      s = s.copyWith(
        phase: step.nextPhase,
        focusCompletedInCycle: step.focusCompletedInCycle,
        completedToday: completedPhase == SessionPhase.focus
            ? s.completedToday + 1
            : s.completedToday,
        totalDuration: nextDuration,
        remaining: nextDuration,
        status: autoStart ? TimerStatus.running : TimerStatus.idle,
        endsAt: autoStart ? completedAt.add(nextDuration) : null,
        clearEndsAt: !autoStart,
      );
    }

    if (s.status.isRunning && s.endsAt != null) {
      final left = s.endsAt!.difference(now);
      s = s.copyWith(remaining: left.isNegative ? Duration.zero : left);
    } else {
      _stopTicking();
    }

    _emit(s);

    if (lastCompleted != null) {
      // "Fresh" means we caught the completion as it happened rather than
      // discovering it after the fact on resume.
      final lateness = now.difference(lastCompletedAt!);
      _effects.announceCompletion(
        lastCompleted,
        fresh: lateness < const Duration(seconds: 2),
      );

      if (s.status.isRunning && s.endsAt != null) {
        _effects.scheduleCompletionAlert(phase: s.phase, endsAt: s.endsAt!);
      } else {
        _effects.cancelCompletionAlerts();
      }
    }
  }

  /// Re-attach to a state restored from disk. If it was running, the ticker
  /// resumes and [sync] immediately reconciles against the real clock.
  void restore(TimerState restored) {
    _emit(restored);
    if (restored.status.isRunning && restored.endsAt != null) {
      _startTicking();
      _tick();
    }
  }
}
