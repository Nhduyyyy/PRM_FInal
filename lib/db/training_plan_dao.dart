import 'database_helper.dart';
import 'models.dart';

class TrainingPlanDao {
  Future<List<TrainingPlan>> getAllPlans() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('training_plans', orderBy: 'id ASC');
    return rows.map(TrainingPlan.fromMap).toList();
  }

  Future<TrainingPlan?> getPlanById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('training_plans', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TrainingPlan.fromMap(rows.first);
  }

  Future<List<TrainingPlanDay>> getPlanDays(int planId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'training_plan_days',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'week_number ASC, day_number ASC',
    );
    return rows.map(TrainingPlanDay.fromMap).toList();
  }

  Future<TrainingPlanDay?> getPlanDayById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('training_plan_days', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TrainingPlanDay.fromMap(rows.first);
  }

  Future<ActivePlan> getActivePlan() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('active_plan', where: 'id = 1');
    if (rows.isEmpty) return const ActivePlan();
    return ActivePlan.fromMap(rows.first);
  }

  Future<void> startPlan(int planId, String startDate) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'active_plan',
      {'plan_id': planId, 'start_date': startDate},
      where: 'id = 1',
    );
  }

  Future<void> stopActivePlan() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'active_plan',
      {'plan_id': null, 'start_date': null},
      where: 'id = 1',
    );
  }

  /// The plan day that corresponds to [today] given the plan started on
  /// [startDate], or null if [today] falls after the plan's last day.
  TrainingPlanDay? dayForDate(
    List<TrainingPlanDay> days,
    String startDate,
    DateTime today,
  ) {
    final start = DateTime.parse(startDate);
    final offsetDays = DateTime(today.year, today.month, today.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
    if (offsetDays < 0 || offsetDays >= days.length) return null;
    return days[offsetDays];
  }
}
