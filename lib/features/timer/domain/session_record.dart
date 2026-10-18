import 'session_phase.dart';

/// One completed interval, as written to history.
class SessionRecord {
  const SessionRecord({
    required this.phase,
    required this.length,
    required this.endedAt,
  });

  final SessionPhase phase;
  final Duration length;
  final DateTime endedAt;

  /// Calendar day the session belongs to, used for grouping and streaks.
  DateTime get day => DateTime(endedAt.year, endedAt.month, endedAt.day);

  Map<String, dynamic> toMap() => {
        'phase': phase.name,
        'seconds': length.inSeconds,
        'endedAt': endedAt.millisecondsSinceEpoch,
      };

  static SessionRecord? fromMap(Map<dynamic, dynamic> map) {
    final ms = map['endedAt'];
    final seconds = map['seconds'];
    if (ms is! int || seconds is! int) return null;
    return SessionRecord(
      phase: SessionPhase.fromName(map['phase']?.toString() ?? ''),
      length: Duration(seconds: seconds),
      endedAt: DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}
