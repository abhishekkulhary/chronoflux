import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pomodoro_timers/data/session_repository.dart';
import 'package:pomodoro_timers/features/timer/domain/session_phase.dart';
import 'package:pomodoro_timers/features/timer/domain/session_record.dart';

void main() {
  late Directory dir;
  late SessionRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chronoflux_repo');
    Hive.init(dir.path);
    repo = await SessionRepository.open();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('round-trips a session', () async {
    final record = SessionRecord(
      phase: SessionPhase.focus,
      length: const Duration(minutes: 25),
      endedAt: DateTime(2026, 3, 2, 10, 25),
    );
    await repo.add(record);

    final stored = repo.all().single;
    expect(stored.phase, SessionPhase.focus);
    expect(stored.length, const Duration(minutes: 25));
    expect(stored.endedAt, record.endedAt);
  });

  test('accepts present-day timestamps as keys', () async {
    // Regression: epoch milliseconds overflow Hive's 32-bit integer key limit,
    // so keys must be strings. Writing used to throw and history stayed empty.
    await repo.add(SessionRecord(
      phase: SessionPhase.focus,
      length: const Duration(minutes: 25),
      endedAt: DateTime.now(),
    ));
    expect(repo.all(), hasLength(1));
  });

  test('re-recording the same session does not duplicate it', () async {
    final record = SessionRecord(
      phase: SessionPhase.focus,
      length: const Duration(minutes: 25),
      endedAt: DateTime(2026, 3, 2, 10, 25),
    );
    await repo.add(record);
    await repo.add(record);
    expect(repo.all(), hasLength(1));
  });

  test('orders newest first and filters to focus sessions', () async {
    await repo.add(SessionRecord(
      phase: SessionPhase.focus,
      length: const Duration(minutes: 25),
      endedAt: DateTime(2026, 3, 2, 9),
    ));
    await repo.add(SessionRecord(
      phase: SessionPhase.shortBreak,
      length: const Duration(minutes: 5),
      endedAt: DateTime(2026, 3, 2, 10),
    ));
    await repo.add(SessionRecord(
      phase: SessionPhase.focus,
      length: const Duration(minutes: 25),
      endedAt: DateTime(2026, 3, 2, 11),
    ));

    expect(repo.all().first.endedAt.hour, 11);
    expect(repo.focusSessions(), hasLength(2));
  });
}
