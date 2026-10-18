import '../domain/session_phase.dart';

/// Side effects the engine triggers but does not own: OS notifications, audio,
/// haptics and history writes. Kept behind an interface so the engine stays
/// pure enough to unit test.
abstract class SessionEffects {
  /// Ask the OS to alert at [endsAt], so the user is told even if the process
  /// is suspended before then.
  void scheduleCompletionAlert({
    required SessionPhase phase,
    required DateTime endsAt,
  });

  void cancelCompletionAlerts();

  /// [fresh] is false when the interval actually elapsed while the app was
  /// suspended — the moment has passed, so playing a chime on return would be
  /// confusing rather than helpful.
  void announceCompletion(SessionPhase completed, {required bool fresh});

  void recordSession({
    required SessionPhase phase,
    required Duration length,
    required DateTime endedAt,
  });
}

/// No-op default, used by tests and before services are wired.
class NoopSessionEffects implements SessionEffects {
  const NoopSessionEffects();

  @override
  void scheduleCompletionAlert({
    required SessionPhase phase,
    required DateTime endsAt,
  }) {}

  @override
  void cancelCompletionAlerts() {}

  @override
  void announceCompletion(SessionPhase completed, {required bool fresh}) {}

  @override
  void recordSession({
    required SessionPhase phase,
    required Duration length,
    required DateTime endedAt,
  }) {}
}
