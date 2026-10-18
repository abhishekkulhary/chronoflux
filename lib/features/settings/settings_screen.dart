import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/neon_palette.dart';
import '../timer/application/timer_providers.dart';
import '../timer/presentation/widgets/aurora_background.dart';
import '../timer/presentation/widgets/glass_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final controller = ref.read(configProvider.notifier);
    const palette = PhasePalette.focus;

    return Scaffold(
      body: AuroraBackground(
        palette: palette,
        intensity: 0.5,
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                title: 'SETTINGS',
                trailing: TextButton(
                  onPressed: controller.reset,
                  child: Text(
                    'Restore defaults',
                    style: AppTypography.textTheme.bodyMedium
                        ?.copyWith(color: palette.glow),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    GlassPanel(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INTERVALS', style: AppTypography.eyebrow),
                          const SizedBox(height: 8),
                          _DurationSlider(
                            label: 'Focus',
                            value: config.focusDuration,
                            min: 5,
                            max: 90,
                            palette: palette,
                            onChanged: (d) => controller
                                .update(config.copyWith(focusDuration: d)),
                          ),
                          _DurationSlider(
                            label: 'Short break',
                            value: config.shortBreakDuration,
                            min: 1,
                            max: 30,
                            palette: PhasePalette.shortBreak,
                            onChanged: (d) => controller
                                .update(config.copyWith(shortBreakDuration: d)),
                          ),
                          _DurationSlider(
                            label: 'Long break',
                            value: config.longBreakDuration,
                            min: 5,
                            max: 60,
                            palette: PhasePalette.longBreak,
                            onChanged: (d) => controller
                                .update(config.copyWith(longBreakDuration: d)),
                          ),
                          _CountSlider(
                            label: 'Focus sessions per long break',
                            value: config.sessionsBeforeLongBreak,
                            min: 2,
                            max: 8,
                            palette: palette,
                            onChanged: (v) => controller.update(
                                config.copyWith(sessionsBeforeLongBreak: v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FLOW', style: AppTypography.eyebrow),
                          const SizedBox(height: 6),
                          _SwitchRow(
                            label: 'Auto-start breaks',
                            description:
                                'Roll straight into the break when focus ends.',
                            value: config.autoStartBreaks,
                            palette: palette,
                            onChanged: (v) => controller
                                .update(config.copyWith(autoStartBreaks: v)),
                          ),
                          _SwitchRow(
                            label: 'Auto-start focus',
                            description:
                                'Begin the next session without waiting for you.',
                            value: config.autoStartFocus,
                            palette: palette,
                            onChanged: (v) => controller
                                .update(config.copyWith(autoStartFocus: v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      strong: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALERTS', style: AppTypography.eyebrow),
                          const SizedBox(height: 6),
                          _SwitchRow(
                            label: 'Notifications',
                            description:
                                'Alerts you even when the app is in the background.',
                            value: config.notificationsEnabled,
                            palette: palette,
                            onChanged: (v) => controller.update(
                                config.copyWith(notificationsEnabled: v)),
                          ),
                          _SwitchRow(
                            label: 'Chime',
                            value: config.soundEnabled,
                            palette: palette,
                            onChanged: (v) => controller
                                .update(config.copyWith(soundEnabled: v)),
                          ),
                          _SwitchRow(
                            label: 'Haptics',
                            description: 'Mobile only.',
                            value: config.hapticsEnabled,
                            palette: palette,
                            onChanged: (v) => controller
                                .update(config.copyWith(hapticsEnabled: v)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: NeonSurfaces.textSecondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            title,
            style: AppTypography.eyebrow
                .copyWith(color: NeonSurfaces.textPrimary, fontSize: 14),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.palette,
    required this.onChanged,
  });

  final String label;
  final Duration value;
  final double min;
  final double max;
  final PhasePalette palette;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final minutes = value.inMinutes.toDouble().clamp(min, max);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTypography.textTheme.bodyLarge),
              ),
              Text(
                '${minutes.round()} min',
                style: AppTypography.displaySmall(16)
                    .copyWith(color: palette.glow),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: palette.glow,
              thumbColor: Colors.white,
              overlayColor: palette.glow.withValues(alpha: 0.16),
            ),
            child: Slider(
              value: minutes,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: (v) => onChanged(Duration(minutes: v.round())),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountSlider extends StatelessWidget {
  const _CountSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.palette,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final PhasePalette palette;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(label, style: AppTypography.textTheme.bodyLarge),
              ),
              Text(
                '$value',
                style: AppTypography.displaySmall(16)
                    .copyWith(color: palette.glow),
              ),
            ],
          ),
          Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.palette,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;
  final PhasePalette palette;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.textTheme.bodyLarge),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(description!,
                      style: AppTypography.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.glow.withValues(alpha: 0.55),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Exposed for reuse by the history screen's header.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) =>
      _Header(title: title, trailing: trailing);
}
