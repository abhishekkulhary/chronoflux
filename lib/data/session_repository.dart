import 'package:hive_ce_flutter/hive_flutter.dart';

import '../features/timer/domain/session_phase.dart';
import '../features/timer/domain/session_record.dart';

/// What the app needs from history storage. The interface exists so widget
/// tests can supply an in-memory store instead of real file IO.
abstract interface class SessionStore {
  Future<void> add(SessionRecord record);
  List<SessionRecord> all();
  List<SessionRecord> focusSessions();
  Future<void> clear();
}

/// History storage, backed by Hive so it works unchanged on every target
/// including web (IndexedDB). Records are plain maps, which avoids generated
/// type adapters and keeps the schema easy to migrate by hand.
class SessionRepository implements SessionStore {
  SessionRepository(this._box);

  static const boxName = 'sessions';

  final Box<dynamic> _box;

  static Future<SessionRepository> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return SessionRepository(box);
  }

  @override
  Future<void> add(SessionRecord record) async {
    // Keyed by end time so a replayed catch-up cannot write the same session
    // twice. The key is a string because Hive caps integer keys at 32 bits,
    // which epoch milliseconds overflow by several orders of magnitude.
    await _box.put(
      record.endedAt.millisecondsSinceEpoch.toString(),
      record.toMap(),
    );
  }

  @override
  List<SessionRecord> all() {
    final out = <SessionRecord>[];
    for (final value in _box.values) {
      if (value is Map) {
        final r = SessionRecord.fromMap(value);
        if (r != null) out.add(r);
      }
    }
    out.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return out;
  }

  @override
  List<SessionRecord> focusSessions() =>
      all().where((r) => r.phase == SessionPhase.focus).toList();

  @override
  Future<void> clear() => _box.clear();
}
