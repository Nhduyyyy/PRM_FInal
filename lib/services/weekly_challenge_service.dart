import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/models.dart';
import '../db/weekly_challenge_dao.dart';

/// Rule-based weekly challenge: suggests a target 25% above last week's
/// distance. No ML/AI involved — just a simple multiplier over history.
class WeeklyChallengeService {
  final WeeklyChallengeDao _dao = WeeklyChallengeDao();
  final ActivityDao _activityDao = ActivityDao();
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static DateTime mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Returns this week's challenge, generating one from last week's mileage
  /// the first time it's requested. Returns null if there's no run history
  /// yet to base a suggestion on.
  Future<WeeklyChallenge?> ensureCurrentChallenge() async {
    final weekStart = mondayOf(DateTime.now());
    final weekStartStr = _fmt.format(weekStart);

    final existing = await _dao.getForWeek(weekStartStr);
    if (existing != null) return existing;

    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));
    final lastWeekKm = await _activityDao.getDistanceInRange(
      _fmt.format(lastWeekStart),
      _fmt.format(lastWeekEnd),
    );
    if (lastWeekKm <= 0) return null;

    final targetKm = ((lastWeekKm * 1.25) * 2).round() / 2; // round to nearest 0.5km
    final id = await _dao.insert(WeeklyChallenge(weekStartDate: weekStartStr, targetKm: targetKm));
    return WeeklyChallenge(id: id, weekStartDate: weekStartStr, targetKm: targetKm);
  }

  Future<double> progressKm(WeeklyChallenge challenge) {
    final weekStart = DateTime.parse(challenge.weekStartDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _activityDao.getDistanceInRange(challenge.weekStartDate, _fmt.format(weekEnd));
  }

  Future<void> markAchievedIfNeeded(WeeklyChallenge challenge, double progressKm) async {
    if (!challenge.achieved && progressKm >= challenge.targetKm && challenge.id != null) {
      await _dao.markAchieved(challenge.id!);
    }
  }
}
