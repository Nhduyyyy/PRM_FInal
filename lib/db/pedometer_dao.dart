import 'package:sqflite/sqflite.dart';

import '../services/session_service.dart';
import 'database_helper.dart';
import 'models.dart';

class PedometerDao {
  Future<DailyStepsEntry?> getForDate(String date) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'daily_steps',
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, SessionService.instance.requireUserId],
    );
    if (rows.isEmpty) return null;
    return DailyStepsEntry.fromMap(rows.first);
  }

  /// Records a raw cumulative step-count reading from the pedometer sensor
  /// for [date]. The first reading of a new day becomes the baseline that
  /// today's step count is measured against.
  Future<DailyStepsEntry> recordReading(String date, int cumulativeSteps) async {
    final db = await DatabaseHelper.instance.database;
    final userId = SessionService.instance.requireUserId;
    final existing = await getForDate(date);

    final entry = existing == null
        ? DailyStepsEntry(date: date, baselineSteps: cumulativeSteps, lastSteps: cumulativeSteps)
        : DailyStepsEntry(date: date, baselineSteps: existing.baselineSteps, lastSteps: cumulativeSteps);

    final map = entry.toMap()..['user_id'] = userId;
    await db.insert('daily_steps', map, conflictAlgorithm: ConflictAlgorithm.replace);
    return entry;
  }
}
