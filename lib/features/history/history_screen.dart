import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/neon_palette.dart';
import '../../core/utils/duration_format.dart';
import '../settings/settings_screen.dart' show ScreenHeader;
import '../timer/application/timer_providers.dart';
import '../timer/domain/session_phase.dart';
import '../timer/domain/session_record.dart';
import '../timer/presentation/widgets/aurora_background.dart';
import '../timer/presentation/widgets/glass_panel.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final focus =
        history.where((r) => r.phase == SessionPhase.focus).toList();
    const palette = PhasePalette.focus;

    return Scaffold(
      body: AuroraBackground(
        palette: palette,
        intensity: 0.5,
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'HISTORY',
                trailing: focus.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => _confirmClear(context, ref),
                        child: Text(
                          'Clear',
                          style: AppTypography.textTheme.bodyMedium
                              ?.copyWith(color: NeonSurfaces.danger),
                        ),
                      ),
              ),
              Expanded(
                child: focus.isEmpty
                    ? const _EmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          _WeekChart(sessions: focus),
                          const SizedBox(height: 18),
                          _Totals(sessions: focus),
                          const SizedBox(height: 18),
                          Text('RECENT', style: AppTypography.eyebrow),
                          const SizedBox(height: 10),
                          // Capped: history is a glance, not an archive.
                          ...focus.take(50).map(
                                (r) => _SessionTile(record: r),
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

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear history?', style: AppTypography.textTheme.titleLarge),
        content: Text(
          'This permanently deletes every recorded session. It cannot be undone.',
          style: AppTypography.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear',
                style: TextStyle(color: NeonSurfaces.danger)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(historyProvider.notifier).clear();
    }
  }
}

/// Focus sessions per day over the last seven days.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.sessions});

  final List<SessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final days = List.generate(7, (i) {
      final day = startOfToday.subtract(Duration(days: 6 - i));
      final count = sessions.where((r) => r.day == day).length;
      return (day: day, count: count);
    });

    final maxCount = days.fold<int>(1, (m, d) => d.count > m ? d.count : m);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassPanel(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST 7 DAYS', style: AppTypography.eyebrow),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() + 1,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[days[i].day.weekday - 1],
                            style: AppTypography.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => NeonSurfaces.canvasElevated,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${rod.toY.toInt()} session'
                      '${rod.toY.toInt() == 1 ? '' : 's'}',
                      AppTypography.textTheme.bodyMedium!
                          .copyWith(color: NeonSurfaces.textPrimary),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].count.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: const [
                              Color(0xFF4C6BFF),
                              Color(0xFF22E1FF),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxCount.toDouble() + 1,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.sessions});

  final List<SessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final total = sessions.fold(Duration.zero, (sum, r) => sum + r.length);
    final days = sessions.map((r) => r.day).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _TotalCard(value: '${sessions.length}', label: 'sessions'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _TotalCard(value: formatSpan(total), label: 'focused'),
        ),
        const SizedBox(width: 14),
        Expanded(child: _TotalCard(value: '$days', label: 'active days')),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (rect) =>
                PhasePalette.focus.sweep.createShader(rect),
            child: Text(
              value,
              style: AppTypography.displaySmall(22, weight: 700)
                  .copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.record});

  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final t = record.endedAt;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 16,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PhasePalette.focus.glow,
                boxShadow: [
                  BoxShadow(
                    color: PhasePalette.focus.glow.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _dayLabel(record.day),
                style: AppTypography.textTheme.bodyLarge,
              ),
            ),
            Text('$hh:$mm', style: AppTypography.textTheme.bodyMedium),
            const SizedBox(width: 14),
            Text(
              formatSpan(record.length),
              style: AppTypography.displaySmall(14)
                  .copyWith(color: NeonSurfaces.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${day.day}/${day.month}/${day.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_rounded,
                size: 46, color: NeonSurfaces.textFaint),
            const SizedBox(height: 18),
            Text('No sessions yet',
                style: AppTypography.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Finish a focus session and it will show up here.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
