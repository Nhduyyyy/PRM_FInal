import 'activity_dao.dart';
import 'database_helper.dart';
import 'models.dart';

class GoalDao {
  final ActivityDao _activityDao = ActivityDao();

  Future<int> insert(RunGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('goals', goal.toMap());
  }

  Future<int> update(RunGoal goal) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RunGoal>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('goals', orderBy: 'start_date DESC');
    return rows.map(RunGoal.fromMap).toList();
  }

  /// The goal of [type] ('weekly'/'monthly') whose date range contains [today].
  Future<RunGoal?> getActiveGoal(String type, String today) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'goals',
      where: 'type = ? AND start_date <= ? AND end_date >= ?',
      whereArgs: [type, today, today],
      orderBy: 'start_date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RunGoal.fromMap(rows.first);
  }

  /// Progress ratio (0.0 - 1.0+) = distance run within the goal's date range / target.
  Future<double> getProgress(RunGoal goal) async {
    final distance = await _activityDao.getDistanceInRange(goal.startDate, goal.endDate);
    if (goal.targetKm <= 0) return 0;
    return distance / goal.targetKm;
  }

  Future<double> getDistanceForGoal(RunGoal goal) {
    return _activityDao.getDistanceInRange(goal.startDate, goal.endDate);
  }
}
