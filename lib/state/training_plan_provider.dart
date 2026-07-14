import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/models.dart';
import '../db/training_plan_dao.dart';

class TrainingPlanProvider extends ChangeNotifier {
  final TrainingPlanDao _dao = TrainingPlanDao();
  final ActivityDao _activityDao = ActivityDao();

  bool _loading = true;
  ActivePlan _active = const ActivePlan();
  TrainingPlan? _plan;
  List<TrainingPlanDay> _days = const [];
  TrainingPlanDay? _todayPlan;
  Set<int> _completedDayIds = const {};

  bool get loading => _loading;
  bool get hasActivePlan => _active.hasActivePlan;
  TrainingPlan? get plan => _plan;
  List<TrainingPlanDay> get days => _days;
  TrainingPlanDay? get todayPlan => _todayPlan;
  Set<int> get completedDayIds => _completedDayIds;
  ActivePlan get active => _active;

  bool isCompleted(TrainingPlanDay day) => day.id != null && _completedDayIds.contains(day.id);

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _active = await _dao.getActivePlan();
    _completedDayIds = await _activityDao.getCompletedPlanDayIds();

    if (_active.hasActivePlan) {
      _plan = await _dao.getPlanById(_active.planId!);
      _days = await _dao.getPlanDays(_active.planId!);
      _todayPlan = _dao.dayForDate(_days, _active.startDate!, DateTime.now());
    } else {
      _plan = null;
      _days = const [];
      _todayPlan = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> startPlan(int planId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _dao.startPlan(planId, today);
    await load();
  }

  Future<void> stopPlan() async {
    await _dao.stopActivePlan();
    await load();
  }
}
