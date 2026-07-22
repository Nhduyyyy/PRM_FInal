import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/badge_dao.dart';
import '../db/database_helper.dart';
import '../db/goal_dao.dart';
import '../db/models.dart';
import '../db/pedometer_dao.dart';
import '../db/profile_dao.dart';
import '../db/training_plan_dao.dart';
import '../db/user_dao.dart';
import '../db/user_level_dao.dart';
import '../db/weekly_challenge_dao.dart';
import '../db/workout_template_dao.dart';
import '../models/activity_type.dart';
import 'calorie_calculator.dart';
import 'location_service.dart';
import 'session_service.dart';
import 'weekly_challenge_service.dart';

class _RouteBase {
  final String name;
  final double lat;
  final double lng;
  final double altitude;
  const _RouteBase(this.name, this.lat, this.lng, this.altitude);
}

/// Fills the `demo`/`demo123` account with ~10 weeks of believable running
/// history (varied routes, paces, notes, an active streak, partially
/// completed training plan, goals, badges, weekly challenges, pedometer
/// data...) so every screen in the app has something realistic to show
/// without hand-recording dozens of real GPS runs first.
///
/// Debug/demo tooling only — wired up behind a `kDebugMode` button in
/// [BackupRestoreScreen], never called from a production code path.
class DemoSeedService {
  static const demoUsername = 'demo';
  static const demoPassword = 'demo123';

  static const _routeBases = [
    _RouteBase('Công viên Tao Đàn', 10.7769, 106.6929, 9),
    _RouteBase('Bờ kè Nhiêu Lộc', 10.7889, 106.6797, 6),
    _RouteBase('Quanh khu dân cư', 10.8012, 106.7145, 11),
  ];
  static const _hikeBase = _RouteBase('Núi Bà Đen', 11.3652, 106.1689, 420);

  static const _notePool = [
    'Cảm thấy sung sức hôm nay!',
    'Trời hơi nóng nhưng vẫn ổn.',
    'Chạy cùng nhóm bạn, vui lắm.',
    'Chân hơi mỏi ở km cuối.',
    'Pace tốt hơn tuần trước rồi!',
    'Buổi sáng mát mẻ, chạy rất thoải mái.',
    'Hôm nay hơi mệt, chắc do thiếu ngủ.',
    'Cung đường quen thuộc, chạy rất thư giãn.',
  ];
  static const _moodPool = ['😄', '😊', '💪', '🥵', '😌', '🙂'];

  static const _planStartOffsetDays = 17;

  final _userDao = UserDao();
  final _profileDao = ProfileDao();
  final _activityDao = ActivityDao();
  final _goalDao = GoalDao();
  final _badgeDao = BadgeDao();
  final _levelDao = UserLevelDao();
  final _planDao = TrainingPlanDao();
  final _templateDao = WorkoutTemplateDao();
  final _pedometerDao = PedometerDao();
  final _weeklyChallengeDao = WeeklyChallengeDao();
  final _weeklyChallengeService = WeeklyChallengeService();

  final _rng = Random(42);
  static final _fmtDate = DateFormat('yyyy-MM-dd');

  /// Creates (or reuses) the demo account, logs the current session into
  /// it, wipes any previously seeded data for it, and repopulates
  /// everything from scratch. Safe to call repeatedly.
  Future<void> seedDemoAccount() async {
    final userId = await _ensureDemoUser();
    await SessionService.instance.setCurrentUser(userId);
    await _wipeUserData(userId);

    final profile = await _seedProfile();
    final templates = await _seedWorkoutTemplates();
    final planDays = await _planDao.getPlanDays(1);
    final planStartDate = DateTime.now().subtract(const Duration(days: _planStartOffsetDays));

    final activities = _buildActivities(
      profile: profile,
      templates: templates,
      planDays: planDays,
      planStartDate: planStartDate,
    );

    for (final activity in activities) {
      await _activityDao.insert(activity);
      final streak = await _profileDao.updateStreak(activity.date);
      final totalKm = await _activityDao.getTotalDistance();
      await _badgeDao.checkAndUnlockBadges(
        totalKm: totalKm,
        currentStreak: streak.currentStreak,
        lastRunKm: activity.distanceKm,
      );
      await _levelDao.addXp(activity.xpEarned);
    }

    await _planDao.startPlan(1, _fmtDate.format(planStartDate));
    await _seedGoals();
    await _seedWeeklyChallenges();
    await _seedPedometer();
  }

  Future<int> _ensureDemoUser() async {
    if (await _userDao.usernameExists(demoUsername)) {
      final id = await _userDao.verifyPassword(demoUsername, demoPassword);
      if (id != null) return id;
    }
    return _userDao.createUser(demoUsername, demoPassword);
  }

  Future<void> _wipeUserData(int userId) async {
    final db = await DatabaseHelper.instance.database;
    for (final table in [
      'activities',
      'goals',
      'user_badges',
      'streak_info',
      'active_plan',
      'user_level',
      'workout_templates',
      'daily_steps',
      'weekly_challenges',
      'user_profile',
    ]) {
      await db.delete(table, where: 'user_id = ?', whereArgs: [userId]);
    }
  }

  Future<UserProfile> _seedProfile() async {
    const profile = UserProfile(
      name: 'Minh Khôi',
      weightKg: 66,
      heightCm: 172,
      unit: 'km',
      themeMode: 'system',
      dailyReminderEnabled: true,
      dailyReminderTime: '06:00',
      goalReminderEnabled: true,
    );
    await _profileDao.saveProfile(profile);
    return profile;
  }

  Future<List<WorkoutTemplate>> _seedWorkoutTemplates() async {
    final now = DateTime.now();
    final drafts = [
      WorkoutTemplate(
        name: 'Interval 400m x 6',
        configJson: jsonEncode([
          for (var i = 0; i < 6; i++) ...[
            const IntervalSegment(type: 'fast', mode: 'distance', value: 400, targetPaceSecPerKm: 300).toJson(),
            const IntervalSegment(type: 'recover', mode: 'distance', value: 200).toJson(),
          ],
        ]),
        createdAt: now.subtract(const Duration(days: 25)).toIso8601String(),
      ),
      WorkoutTemplate(
        name: 'Interval 1 phút / 2 phút',
        configJson: jsonEncode([
          for (var i = 0; i < 8; i++) ...[
            const IntervalSegment(type: 'fast', mode: 'duration', value: 60, targetPaceSecPerKm: 280).toJson(),
            const IntervalSegment(type: 'recover', mode: 'duration', value: 120).toJson(),
          ],
        ]),
        createdAt: now.subtract(const Duration(days: 12)).toIso8601String(),
      ),
    ];

    final saved = <WorkoutTemplate>[];
    for (final draft in drafts) {
      final id = await _templateDao.insert(draft);
      saved.add(WorkoutTemplate(id: id, name: draft.name, configJson: draft.configJson, createdAt: draft.createdAt));
    }
    return saved;
  }

  List<RunActivity> _buildActivities({
    required UserProfile profile,
    required List<WorkoutTemplate> templates,
    required List<TrainingPlanDay> planDays,
    required DateTime planStartDate,
  }) {
    final today = DateTime.now();
    final planStartDateStr = _fmtDate.format(planStartDate);
    final result = <RunActivity>[];

    for (var daysAgo = 69; daysAgo >= 0; daysAgo--) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: daysAgo));
      final dateStr = _fmtDate.format(date);

      final activity = daysAgo <= _planStartOffsetDays
          ? _buildPlanDayActivity(
              date: date,
              dateStr: dateStr,
              daysAgo: daysAgo,
              planDay: _planDao.dayForDate(planDays, planStartDateStr, date),
              profile: profile,
              templates: templates,
            )
          : _buildHistoricalActivity(date: date, dateStr: dateStr, daysAgo: daysAgo, profile: profile);

      if (activity != null) result.add(activity);
    }

    return result;
  }

  /// Days within the training plan's elapsed window: follows the plan's own
  /// schedule, but the most recent 6 days always log *something* (even a
  /// light walk on a scheduled rest day) so the demo shows a live streak.
  RunActivity? _buildPlanDayActivity({
    required DateTime date,
    required String dateStr,
    required int daysAgo,
    required TrainingPlanDay? planDay,
    required UserProfile profile,
    required List<WorkoutTemplate> templates,
  }) {
    final mustLog = daysAgo <= 5;

    if (planDay == null || planDay.dayType == 'rest') {
      if (mustLog) {
        return _buildRoute(
          date: date,
          dateStr: dateStr,
          type: ActivityType.walk,
          distanceKm: 1.8 + _rng.nextDouble() * 0.9,
          paceSecPerKm: 620 + _rng.nextInt(60),
          profile: profile,
          note: 'Đi bộ nhẹ ngày nghỉ, giữ chuỗi streak.',
          mood: '🙂',
        );
      }
      if (_rng.nextDouble() < 0.22) {
        return _buildRoute(
          date: date,
          dateStr: dateStr,
          type: ActivityType.walk,
          distanceKm: 1.5 + _rng.nextDouble() * 1.0,
          paceSecPerKm: 620 + _rng.nextInt(80),
          profile: profile,
        );
      }
      return null;
    }

    if (!mustLog && _rng.nextDouble() < 0.12) return null;

    if (planDay.dayType == 'interval') {
      final template = templates[_rng.nextInt(templates.length)];
      return _buildRoute(
        date: date,
        dateStr: dateStr,
        type: ActivityType.run,
        distanceKm: 3.0 + _rng.nextDouble() * 1.5,
        paceSecPerKm: 330 + _rng.nextInt(40),
        profile: profile,
        note: 'Bài interval theo giáo án — ${template.name}.',
        mood: '💪',
        workoutMode: 'plan',
        planDayId: planDay.id,
      );
    }

    final target = planDay.targetDistanceKm ?? 3.0;
    final distanceKm = target * (0.9 + _rng.nextDouble() * 0.2);
    final pace = planDay.dayType == 'long_run' ? 375 + _rng.nextInt(45) : 345 + _rng.nextInt(50);
    return _buildRoute(
      date: date,
      dateStr: dateStr,
      type: ActivityType.run,
      distanceKm: distanceKm,
      paceSecPerKm: pace,
      profile: profile,
      note: _rng.nextDouble() < 0.5 ? _pickNote() : null,
      mood: _rng.nextDouble() < 0.6 ? _pickMood() : null,
      workoutMode: 'plan',
      planDayId: planDay.id,
    );
  }

  /// Days before the training plan started: a generic history that grows
  /// busier, longer and faster the closer it gets to "today" (0 = oldest,
  /// 1 = fittest), like a runner easing into the habit.
  RunActivity? _buildHistoricalActivity({
    required DateTime date,
    required String dateStr,
    required int daysAgo,
    required UserProfile profile,
  }) {
    final p = (1 - (daysAgo - _planStartOffsetDays) / (69 - _planStartOffsetDays)).clamp(0.0, 1.0);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    var chance = 0.30 + 0.33 * p;
    if (isWeekend) chance += 0.15;
    if (_rng.nextDouble() > chance) return null;

    final longRun = isWeekend && p > 0.35 && _rng.nextDouble() < 0.55;
    final distMin = 2.0 + 3.0 * p;
    final distMax = 3.0 + 4.5 * p;
    var distanceKm = distMin + _rng.nextDouble() * (distMax - distMin);
    if (longRun) distanceKm *= 1.6;

    final paceMax = (465 - 90 * p).round();
    final paceMin = paceMax - 40;
    final pace = paceMin + _rng.nextInt(paceMax - paceMin + 1);

    var type = ActivityType.run;
    var effectivePace = pace;
    final roll = _rng.nextDouble();
    if (isWeekend && roll < 0.10) {
      type = ActivityType.cycle;
      distanceKm *= 2.6;
      effectivePace = 190 + _rng.nextInt(40);
    } else if (roll < 0.08) {
      type = ActivityType.walk;
      distanceKm *= 0.55;
      effectivePace = 620 + _rng.nextInt(80);
    } else if (isWeekend && p > 0.55 && roll > 0.94) {
      type = ActivityType.hike;
      distanceKm = 4.5 + _rng.nextDouble() * 3.0;
      effectivePace = 720 + _rng.nextInt(120);
    }

    return _buildRoute(
      date: date,
      dateStr: dateStr,
      type: type,
      distanceKm: distanceKm,
      paceSecPerKm: effectivePace,
      profile: profile,
      note: _rng.nextDouble() < 0.35 ? _pickNote() : null,
      mood: _rng.nextDouble() < 0.5 ? _pickMood() : null,
    );
  }

  RunActivity _buildRoute({
    required DateTime date,
    required String dateStr,
    required ActivityType type,
    required double distanceKm,
    required int paceSecPerKm,
    required UserProfile profile,
    String? note,
    String? mood,
    String workoutMode = 'free',
    String? intervalConfig,
    int? planDayId,
  }) {
    final base = type == ActivityType.hike ? _hikeBase : _routeBases[_rng.nextInt(_routeBases.length)];
    final morning = _rng.nextBool();
    final hour = morning ? 5 + _rng.nextInt(2) : 17 + _rng.nextInt(2);
    final minute = _rng.nextInt(60);
    final startTime = DateTime(date.year, date.month, date.day, hour, minute);

    final points = _generateRoute(
      centerLat: base.lat + (_rng.nextDouble() - 0.5) * 0.01,
      centerLng: base.lng + (_rng.nextDouble() - 0.5) * 0.01,
      targetDistanceKm: distanceKm,
      startTime: startTime,
      avgPaceSecPerKm: paceSecPerKm,
      baseAltitude: base.altitude,
      hilly: type == ActivityType.hike,
    );

    final distanceMeters = LocationService.totalDistanceMeters(points);
    final actualDistanceKm = distanceMeters / 1000.0;
    final durationSeconds = (points.last.t - points.first.t) ~/ 1000;
    final avgPace = LocationService.avgPaceSecPerKm(distanceMeters, durationSeconds);
    final bestPace = LocationService.bestPaceSecPerKm(points) ?? avgPace;
    final elevationGain = LocationService.elevationGain(points);
    final calories = CalorieCalculator.calculateCalories(
      durationSeconds: durationSeconds,
      weightKg: profile.weightKg,
      avgPaceSecPerKm: avgPace,
      activityType: type,
    );
    final xpEarned = actualDistanceKm * 10 * (workoutMode == 'plan' ? 1.2 : 1.0);

    return RunActivity(
      date: dateStr,
      distanceKm: double.parse(actualDistanceKm.toStringAsFixed(2)),
      durationSeconds: durationSeconds,
      avgPaceSecPerKm: avgPace,
      bestPaceSecPerKm: bestPace,
      calories: calories,
      routePolyline: jsonEncode(points.map((p) => p.toJson()).toList()),
      note: note,
      mood: mood,
      locationTag: base.name,
      createdAt: startTime.add(Duration(seconds: durationSeconds)).toIso8601String(),
      activityType: type.key,
      workoutMode: workoutMode,
      intervalConfig: intervalConfig,
      planDayId: planDayId,
      elevationGainM: double.parse(elevationGain.toStringAsFixed(1)),
      xpEarned: double.parse(xpEarned.toStringAsFixed(1)),
    );
  }

  /// A loop (or a few laps of one) around [centerLat]/[centerLng], sized so
  /// its actual walked length lands close to [targetDistanceKm] — mimics a
  /// runner repeating a favourite park loop rather than a perfect circle.
  List<RoutePoint> _generateRoute({
    required double centerLat,
    required double centerLng,
    required double targetDistanceKm,
    required DateTime startTime,
    required int avgPaceSecPerKm,
    required double baseAltitude,
    bool hilly = false,
  }) {
    final loops = max(1, (targetDistanceKm / 2.2).round());
    final radiusKm = targetDistanceKm / (2 * pi * loops);
    final latRadiusDeg = radiusKm / 111.0;
    final lngRadiusDeg = latRadiusDeg / cos(centerLat * pi / 180);
    final totalPoints = max(24, (targetDistanceKm * 1000 / 25).round());
    final totalDurationSec = (targetDistanceKm * avgPaceSecPerKm).round().clamp(60, 24 * 3600);
    final startMs = startTime.millisecondsSinceEpoch;

    final points = <RoutePoint>[];
    for (var i = 0; i <= totalPoints; i++) {
      final t = i / totalPoints;
      final angle = 2 * pi * loops * t;
      final jitter = (_rng.nextDouble() - 0.5) * 0.08;
      final lat = centerLat + latRadiusDeg * (1 + jitter) * sin(angle);
      final lng = centerLng + lngRadiusDeg * (1 + jitter) * cos(angle);
      final alt = baseAltitude + (hilly ? sin(angle * 1.3) * 25 + t * 40 : sin(angle * 3) * 2 + _rng.nextDouble());
      points.add(RoutePoint(
        lat: lat,
        lng: lng,
        t: startMs + (totalDurationSec * t * 1000).round(),
        alt: double.parse(alt.toStringAsFixed(1)),
      ));
    }
    return points;
  }

  String _pickNote() => _notePool[_rng.nextInt(_notePool.length)];
  String _pickMood() => _moodPool[_rng.nextInt(_moodPool.length)];

  Future<void> _seedGoals() async {
    final now = DateTime.now();
    final weekStart = WeeklyChallengeService.mondayOf(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final weekSoFar = await _activityDao.getDistanceInRange(_fmtDate.format(weekStart), _fmtDate.format(now));
    final monthSoFar = await _activityDao.getDistanceInRange(_fmtDate.format(monthStart), _fmtDate.format(now));

    final weeklyTarget = (weekSoFar / 0.7).clamp(15, 60).roundToDouble();
    final monthlyTarget = ((monthSoFar / 0.6).clamp(60, 250) / 5).round() * 5.0;

    await _goalDao.insert(RunGoal(
      type: 'weekly',
      targetKm: weeklyTarget,
      startDate: _fmtDate.format(weekStart),
      endDate: _fmtDate.format(weekEnd),
      createdAt: weekStart.toIso8601String(),
    ));

    await _goalDao.insert(RunGoal(
      type: 'monthly',
      targetKm: monthlyTarget,
      startDate: _fmtDate.format(monthStart),
      endDate: _fmtDate.format(monthEnd),
      createdAt: monthStart.toIso8601String(),
    ));
  }

  Future<void> _seedWeeklyChallenges() async {
    final now = DateTime.now();
    final thisWeekStart = WeeklyChallengeService.mondayOf(now);

    for (var weeksAgo = 3; weeksAgo >= 1; weeksAgo--) {
      final weekStart = thisWeekStart.subtract(Duration(days: 7 * weeksAgo));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final actual = await _activityDao.getDistanceInRange(_fmtDate.format(weekStart), _fmtDate.format(weekEnd));
      if (actual <= 0) continue;

      final target = ((actual * (0.85 + _rng.nextDouble() * 0.3)) * 2).round() / 2;
      final id = await _weeklyChallengeDao.insert(WeeklyChallenge(
        weekStartDate: _fmtDate.format(weekStart),
        targetKm: target,
      ));
      if (actual >= target) await _weeklyChallengeDao.markAchieved(id);
    }

    await _weeklyChallengeService.ensureCurrentChallenge();
  }

  Future<void> _seedPedometer() async {
    final now = DateTime.now();
    var cumulative = 500000 + _rng.nextInt(50000);
    for (var daysAgo = 6; daysAgo >= 0; daysAgo--) {
      final date = _fmtDate.format(now.subtract(Duration(days: daysAgo)));
      final baseline = cumulative;
      await _pedometerDao.recordReading(date, baseline);
      cumulative = baseline + 3500 + _rng.nextInt(6000);
      await _pedometerDao.recordReading(date, cumulative);
    }
  }
}
