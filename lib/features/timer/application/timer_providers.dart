import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/session_repository.dart';
import '../../../data/settings_repository.dart';
import '../../../services/haptics_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/sound_service.dart';
import '../domain/pomodoro_config.dart';
import '../domain/session_phase.dart';
import '../domain/session_record.dart';
import '../domain/timer_state.dart';
import 'pomodoro_engine.dart';
import 'session_effects.dart';
import 'ticker.dart';

/// Overridden in main() once the async open() calls have completed.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepositoryProvider not overridden'),
);

final sessionRepositoryProvider = Provider<SessionStore>(
  (ref) => throw UnimplementedError('sessionRepositoryProvider not overridden'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationServiceProvider not overridden'),
);

/// Injectable so tests (and any future "simulate a session" tooling) can drive
/// the engine without waiting on real time.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
final tickerProvider = Provider<Ticker>((ref) => const SystemTicker());

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

// ------------------------------------------------------------------- config

class ConfigController extends Notifier<PomodoroConfig> {
  @override
  PomodoroConfig build() => ref.watch(settingsRepositoryProvider).loadConfig();

  void update(PomodoroConfig config) {
    state = config;
    unawaited(ref.read(settingsRepositoryProvider).saveConfig(config));
  }

  void reset() => update(const PomodoroConfig());
}

final configProvider =
    NotifierProvider<ConfigController, PomodoroConfig>(ConfigController.new);

// ------------------------------------------------------------------ history

class HistoryController extends Notifier<List<SessionRecord>> {
  @override
  List<SessionRecord> build() => ref.watch(sessionRepositoryProvider).all();

  Future<void> refresh() async {
    state = ref.read(sessionRepositoryProvider).all();
  }

  Future<void> clear() async {
    await ref.read(sessionRepositoryProvider).clear();
    state = const [];
  }
}

final historyProvider =
    NotifierProvider<HistoryController, List<SessionRecord>>(
        HistoryController.new);

// -------------------------------------------------------------------- timer

/// Owns the engine and bridges its side effects to the platform services.
class TimerController extends Notifier<TimerState> implements SessionEffects {
  late final PomodoroEngine _engine;

  PomodoroEngine get engine => _engine;

  @override
  TimerState build() {
    final settings = ref.watch(settingsRepositoryProvider);
    final config = ref.read(configProvider);

    _engine = PomodoroEngine(
      config: config,
      clock: ref.read(clockProvider),
      ticker: ref.read(tickerProvider),
      effects: this,
    );

    // Restore before wiring onChanged: the engine emits during restore, and
    // assigning `state` while build() is still running is not allowed.
    final restored = settings.loadTimer();
    if (restored != null) _engine.restore(restored);

    _engine.onChanged = (next) {
      state = next;
      unawaited(settings.saveTimer(next));
    };

    ref.listen(configProvider, (_, next) => _engine.updateConfig(next));
    ref.onDispose(_engine.dispose);

    return _engine.state;
  }

  // -- commands

  Future<void> start() async {
    final config = ref.read(configProvider);
    if (config.notificationsEnabled) {
      // Ask on first start rather than at launch, so the reason is obvious.
      await ref.read(notificationServiceProvider).requestPermission();
    }
    HapticsService.impact();
    _engine.start();
  }

  Future<void> toggle() =>
      state.status.isRunning ? Future.sync(pause) : start();

  void pause() {
    HapticsService.impact();
    _engine.pause();
  }

  void reset() {
    HapticsService.tap();
    _engine.reset();
  }

  void skip() {
    HapticsService.tap();
    _engine.skip();
  }

  /// Reconcile against the wall clock — called on app resume.
  void sync() => _engine.sync();

  // -- SessionEffects

  @override
  void scheduleCompletionAlert({
    required SessionPhase phase,
    required DateTime endsAt,
  }) {
    if (!ref.read(configProvider).notificationsEnabled) return;
    unawaited(ref
        .read(notificationServiceProvider)
        .scheduleCompletion(phase: phase, endsAt: endsAt));
  }

  @override
  void cancelCompletionAlerts() =>
      unawaited(ref.read(notificationServiceProvider).cancelAll());

  @override
  void announceCompletion(SessionPhase completed, {required bool fresh}) {
    // Only celebrate a completion we actually witnessed. Chiming for an
    // interval that ended twenty minutes ago is just confusing.
    if (!fresh) return;
    final config = ref.read(configProvider);
    if (config.soundEnabled) {
      unawaited(ref.read(soundServiceProvider).playFor(completed));
    }
    if (config.hapticsEnabled) HapticsService.complete();
  }

  @override
  void recordSession({
    required SessionPhase phase,
    required Duration length,
    required DateTime endedAt,
  }) {
    final record =
        SessionRecord(phase: phase, length: length, endedAt: endedAt);
    unawaited(ref.read(sessionRepositoryProvider).add(record).then(
          (_) => ref.read(historyProvider.notifier).refresh(),
        ));
  }
}

final timerProvider =
    NotifierProvider<TimerController, TimerState>(TimerController.new);
