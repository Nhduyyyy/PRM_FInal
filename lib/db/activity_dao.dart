import '../services/session_service.dart';
import 'database_helper.dart';
import 'models.dart';

class ActivityStats {
  final double totalKm;
  final int totalDurationSeconds;
  final int runCount;

  const ActivityStats({
    required this.totalKm,
    required this.totalDurationSeconds,
    required this.runCount,
  });
}

class ActivityDao {
  Future<int> insert(RunActivity activity) async {
    final db = await DatabaseHelper.instance.database;
    final map = activity.toMap()..['user_id'] = SessionService.instance.requireUserId;
    return db.insert('activities', map);
  }

  Future<int> update(RunActivity activity) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'activities',
      activity.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [activity.id, SessionService.instance.requireUserId],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      'activities',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, SessionService.instance.requireUserId],
    );
  }

  Future<RunActivity?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, SessionService.instance.requireUserId],
    );
    if (rows.isEmpty) return null;
    return RunActivity.fromMap(rows.first);
  }

  Future<List<RunActivity>> getAll({String orderBy = 'created_at DESC'}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
      orderBy: orderBy,
    );
    return rows.map(RunActivity.fromMap).toList();
  }

  Future<List<RunActivity>> getRecent(int limit) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(RunActivity.fromMap).toList();
  }

  Future<List<RunActivity>> getByType(String activityType) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'activity_type = ? AND user_id = ?',
      whereArgs: [activityType, SessionService.instance.requireUserId],
      orderBy: 'created_at DESC',
    );
    return rows.map(RunActivity.fromMap).toList();
  }

  Future<List<RunActivity>> getInRange(String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'date >= ? AND date <= ? AND user_id = ?',
      whereArgs: [startDate, endDate, SessionService.instance.requireUserId],
      orderBy: 'date ASC',
    );
    return rows.map(RunActivity.fromMap).toList();
  }

  Future<double> getTotalDistance() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(distance_km), 0) as total FROM activities WHERE user_id = ?',
      [SessionService.instance.requireUserId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getDistanceInRange(String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(distance_km), 0) as total FROM activities WHERE date >= ? AND date <= ? AND user_id = ?',
      [startDate, endDate, SessionService.instance.requireUserId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<ActivityStats> getStatsInRange(String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(distance_km), 0) as totalKm,
                COALESCE(SUM(duration_seconds), 0) as totalDuration,
                COUNT(*) as runCount
         FROM activities WHERE date >= ? AND date <= ? AND user_id = ?''',
      [startDate, endDate, SessionService.instance.requireUserId],
    );
    final row = result.first;
    return ActivityStats(
      totalKm: (row['totalKm'] as num).toDouble(),
      totalDurationSeconds: (row['totalDuration'] as num).toInt(),
      runCount: (row['runCount'] as num).toInt(),
    );
  }

  /// Returns a map of date (yyyy-MM-dd) -> total distance km run that day,
  /// for every day in [startDate, endDate] inclusive (days with no run map to 0).
  Future<Map<String, double>> getDailyDistance(String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''SELECT date, SUM(distance_km) as total FROM activities
         WHERE date >= ? AND date <= ? AND user_id = ? GROUP BY date''',
      [startDate, endDate, SessionService.instance.requireUserId],
    );
    final result = <String, double>{};
    for (final row in rows) {
      result[row['date'] as String] = (row['total'] as num).toDouble();
    }
    return result;
  }

  Future<int?> getPersonalBestPace() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT MIN(best_pace_sec_per_km) as best FROM activities WHERE best_pace_sec_per_km > 0 AND user_id = ?',
      [SessionService.instance.requireUserId],
    );
    final value = result.first['best'];
    return value == null ? null : (value as num).toInt();
  }

  Future<RunActivity?> getLongestRunByDistance() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
      orderBy: 'distance_km DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RunActivity.fromMap(rows.first);
  }

  Future<RunActivity?> getLongestRunByDuration() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
      orderBy: 'duration_seconds DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RunActivity.fromMap(rows.first);
  }

  /// Distinct `plan_day_id`s that have at least one logged activity —
  /// used to mark training-plan days as completed.
  Future<Set<int>> getCompletedPlanDayIds() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'activities',
      columns: ['DISTINCT plan_day_id'],
      where: 'plan_day_id IS NOT NULL AND user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
    );
    return rows.map((r) => r['plan_day_id'] as int).toSet();
  }
}
