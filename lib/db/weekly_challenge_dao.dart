import 'database_helper.dart';
import 'models.dart';

class WeeklyChallengeDao {
  Future<WeeklyChallenge?> getForWeek(String weekStartDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'weekly_challenges',
      where: 'week_start_date = ?',
      whereArgs: [weekStartDate],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeeklyChallenge.fromMap(rows.first);
  }

  Future<WeeklyChallenge?> getMostRecentBefore(String weekStartDate) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'weekly_challenges',
      where: 'week_start_date < ?',
      whereArgs: [weekStartDate],
      orderBy: 'week_start_date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeeklyChallenge.fromMap(rows.first);
  }

  Future<int> insert(WeeklyChallenge challenge) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('weekly_challenges', challenge.toMap());
  }

  Future<void> markAchieved(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'weekly_challenges',
      {'achieved': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
