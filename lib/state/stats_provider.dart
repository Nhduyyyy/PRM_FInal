import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/models.dart';

enum StatsPeriod { week, month, year }

class _Range {
  final DateTime start;
  final DateTime end;
  const _Range(this.start, this.end);
}

class StatsProvider extends ChangeNotifier {
  final ActivityDao _activityDao = ActivityDao();
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  StatsPeriod _period = StatsPeriod.week;

  ActivityStats _stats = const ActivityStats(totalKm: 0, totalDurationSeconds: 0, runCount: 0);
  Map<String, double> _dailyDistance = {};
  double _previousPeriodKm = 0;

  int? _bestPace;
  RunActivity? _longestByDistance;
  RunActivity? _longestByDuration;

  bool get loading => _loading;
  StatsPeriod get period => _period;
  ActivityStats get stats => _stats;
  Map<String, double> get dailyDistance => _dailyDistance;
  int? get bestPace => _bestPace;
  RunActivity? get longestByDistance => _longestByDistance;
  RunActivity? get longestByDuration => _longestByDuration;

  /// Percentage change of this period's distance vs the previous equivalent
  /// period. Positive = improvement.
  double get comparisonPercent {
    if (_previousPeriodKm <= 0) return _stats.totalKm > 0 ? 100 : 0;
    return ((_stats.totalKm - _previousPeriodKm) / _previousPeriodKm) * 100;
  }

  /// Weekly totals within the current month — only meaningful when
  /// [period] is [StatsPeriod.month].
  List<double> get weeklyTotalsInMonth {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final weeks = <double>[];
    var weekStart = firstOfMonth;
    while (weekStart.month == now.month) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      var total = 0.0;
      for (var d = weekStart; !d.isAfter(weekEnd) && d.month == now.month; d = d.add(const Duration(days: 1))) {
        total += _dailyDistance[_fmt.format(d)] ?? 0;
      }
      weeks.add(total);
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return weeks;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final range = _rangeFor(_period);
    final prevRange = _previousRangeFor(_period);

    _stats = await _activityDao.getStatsInRange(_fmt.format(range.start), _fmt.format(range.end));
    _dailyDistance = await _activityDao.getDailyDistance(_fmt.format(range.start), _fmt.format(range.end));
    _previousPeriodKm = await _activityDao.getDistanceInRange(
      _fmt.format(prevRange.start),
      _fmt.format(prevRange.end),
    );

    _bestPace = await _activityDao.getPersonalBestPace();
    _longestByDistance = await _activityDao.getLongestRunByDistance();
    _longestByDuration = await _activityDao.getLongestRunByDuration();

    _loading = false;
    notifyListeners();
  }

  Future<void> setPeriod(StatsPeriod period) async {
    _period = period;
    await load();
  }

  _Range _rangeFor(StatsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return _Range(DateTime(start.year, start.month, start.day), now);
      case StatsPeriod.month:
        return _Range(DateTime(now.year, now.month, 1), now);
      case StatsPeriod.year:
        return _Range(DateTime(now.year, 1, 1), now);
    }
  }

  _Range _previousRangeFor(StatsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.week:
        final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = thisWeekStart.subtract(const Duration(days: 7));
        final end = thisWeekStart.subtract(const Duration(days: 1));
        return _Range(DateTime(start.year, start.month, start.day), end);
      case StatsPeriod.month:
        final firstThisMonth = DateTime(now.year, now.month, 1);
        final lastPrevMonth = firstThisMonth.subtract(const Duration(days: 1));
        return _Range(DateTime(lastPrevMonth.year, lastPrevMonth.month, 1), lastPrevMonth);
      case StatsPeriod.year:
        return _Range(DateTime(now.year - 1, 1, 1), DateTime(now.year - 1, 12, 31));
    }
  }
}
