import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/models.dart';

enum HistoryFilter { all, thisWeek, thisMonth }

class HistoryProvider extends ChangeNotifier {
  final ActivityDao _activityDao = ActivityDao();

  bool _loading = true;
  HistoryFilter _filter = HistoryFilter.all;
  List<RunActivity> _all = const [];

  bool get loading => _loading;
  HistoryFilter get filter => _filter;

  List<RunActivity> get activities {
    if (_filter == HistoryFilter.all) return _all;

    final now = DateTime.now();
    DateTime start;
    if (_filter == HistoryFilter.thisWeek) {
      start = now.subtract(Duration(days: now.weekday - 1));
    } else {
      start = DateTime(now.year, now.month, 1);
    }
    final startStr = DateFormat('yyyy-MM-dd').format(DateTime(start.year, start.month, start.day));
    return _all.where((a) => a.date.compareTo(startStr) >= 0).toList();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _activityDao.getAll();
    _loading = false;
    notifyListeners();
  }

  void setFilter(HistoryFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> deleteActivity(int id) async {
    await _activityDao.delete(id);
    _all = _all.where((a) => a.id != id).toList();
    notifyListeners();
  }
}
