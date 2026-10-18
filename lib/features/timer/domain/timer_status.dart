/// Run state of the active interval.
///
/// There is deliberately no `completed` state: completion is an instantaneous
/// event that immediately advances the cycle to the next phase, landing in
/// either [running] (when auto-start is on) or [idle].
enum TimerStatus {
  idle,
  running,
  paused;

  bool get isRunning => this == TimerStatus.running;
  bool get isPaused => this == TimerStatus.paused;
  bool get isIdle => this == TimerStatus.idle;
}
