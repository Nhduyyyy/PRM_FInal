import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/badge_dao.dart';
import '../db/models.dart';
import '../db/profile_dao.dart';
import '../services/calorie_calculator.dart';
import '../services/location_service.dart';

enum RunSessionState { idle, running, paused, finished }

class RunSaveResult {
  final RunActivity activity;
  final List<RunBadge> newBadges;
  final StreakInfo streak;

  const RunSaveResult({required this.activity, required this.newBadges, required this.streak});
}

class RunSessionProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ActivityDao _activityDao = ActivityDao();
  final ProfileDao _profileDao = ProfileDao();
  final BadgeDao _badgeDao = BadgeDao();

  RunSessionState _state = RunSessionState.idle;
  final List<RoutePoint> _points = [];

  DateTime? _segmentStartTime;
  Duration _accumulatedElapsed = Duration.zero;

  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;

  bool _gpsWeak = false;
  LocationAccessResult? _accessResult;

  RunSessionState get state => _state;
  List<RoutePoint> get points => List.unmodifiable(_points);
  bool get gpsWeak => _gpsWeak;
  LocationAccessResult? get accessResult => _accessResult;

  Duration get elapsed {
    if (_state == RunSessionState.running && _segmentStartTime != null) {
      return _accumulatedElapsed + DateTime.now().difference(_segmentStartTime!);
    }
    return _accumulatedElapsed;
  }

  double get distanceMeters => LocationService.totalDistanceMeters(_points);
  double get distanceKm => distanceMeters / 1000.0;

  int get avgPaceSecPerKm =>
      LocationService.avgPaceSecPerKm(distanceMeters, elapsed.inSeconds);

  int get currentPaceSecPerKm =>
      LocationService.currentPaceSecPerKm(_points) ?? avgPaceSecPerKm;

  int get bestPaceSecPerKm =>
      LocationService.bestPaceSecPerKm(_points) ?? avgPaceSecPerKm;

  int estimatedCalories(double weightKg) => CalorieCalculator.calculateCalories(
        durationSeconds: elapsed.inSeconds,
        weightKg: weightKg,
        avgPaceSecPerKm: avgPaceSecPerKm,
      );

  Future<LocationAccessResult> start() async {
    _reset();
    final access = await _locationService.ensureAccess();
    _accessResult = access;
    if (access != LocationAccessResult.granted) {
      notifyListeners();
      return access;
    }

    _state = RunSessionState.running;
    _segmentStartTime = DateTime.now();
    _listenToPosition();
    _startTicker();
    notifyListeners();
    return access;
  }

  void pause() {
    if (_state != RunSessionState.running) return;
    _accumulatedElapsed = elapsed;
    _segmentStartTime = null;
    _positionSub?.pause();
    _ticker?.cancel();
    _state = RunSessionState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != RunSessionState.paused) return;
    _segmentStartTime = DateTime.now();
    _positionSub?.resume();
    _startTicker();
    _state = RunSessionState.running;
    notifyListeners();
  }

  void finish() {
    if (_state == RunSessionState.idle) return;
    _accumulatedElapsed = elapsed;
    _segmentStartTime = null;
    _positionSub?.cancel();
    _positionSub = null;
    _ticker?.cancel();
    _ticker = null;
    _state = RunSessionState.finished;
    notifyListeners();
  }

  Future<RunSaveResult> saveActivity({
    required double weightKg,
    String? note,
    String? mood,
    String? photoPath,
    String? locationTag,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final activity = RunActivity(
      date: dateStr,
      distanceKm: distanceKm,
      durationSeconds: elapsed.inSeconds,
      avgPaceSecPerKm: avgPaceSecPerKm,
      bestPaceSecPerKm: bestPaceSecPerKm,
      calories: estimatedCalories(weightKg),
      routePolyline: jsonEncode(_points.map((p) => p.toJson()).toList()),
      note: note,
      mood: mood,
      photoPath: photoPath,
      locationTag: locationTag,
      createdAt: now.toIso8601String(),
    );

    final id = await _activityDao.insert(activity);
    final savedActivity = activity.copyWith();
    final streak = await _profileDao.updateStreak(dateStr);
    final totalKm = await _activityDao.getTotalDistance();
    final newBadges = await _badgeDao.checkAndUnlockBadges(
      totalKm: totalKm,
      currentStreak: streak.currentStreak,
      lastRunKm: distanceKm,
    );

    _reset();

    return RunSaveResult(
      activity: RunActivity.fromMap({...savedActivity.toMap(), 'id': id}),
      newBadges: newBadges,
      streak: streak,
    );
  }

  void discard() {
    _reset();
  }

  void _listenToPosition() {
    _positionSub = _locationService.getPositionStream().listen((position) {
      _gpsWeak = position.accuracy > 20;
      _points.add(RoutePoint(
        lat: position.latitude,
        lng: position.longitude,
        t: DateTime.now().millisecondsSinceEpoch,
      ));
      notifyListeners();
    });
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  void _reset() {
    _positionSub?.cancel();
    _positionSub = null;
    _ticker?.cancel();
    _ticker = null;
    _points.clear();
    _accumulatedElapsed = Duration.zero;
    _segmentStartTime = null;
    _gpsWeak = false;
    _state = RunSessionState.idle;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
