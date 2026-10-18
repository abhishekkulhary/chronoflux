/// The three kinds of interval in a Pomodoro cycle.
enum SessionPhase {
  focus,
  shortBreak,
  longBreak;

  bool get isBreak => this != SessionPhase.focus;

  String get label => switch (this) {
        SessionPhase.focus => 'Focus',
        SessionPhase.shortBreak => 'Short Break',
        SessionPhase.longBreak => 'Long Break',
      };

  /// Short form for dense surfaces (notifications, the cycle rail).
  String get shortLabel => switch (this) {
        SessionPhase.focus => 'FOCUS',
        SessionPhase.shortBreak => 'BREAK',
        SessionPhase.longBreak => 'LONG BREAK',
      };

  String get tagline => switch (this) {
        SessionPhase.focus => 'Deep work in progress',
        SessionPhase.shortBreak => 'Breathe. Reset.',
        SessionPhase.longBreak => 'Step away properly',
      };

  static SessionPhase fromName(String name) =>
      SessionPhase.values.firstWhere((p) => p.name == name,
          orElse: () => SessionPhase.focus);
}
