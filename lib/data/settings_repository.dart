import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/timer/domain/pomodoro_config.dart';
import '../features/timer/domain/session_phase.dart';
import '../features/timer/domain/timer_state.dart';
import '../features/timer/domain/timer_status.dart';

/// Settings plus a snapshot of any in-flight interval, so a cold start can
/// pick a running timer back up rather than silently losing it.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _configKey = 'pomodoro.config';
  static const _timerKey = 'pomodoro.timer';

  final SharedPreferences _prefs;

  static Future<SettingsRepository> open() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  PomodoroConfig loadConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return const PomodoroConfig();
    try {
      return PomodoroConfig.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt or from an incompatible build: fall back rather than crash.
      return const PomodoroConfig();
    }
  }

  Future<void> saveConfig(PomodoroConfig config) =>
      _prefs.setString(_configKey, jsonEncode(config.toJson()));

  Future<void> saveTimer(TimerState state) {
    // A paused timer keeps its remaining time; a running one is defined by its
    // absolute end instant. Idle needs nothing persisted.
    if (state.status.isIdle) return _prefs.remove(_timerKey);
    return _prefs.setString(
      _timerKey,
      jsonEncode({
        'phase': state.phase.name,
        'status': state.status.name,
        'remainingSeconds': state.remaining.inSeconds,
        'totalSeconds': state.totalDuration.inSeconds,
        'endsAt': state.endsAt?.millisecondsSinceEpoch,
        'focusCompletedInCycle': state.focusCompletedInCycle,
        'completedToday': state.completedToday,
        'savedOn': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  /// Returns null when there is nothing to resume.
  TimerState? loadTimer() {
    final raw = _prefs.getString(_timerKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final endsAtMs = map['endsAt'];
      final savedOnMs = map['savedOn'];

      // The daily tally is only meaningful for today.
      var completedToday = (map['completedToday'] as int?) ?? 0;
      if (savedOnMs is int) {
        final saved = DateTime.fromMillisecondsSinceEpoch(savedOnMs);
        final now = DateTime.now();
        if (saved.year != now.year ||
            saved.month != now.month ||
            saved.day != now.day) {
          completedToday = 0;
        }
      }

      return TimerState(
        phase: SessionPhase.fromName(map['phase']?.toString() ?? ''),
        status: TimerStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => TimerStatus.idle,
        ),
        remaining: Duration(seconds: (map['remainingSeconds'] as int?) ?? 0),
        totalDuration: Duration(seconds: (map['totalSeconds'] as int?) ?? 1500),
        endsAt: endsAtMs is int
            ? DateTime.fromMillisecondsSinceEpoch(endsAtMs)
            : null,
        focusCompletedInCycle: (map['focusCompletedInCycle'] as int?) ?? 0,
        completedToday: completedToday,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTimer() => _prefs.remove(_timerKey);
}
