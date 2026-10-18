/// `mm:ss`, or `h:mm:ss` past an hour. Rounds up so a timer started at 25:00
/// reads "25:00" rather than flicking straight to "24:59".
String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : (d.inMilliseconds / 1000).ceil();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}

/// Compact human form for stats: `1h 25m`, `45m`, `30s`.
String formatSpan(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
