import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/goal_dao.dart';
import '../db/models.dart';

class PastGoal {
  final RunGoal goal;
  final double achievedKm;
  final bool achieved;

  const PastGoal({required this.goal, required this.achievedKm, required this.achieved});
}

class GoalsProvider extends ChangeNotifier {
  final GoalDao _goalDao = GoalDao();
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  RunGoal? _activeGoal;
  double _activeProgress = 0;
  List<PastGoal> _pastGoals = const [];

  bool get loading => _loading;
  RunGoal? get activeGoal => _activeGoal;
  double get activeProgress => _activeProgress;
  List<PastGoal> get pastGoals => _pastGoals;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final today = _fmt.format(DateTime.now());
    final all = await _goalDao.getAll();

    RunGoal? active;
    final past = <PastGoal>[];
    for (final goal in all) {
      final isActive = goal.startDate.compareTo(today) <= 0 && goal.endDate.compareTo(today) >= 0;
      if (isActive && (active == null || goal.startDate.compareTo(active.startDate) > 0)) {
        if (active != null) {
          final achievedKm = await _goalDao.getDistanceForGoal(active);
          past.add(PastGoal(goal: active, achievedKm: achievedKm, achieved: achievedKm >= active.targetKm));
        }
        active = goal;
      } else if (!isActive) {
        final achievedKm = await _goalDao.getDistanceForGoal(goal);
        past.add(PastGoal(goal: goal, achievedKm: achievedKm, achieved: achievedKm >= goal.targetKm));
      }
    }

    _activeGoal = active;
    _activeProgress = active != null ? await _goalDao.getProgress(active) : 0;
    past.sort((a, b) => b.goal.startDate.compareTo(a.goal.startDate));
    _pastGoals = past;

    _loading = false;
    notifyListeners();
  }

  Future<void> createGoal({required String type, required double targetKm}) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    if (type == 'weekly') {
      start = now.subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }

    final goal = RunGoal(
      type: type,
      targetKm: targetKm,
      startDate: _fmt.format(DateTime(start.year, start.month, start.day)),
      endDate: _fmt.format(DateTime(end.year, end.month, end.day)),
      createdAt: now.toIso8601String(),
    );
    await _goalDao.insert(goal);
    await load();
  }

  Future<void> updateGoal(RunGoal goal, {required double targetKm}) async {
    final updated = RunGoal(
      id: goal.id,
      type: goal.type,
      targetKm: targetKm,
      startDate: goal.startDate,
      endDate: goal.endDate,
      createdAt: goal.createdAt,
    );
    await _goalDao.update(updated);
    await load();
  }
}
