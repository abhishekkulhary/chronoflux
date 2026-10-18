import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neon_palette.dart';
import '../../../core/utils/duration_format.dart';
import '../../get_the_app/get_the_app_screen.dart';
import '../../get_the_app/get_the_app_strings.dart';
import '../../history/history_screen.dart';
import '../../settings/settings_screen.dart';
import '../application/timer_providers.dart';
import '../domain/session_phase.dart';
import '../domain/timer_state.dart';
import 'widgets/aurora_background.dart';
import 'widgets/cycle_dots.dart';
import 'widgets/glass_panel.dart';
import 'widgets/glow_ring.dart';
import 'widgets/neon_button.dart';
import 'widgets/palette_transition.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with SingleTickerProviderStateMixin {
  /// Slow breathing applied to the ring's bloom while a session runs.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse(bool running) {
    if (running && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!running && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerProvider);
    final config = ref.watch(configProvider);
    final controller = ref.read(timerProvider.notifier);
    final target = PhasePalette.of(state.phase);

    _syncPulse(state.status.isRunning);

    return PaletteTransition(
      palette: target,
      builder: (context, palette) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): controller.toggle,
          const SingleActivator(LogicalKeyboardKey.keyR): controller.reset,
          const SingleActivator(LogicalKeyboardKey.keyS): controller.skip,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: AuroraBackground(
              palette: palette,
              intensity: state.status.isRunning ? 1.0 : 0.62,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = context.isWide && constraints.maxWidth > 940;
                    return Column(
                      children: [
                        _TopBar(palette: palette),
                        Expanded(
                          child: wide
                              ? _WideBody(
                                  state: state,
                                  palette: palette,
                                  pulse: _pulse,
                                  sessionsPerSet:
                                      config.sessionsBeforeLongBreak,
                                )
                              : _CompactBody(
                                  state: state,
                                  palette: palette,
                                  pulse: _pulse,
                                  sessionsPerSet:
                                      config.sessionsBeforeLongBreak,
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.palette});

  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Shrinks rather than overflows on narrow screens and at large
          // system text scales.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                shaderCallback: (rect) => palette.sweep.createShader(rect),
                child: Text(
                  'CHRONOFLUX',
                  maxLines: 1,
                  style: AppTypography.displaySmall(17, weight: 700)
                      .copyWith(color: Colors.white, letterSpacing: 4),
                ),
              ),
            ),
          ),
          const Spacer(),
          // The native apps are offered from the web build only.
          if (kIsWeb) ...[
            NeonIconButton(
              icon: Icons.download_rounded,
              tooltip: GetTheAppStrings.of(context).getTheApp,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GetTheAppScreen(appName: 'Chronoflux'),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          NeonIconButton(
            icon: Icons.insights_outlined,
            tooltip: 'History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
          const SizedBox(width: 10),
          NeonIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ring, labels and controls stacked vertically — phones and narrow windows.
class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.state,
    required this.palette,
    required this.pulse,
    required this.sessionsPerSet,
  });

  final TimerState state;
  final PhasePalette palette;
  final Animation<double> pulse;
  final int sessionsPerSet;

  @override
  Widget build(BuildContext context) {
    // The ring takes whatever vertical space the labels, dots and controls
    // leave over. Sizing it from a hand-tuned constant instead was fragile:
    // the reserve was always slightly wrong on some window height, pushing the
    // Start button below the fold. Expanded cannot be wrong.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          _PhaseLabel(state: state, palette: palette),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Center(
                child: _TimerDial(
                  state: state,
                  palette: palette,
                  pulse: pulse,
                  size: math.min(c.maxWidth * 0.86, c.maxHeight),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          CycleDots(
            completed: state.focusCompletedInCycle,
            total: sessionsPerSet,
            palette: palette,
          ),
          const SizedBox(height: 26),
          _Controls(state: state, palette: palette),
        ],
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.state,
    required this.palette,
    required this.pulse,
    required this.sessionsPerSet,
  });

  final TimerState state;
  final PhasePalette palette;
  final Animation<double> pulse;
  final int sessionsPerSet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _PhaseLabel(state: state, palette: palette),
                const SizedBox(height: 18),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Center(
                      child: _TimerDial(
                        state: state,
                        palette: palette,
                        pulse: pulse,
                        size: math.min(c.maxWidth * 0.86, c.maxHeight),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                CycleDots(
                  completed: state.focusCompletedInCycle,
                  total: sessionsPerSet,
                  palette: palette,
                ),
                const SizedBox(height: 26),
                _Controls(state: state, palette: palette),
              ],
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            flex: 2,
            child: _SidePanel(state: state, palette: palette),
          ),
        ],
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.state, required this.palette});

  final TimerState state;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(state.phase),
        children: [
          ShaderMask(
            shaderCallback: (rect) => palette.sweep.createShader(rect),
            child: Text(
              state.phase.shortLabel,
              style: AppTypography.eyebrow.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.phase.tagline,
            style: AppTypography.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({
    required this.state,
    required this.palette,
    required this.pulse,
    required this.size,
  });

  final TimerState state;
  final PhasePalette palette;
  final Animation<double> pulse;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clockSize = size * 0.215;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) => GlowRing(
          progress: state.progress,
          palette: palette,
          pulse: pulse.value,
          strokeWidth: math.max(size * 0.038, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCountdown(state.remaining),
                style: AppTypography.clock(clockSize),
              ),
              const SizedBox(height: 10),
              Text(
                state.status.isPaused
                    ? 'PAUSED'
                    : '${state.completedToday} DONE TODAY',
                style: AppTypography.eyebrow.copyWith(
                  fontSize: math.max(clockSize * 0.13, 10),
                  color: state.status.isPaused
                      ? palette.glow
                      : NeonSurfaces.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.state, required this.palette});

  final TimerState state;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(timerProvider.notifier);
    final running = state.status.isRunning;
    final atFullIdle =
        state.status.isIdle && state.remaining == state.totalDuration;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeonIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Reset (R)',
          onPressed: atFullIdle ? null : controller.reset,
        ),
        const SizedBox(width: 18),
        NeonButton(
          label: running
              ? 'Pause'
              : (state.status.isPaused ? 'Resume' : 'Start'),
          icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          primary: true,
          palette: palette,
          width: 176,
          onPressed: controller.toggle,
        ),
        const SizedBox(width: 18),
        NeonIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Skip to next phase (S)',
          onPressed: controller.skip,
        ),
      ],
    );
  }
}

/// Desktop-only companion column: today's numbers and the upcoming phase.
class _SidePanel extends ConsumerWidget {
  const _SidePanel({required this.state, required this.palette});

  final TimerState state;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final config = ref.watch(configProvider);
    final today = DateTime.now();
    final todaysFocus = history.where((r) =>
        r.phase == SessionPhase.focus &&
        r.day == DateTime(today.year, today.month, today.day));
    final focusedTime = todaysFocus.fold(
      Duration.zero,
      (sum, r) => sum + r.length,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TODAY', style: AppTypography.eyebrow),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: '${todaysFocus.length}',
                      label: 'sessions',
                      palette: palette,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      value: formatSpan(focusedTime),
                      label: 'focused',
                      palette: palette,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 20, color: palette.glow.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Long break after '
                  '${math.max(config.sessionsBeforeLongBreak - state.focusCompletedInCycle, 0)}'
                  ' more focus '
                  '${config.sessionsBeforeLongBreak - state.focusCompletedInCycle == 1 ? 'session' : 'sessions'}',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Row(
            children: [
              Icon(Icons.keyboard_rounded,
                  size: 20, color: NeonSurfaces.textFaint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Space start/pause · R reset · S skip',
                  style: AppTypography.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.palette,
  });

  final String value;
  final String label;
  final PhasePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (rect) => palette.sweep.createShader(rect),
          child: Text(
            value,
            style: AppTypography.displaySmall(30, weight: 700)
                .copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.textTheme.bodySmall),
      ],
    );
  }
}
