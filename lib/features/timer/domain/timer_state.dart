import 'pomodoro_config.dart';
import 'session_phase.dart';
import 'timer_status.dart';

/// Immutable snapshot of the timer.
///
/// [endsAt] is the authoritative field while running: it is an absolute wall
/// clock instant, so remaining time is always *derived* from it rather than
/// decremented. That is what keeps the timer honest across app suspension,
/// browser tab throttling and device sleep.
class TimerState {
  const TimerState({
    required this.phase,
    required this.status,
    required this.remaining,
    required this.totalDuration,
    this.endsAt,
    this.focusCompletedInCycle = 0,
    this.completedToday = 0,
  });

  factory TimerState.initial(PomodoroConfig config) => TimerState(
        phase: SessionPhase.focus,
        status: TimerStatus.idle,
        remaining: config.focusDuration,
        totalDuration: config.focusDuration,
      );

  final SessionPhase phase;
  final TimerStatus status;

  /// Time left in the current interval. Derived from [endsAt] while running.
  final Duration remaining;

  /// Full length of the current interval, for progress calculation.
  final Duration totalDuration;

  /// Absolute instant the current interval ends. Null unless running.
  final DateTime? endsAt;

  /// Focus sessions finished since the last long break, in `[0, sessionsBeforeLongBreak)`.
  final int focusCompletedInCycle;

  /// Focus sessions finished today, shown on the timer face.
  final int completedToday;

  /// 0.0 at the start of the interval, 1.0 at the end.
  double get progress {
    final total = totalDuration.inMilliseconds;
    if (total <= 0) return 1;
    final done = total - remaining.inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  bool get isFinished => remaining <= Duration.zero;

  TimerState copyWith({
    SessionPhase? phase,
    TimerStatus? status,
    Duration? remaining,
    Duration? totalDuration,
    DateTime? endsAt,
    bool clearEndsAt = false,
    int? focusCompletedInCycle,
    int? completedToday,
  }) =>
      TimerState(
        phase: phase ?? this.phase,
        status: status ?? this.status,
        remaining: remaining ?? this.remaining,
        totalDuration: totalDuration ?? this.totalDuration,
        endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
        focusCompletedInCycle:
            focusCompletedInCycle ?? this.focusCompletedInCycle,
        completedToday: completedToday ?? this.completedToday,
      );
}
