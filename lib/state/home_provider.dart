import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/goal_dao.dart';
import '../db/models.dart';

class HomeProvider extends ChangeNotifier {
  final ActivityDao _activityDao = ActivityDao();
  final GoalDao _goalDao = GoalDao();

  bool _loading = true;
  RunGoal? _activeGoal;
  double _goalProgress = 0;
  List<RunActivity> _recentActivities = const [];

  bool get loading => _loading;
  RunGoal? get activeGoal => _activeGoal;
  double get goalProgress => _goalProgress;
  List<RunActivity> get recentActivities => _recentActivities;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _activeGoal = await _goalDao.getActiveGoal('weekly', today);
    if (_activeGoal != null) {
      _goalProgress = await _goalDao.getProgress(_activeGoal!);
    } else {
      _goalProgress = 0;
    }

    _recentActivities = await _activityDao.getRecent(3);

    _loading = false;
    notifyListeners();
  }
}
