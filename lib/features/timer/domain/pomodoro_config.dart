import 'session_phase.dart';

/// User-tunable settings for the cycle. Persisted via SharedPreferences.
class PomodoroConfig {
  const PomodoroConfig({
    this.focusDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = true,
    this.autoStartFocus = false,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
  });

  final Duration focusDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;

  /// Focus sessions completed before a long break is offered.
  final int sessionsBeforeLongBreak;

  /// Breaks default to auto-start (you have earned it, no tap required) while
  /// focus does not — dropping back into work should be a deliberate choice.
  final bool autoStartBreaks;
  final bool autoStartFocus;

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;

  Duration durationFor(SessionPhase phase) => switch (phase) {
        SessionPhase.focus => focusDuration,
        SessionPhase.shortBreak => shortBreakDuration,
        SessionPhase.longBreak => longBreakDuration,
      };

  bool autoStartFor(SessionPhase phase) =>
      phase.isBreak ? autoStartBreaks : autoStartFocus;

  PomodoroConfig copyWith({
    Duration? focusDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
  }) =>
      PomodoroConfig(
        focusDuration: focusDuration ?? this.focusDuration,
        shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
        longBreakDuration: longBreakDuration ?? this.longBreakDuration,
        sessionsBeforeLongBreak:
            sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
        autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
        autoStartFocus: autoStartFocus ?? this.autoStartFocus,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'focusSeconds': focusDuration.inSeconds,
        'shortBreakSeconds': shortBreakDuration.inSeconds,
        'longBreakSeconds': longBreakDuration.inSeconds,
        'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
        'autoStartBreaks': autoStartBreaks,
        'autoStartFocus': autoStartFocus,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'notificationsEnabled': notificationsEnabled,
      };

  factory PomodoroConfig.fromJson(Map<String, dynamic> json) {
    const fallback = PomodoroConfig();
    Duration secs(String key, Duration or) {
      final v = json[key];
      return v is int && v > 0 ? Duration(seconds: v) : or;
    }

    bool flag(String key, bool or) {
      final v = json[key];
      return v is bool ? v : or;
    }

    final cycles = json['sessionsBeforeLongBreak'];
    return PomodoroConfig(
      focusDuration: secs('focusSeconds', fallback.focusDuration),
      shortBreakDuration: secs('shortBreakSeconds', fallback.shortBreakDuration),
      longBreakDuration: secs('longBreakSeconds', fallback.longBreakDuration),
      sessionsBeforeLongBreak:
          cycles is int && cycles > 0 ? cycles : fallback.sessionsBeforeLongBreak,
      autoStartBreaks: flag('autoStartBreaks', fallback.autoStartBreaks),
      autoStartFocus: flag('autoStartFocus', fallback.autoStartFocus),
      soundEnabled: flag('soundEnabled', fallback.soundEnabled),
      hapticsEnabled: flag('hapticsEnabled', fallback.hapticsEnabled),
      notificationsEnabled:
          flag('notificationsEnabled', fallback.notificationsEnabled),
    );
  }
}
