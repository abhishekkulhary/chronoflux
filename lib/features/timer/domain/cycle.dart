import 'pomodoro_config.dart';
import 'session_phase.dart';

/// Result of finishing one interval: what comes next, and where that leaves
/// the cycle counter.
class CycleStep {
  const CycleStep({required this.nextPhase, required this.focusCompletedInCycle});

  final SessionPhase nextPhase;
  final int focusCompletedInCycle;
}

/// The Pomodoro cycle rule, kept free of timing concerns so it can be
/// reasoned about (and tested) on its own.
///
/// focus → short break → … → focus → long break → focus → …
/// with the long break replacing the short one after every
/// [PomodoroConfig.sessionsBeforeLongBreak] focus sessions.
CycleStep advanceCycle({
  required SessionPhase completed,
  required int focusCompletedInCycle,
  required PomodoroConfig config,
}) {
  switch (completed) {
    case SessionPhase.focus:
      final done = focusCompletedInCycle + 1;
      final earnedLongBreak = done >= config.sessionsBeforeLongBreak;
      return CycleStep(
        nextPhase:
            earnedLongBreak ? SessionPhase.longBreak : SessionPhase.shortBreak,
        focusCompletedInCycle: done,
      );
    case SessionPhase.shortBreak:
      return CycleStep(
        nextPhase: SessionPhase.focus,
        focusCompletedInCycle: focusCompletedInCycle,
      );
    case SessionPhase.longBreak:
      // The long break closes the set; the counter starts over.
      return const CycleStep(
        nextPhase: SessionPhase.focus,
        focusCompletedInCycle: 0,
      );
  }
}
