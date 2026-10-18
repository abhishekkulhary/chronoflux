import 'dart:async';

/// Source of "now". Injected so tests can move time without waiting.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Drives periodic recomputation. It carries no time information itself — it
/// only says "look at the clock again", which is why a dropped or delayed tick
/// can never corrupt the countdown.
abstract class Ticker {
  /// Returns a cancel callback.
  void Function() start(Duration interval, void Function() onTick);
}

class SystemTicker implements Ticker {
  const SystemTicker();

  @override
  void Function() start(Duration interval, void Function() onTick) {
    final timer = Timer.periodic(interval, (_) => onTick());
    return timer.cancel;
  }
}

/// Test double: time advances only when told to.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

/// Test double: ticks fire only when [pump] is called, letting a test model a
/// suspended app (time passes, no ticks) before resuming.
class FakeTicker implements Ticker {
  final List<void Function()> _listeners = [];

  bool get isRunning => _listeners.isNotEmpty;

  @override
  void Function() start(Duration interval, void Function() onTick) {
    _listeners.add(onTick);
    return () => _listeners.remove(onTick);
  }

  void pump() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }
}
