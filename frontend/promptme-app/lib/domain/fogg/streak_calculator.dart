class StreakCalculator {
  /// 从 [today] 往回数的连续「有完成」天数。
  /// 若今天还没完成，则从昨天起算，避免上午时段读成 0。
  static int currentStreak(Set<DateTime> completionDays, DateTime today) {
    final days = completionDays.map(_dateOnly).toSet();
    final t = _dateOnly(today);
    var cursor = days.contains(t) ? t : t.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// done / total，total 为 0 时返回 0。
  static double completionRate({required int done, required int total}) =>
      total == 0 ? 0 : done / total;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
