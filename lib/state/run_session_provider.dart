import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/badge_dao.dart';
import '../db/models.dart';
import '../db/profile_dao.dart';
import '../db/user_level_dao.dart';
import '../models/activity_type.dart';
import '../services/calorie_calculator.dart';
import '../services/location_service.dart';
import '../services/voice_coach_service.dart';

enum RunSessionState { idle, running, paused, autoPaused, finished }

class RunSaveResult {
  final RunActivity activity;
  final List<RunBadge> newBadges;
  final StreakInfo streak;
  final UserLevel updatedLevel;
  final bool leveledUp;

  const RunSaveResult({
    required this.activity,
    required this.newBadges,
    required this.streak,
    required this.updatedLevel,
    required this.leveledUp,
  });
}

class RunSessionProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ActivityDao _activityDao = ActivityDao();
  final ProfileDao _profileDao = ProfileDao();
  final BadgeDao _badgeDao = BadgeDao();
  final UserLevelDao _userLevelDao = UserLevelDao();
  final VoiceCoachService _voiceCoach = VoiceCoachService();

  /// A run is considered "stationary" once this long has passed without a
  /// new GPS point — the position stream (see [LocationService.settings])
  /// only emits when the user has moved >=5m, so 10s of silence is
  /// equivalent to an average speed under 0.5 m/s (5m / 10s).
  static const Duration _autoPauseThreshold = Duration(seconds: 10);

  RunSessionState _state = RunSessionState.idle;
  final List<RoutePoint> _points = [];

  DateTime? _segmentStartTime;
  Duration _accumulatedElapsed = Duration.zero;
  DateTime? _lastMovementAt;

  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;

  bool _gpsWeak = false;
  LocationAccessResult? _accessResult;

  ActivityType _activityType = ActivityType.run;
  int? _planDayId;
  WorkoutTemplate? _template;
  List<IntervalSegment>? _segments;
  int _currentSegmentIndex = 0;
  int _segmentStartElapsedSec = 0;
  double _segmentStartDistanceKm = 0;

  bool _voiceEnabled = true;
  int _lastAnnouncedKm = 0;

  RunSessionState get state => _state;
  List<RoutePoint> get points => List.unmodifiable(_points);
  bool get gpsWeak => _gpsWeak;
  LocationAccessResult? get accessResult => _accessResult;
  bool get isAutoPaused => _state == RunSessionState.autoPaused;

  ActivityType get activityType => _activityType;
  int? get planDayId => _planDayId;
  WorkoutTemplate? get template => _template;
  List<IntervalSegment>? get segments => _segments;
  int get currentSegmentIndex => _currentSegmentIndex;

  bool get voiceEnabled => _voiceEnabled;
  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled) _voiceCoach.stop();
    notifyListeners();
  }

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

  double get elevationGainM => LocationService.elevationGain(_points);

  int estimatedCalories(double weightKg) => CalorieCalculator.calculateCalories(
        durationSeconds: elapsed.inSeconds,
        weightKg: weightKg,
        avgPaceSecPerKm: avgPaceSecPerKm,
        activityType: _activityType,
      );

  Future<LocationAccessResult> start({
    ActivityType activityType = ActivityType.run,
    WorkoutTemplate? template,
    int? planDayId,
  }) async {
    _reset();
    _activityType = activityType;
    _template = template;
    _planDayId = planDayId;

    if (template != null) {
      final decoded = jsonDecode(template.configJson) as List;
      _segments = decoded.map((e) => IntervalSegment.fromJson(e as Map<String, dynamic>)).toList();
    }

    final access = await _locationService.ensureAccess();
    _accessResult = access;
    if (access != LocationAccessResult.granted) {
      notifyListeners();
      return access;
    }

    _state = RunSessionState.running;
    _segmentStartTime = DateTime.now();
    _lastMovementAt = DateTime.now();
    if (_segments != null && _segments!.isNotEmpty) {
      _announceSegment(0);
    }
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
    if (_state != RunSessionState.paused && _state != RunSessionState.autoPaused) return;
    final wasManuallyPaused = _state == RunSessionState.paused;
    _segmentStartTime = DateTime.now();
    _lastMovementAt = DateTime.now();
    if (wasManuallyPaused) {
      _positionSub?.resume();
      _startTicker();
    }
    _state = RunSessionState.running;
    notifyListeners();
  }

  /// Unlike [pause], auto-pause keeps the position stream and ticker alive
  /// so we can detect movement resuming and auto-resume without user input.
  void _autoPause() {
    _accumulatedElapsed = elapsed;
    _segmentStartTime = null;
    _state = RunSessionState.autoPaused;
  }

  void _autoResume() {
    _segmentStartTime = DateTime.now();
    _state = RunSessionState.running;
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
    String? audioNotePath,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final workoutMode = _template != null ? 'interval' : (_planDayId != null ? 'plan' : 'free');
    final xpEarned = distanceKm * 10 * (_planDayId != null ? 1.2 : 1.0);

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
      activityType: _activityType.key,
      workoutMode: workoutMode,
      intervalConfig: _template?.configJson,
      planDayId: _planDayId,
      elevationGainM: elevationGainM,
      xpEarned: xpEarned,
      audioNotePath: audioNotePath,
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
    final (updatedLevel, leveledUp) = await _userLevelDao.addXp(xpEarned);

    _reset();

    return RunSaveResult(
      activity: RunActivity.fromMap({...savedActivity.toMap(), 'id': id}),
      newBadges: newBadges,
      streak: streak,
      updatedLevel: updatedLevel,
      leveledUp: leveledUp,
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
        alt: position.altitude,
      ));
      _lastMovementAt = DateTime.now();
      if (_state == RunSessionState.autoPaused) _autoResume();
      _announceKmIfNeeded();
      _maybeAdvanceSegment();
      notifyListeners();
    });
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == RunSessionState.running &&
          _lastMovementAt != null &&
          DateTime.now().difference(_lastMovementAt!) >= _autoPauseThreshold) {
        _autoPause();
      }
      _maybeAdvanceSegment();
      notifyListeners();
    });
  }

  void _announceKmIfNeeded() {
    if (!_voiceEnabled) return;
    final km = distanceKm.floor();
    if (km >= 1 && km > _lastAnnouncedKm) {
      _lastAnnouncedKm = km;
      final paceMin = avgPaceSecPerKm ~/ 60;
      final paceSec = avgPaceSecPerKm % 60;
      _voiceCoach.speak(
        'Bạn đã chạy $km ki lô mét. Pace trung bình $paceMin phút $paceSec giây.',
      );
    }
  }

  void _announceSegment(int index) {
    final segments = _segments;
    if (segments == null || index >= segments.length) return;
    final seg = segments[index];
    final typeLabel = seg.type == 'fast' ? 'chạy nhanh' : 'đi bộ hồi phục';
    if (_voiceEnabled) {
      _voiceCoach.speak('Bắt đầu hiệp ${index + 1} — $typeLabel.');
    }
  }

  void _maybeAdvanceSegment() {
    final segments = _segments;
    if (segments == null || _currentSegmentIndex >= segments.length) return;

    final seg = segments[_currentSegmentIndex];
    final elapsedInSegmentSec = elapsed.inSeconds - _segmentStartElapsedSec;
    final distInSegmentM = (distanceKm - _segmentStartDistanceKm) * 1000;

    final reached = seg.mode == 'duration' ? elapsedInSegmentSec >= seg.value : distInSegmentM >= seg.value;
    if (!reached) return;

    _currentSegmentIndex++;
    _segmentStartElapsedSec = elapsed.inSeconds;
    _segmentStartDistanceKm = distanceKm;

    if (_currentSegmentIndex < segments.length) {
      _announceSegment(_currentSegmentIndex);
    } else if (_voiceEnabled) {
      _voiceCoach.speak('Bạn đã hoàn thành bài tập interval. Làm tốt lắm!');
    }
  }

  void _reset() {
    _positionSub?.cancel();
    _positionSub = null;
    _ticker?.cancel();
    _ticker = null;
    _points.clear();
    _accumulatedElapsed = Duration.zero;
    _segmentStartTime = null;
    _lastMovementAt = null;
    _gpsWeak = false;
    _state = RunSessionState.idle;

    _activityType = ActivityType.run;
    _planDayId = null;
    _template = null;
    _segments = null;
    _currentSegmentIndex = 0;
    _segmentStartElapsedSec = 0;
    _segmentStartDistanceKm = 0;
    _lastAnnouncedKm = 0;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _ticker?.cancel();
    _voiceCoach.stop();
    super.dispose();
  }
}
