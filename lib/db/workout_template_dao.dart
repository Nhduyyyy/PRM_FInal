import 'database_helper.dart';
import 'models.dart';

class WorkoutTemplateDao {
  Future<int> insert(WorkoutTemplate template) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('workout_templates', template.toMap());
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('workout_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WorkoutTemplate>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('workout_templates', orderBy: 'created_at DESC');
    return rows.map(WorkoutTemplate.fromMap).toList();
  }
}
