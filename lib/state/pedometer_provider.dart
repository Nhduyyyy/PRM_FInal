import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';

import '../db/pedometer_dao.dart';

/// Tracks today's step count independently of GPS runs, using the device's
/// step-count sensor via the `pedometer` package. The sensor reports a
/// cumulative count since last device boot, so [PedometerDao] stores a daily
/// baseline to derive "steps since midnight".
class PedometerProvider extends ChangeNotifier {
  final PedometerDao _dao = PedometerDao();
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  StreamSubscription<StepCount>? _sub;
  int _stepsToday = 0;
  bool _available = true;
  bool _started = false;

  int get stepsToday => _stepsToday;
  bool get available => _available;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final today = _fmt.format(DateTime.now());
    final existing = await _dao.getForDate(today);
    if (existing != null) {
      _stepsToday = existing.stepsToday;
      notifyListeners();
    }

    _sub = Pedometer.stepCountStream.listen(_onStepCount, onError: (_) {
      _available = false;
      notifyListeners();
    });
  }

  Future<void> _onStepCount(StepCount event) async {
    final today = _fmt.format(DateTime.now());
    final entry = await _dao.recordReading(today, event.steps);
    _stepsToday = entry.stepsToday;
    notifyListeners();
  }

  /// Cancels the sensor subscription and resets state, so a subsequent
  /// [start] (e.g. after logging into a different account) starts clean.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    _stepsToday = 0;
    _available = true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
