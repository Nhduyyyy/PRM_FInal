import 'package:sqflite/sqflite.dart';

import '../services/session_service.dart';
import 'database_helper.dart';
import 'models.dart';

class ProfileDao {
  Future<UserProfile?> getProfile() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    final map = profile.toMap()
      ..remove('id')
      ..['user_id'] = SessionService.instance.requireUserId;
    // `user_profile.user_id` is UNIQUE, so INSERT OR REPLACE upserts on it
    // the same way the old code relied on the (now removed) `id = 1` PK.
    await db.insert('user_profile', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<StreakInfo> getStreakInfo() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'streak_info',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
    );
    if (rows.isEmpty) return const StreakInfo();
    return StreakInfo.fromMap(rows.first);
  }

  /// Updates the streak given that a run happened on [runDate] ('yyyy-MM-dd').
  /// - +1 if runDate is exactly 1 day after the last run date.
  /// - unchanged if runDate is the same day as the last run date.
  /// - reset to 1 if the gap is more than 1 day (or there was no previous run).
  /// `best_streak` always holds the highest streak ever reached.
  Future<StreakInfo> updateStreak(String runDate) async {
    final db = await DatabaseHelper.instance.database;
    final userId = SessionService.instance.requireUserId;
    final current = await getStreakInfo();

    final runDay = DateTime.parse(runDate);
    int newStreak;

    if (current.lastRunDate == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime.parse(current.lastRunDate!);
      final diffDays = DateTime(runDay.year, runDay.month, runDay.day)
          .difference(DateTime(lastDay.year, lastDay.month, lastDay.day))
          .inDays;

      if (diffDays == 0) {
        newStreak = current.currentStreak;
      } else if (diffDays == 1) {
        newStreak = current.currentStreak + 1;
      } else if (diffDays < 0) {
        // Run backdated before the last recorded run: keep streak unchanged.
        newStreak = current.currentStreak;
      } else {
        newStreak = 1;
      }
    }

    final newBest = newStreak > current.bestStreak ? newStreak : current.bestStreak;
    final updated = StreakInfo(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastRunDate: runDate,
    );

    final map = updated.toMap()
      ..remove('id')
      ..['user_id'] = userId;
    // `streak_info.user_id` is UNIQUE, so INSERT OR REPLACE upserts on it.
    await db.insert('streak_info', map, conflictAlgorithm: ConflictAlgorithm.replace);

    return updated;
  }
}
