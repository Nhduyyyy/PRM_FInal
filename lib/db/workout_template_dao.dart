import '../services/session_service.dart';
import 'database_helper.dart';
import 'models.dart';

class WorkoutTemplateDao {
  Future<int> insert(WorkoutTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    final map = template.toMap()..['user_id'] = SessionService.instance.requireUserId;
    return db.insert('workout_templates', map);
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      'workout_templates',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, SessionService.instance.requireUserId],
    );
  }

  Future<List<WorkoutTemplate>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'workout_templates',
      where: 'user_id = ?',
      whereArgs: [SessionService.instance.requireUserId],
      orderBy: 'created_at DESC',
    );
    return rows.map(WorkoutTemplate.fromMap).toList();
  }
}
