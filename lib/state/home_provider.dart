import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/goal_dao.dart';
import '../db/models.dart';
import '../services/weekly_challenge_service.dart';

class HomeProvider extends ChangeNotifier {
  final ActivityDao _activityDao = ActivityDao();
  final GoalDao _goalDao = GoalDao();
  final WeeklyChallengeService _weeklyChallengeService = WeeklyChallengeService();

  bool _loading = true;
  RunGoal? _activeGoal;
  double _goalProgress = 0;
  List<RunActivity> _recentActivities = const [];
  WeeklyChallenge? _weeklyChallenge;
  double _weeklyChallengeProgressKm = 0;

  bool get loading => _loading;
  RunGoal? get activeGoal => _activeGoal;
  double get goalProgress => _goalProgress;
  List<RunActivity> get recentActivities => _recentActivities;
  WeeklyChallenge? get weeklyChallenge => _weeklyChallenge;
  double get weeklyChallengeProgressKm => _weeklyChallengeProgressKm;

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

    _weeklyChallenge = await _weeklyChallengeService.ensureCurrentChallenge();
    if (_weeklyChallenge != null) {
      _weeklyChallengeProgressKm = await _weeklyChallengeService.progressKm(_weeklyChallenge!);
      await _weeklyChallengeService.markAchievedIfNeeded(_weeklyChallenge!, _weeklyChallengeProgressKm);
    } else {
      _weeklyChallengeProgressKm = 0;
    }

    _loading = false;
    notifyListeners();
  }
}
