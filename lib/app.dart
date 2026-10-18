import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/neon_theme.dart';
import 'features/timer/application/timer_providers.dart';
import 'features/timer/presentation/timer_screen.dart';

class ChronofluxApp extends ConsumerStatefulWidget {
  const ChronofluxApp({super.key});

  @override
  ConsumerState<ChronofluxApp> createState() => _ChronofluxAppState();
}

class _ChronofluxAppState extends ConsumerState<ChronofluxApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back to the foreground is the moment stale state is most likely,
    // whether from a suspended process or a throttled browser tab. Both
    // callbacks fire the same reconciliation; it is cheap and idempotent.
    _lifecycle = AppLifecycleListener(
      onResume: _sync,
      onShow: _sync,
    );
  }

  void _sync() => ref.read(timerProvider.notifier).sync();

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF04060F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: 'Chronoflux',
        debugShowCheckedModeBanner: false,
        theme: NeonTheme.build(),
        home: const TimerScreen(),
      ),
    );
  }
}
