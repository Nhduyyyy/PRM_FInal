class UserProfile {
  final int id;
  final String name;
  final double weightKg;
  final double heightCm;
  final String unit; // 'km' or 'miles'
  final String themeMode; // 'system', 'light', 'dark'
  final bool dailyReminderEnabled;
  final String dailyReminderTime; // 'HH:mm'
  final bool goalReminderEnabled;

  const UserProfile({
    this.id = 1,
    required this.name,
    required this.weightKg,
    required this.heightCm,
    this.unit = 'km',
    this.themeMode = 'system',
    this.dailyReminderEnabled = false,
    this.dailyReminderTime = '18:00',
    this.goalReminderEnabled = false,
  });

  UserProfile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    String? unit,
    String? themeMode,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    bool? goalReminderEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      unit: unit ?? this.unit,
      themeMode: themeMode ?? this.themeMode,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      goalReminderEnabled: goalReminderEnabled ?? this.goalReminderEnabled,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'unit': unit,
        'theme_mode': themeMode,
        'daily_reminder_enabled': dailyReminderEnabled ? 1 : 0,
        'daily_reminder_time': dailyReminderTime,
        'goal_reminder_enabled': goalReminderEnabled ? 1 : 0,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        id: map['id'] as int? ?? 1,
        name: map['name'] as String,
        weightKg: (map['weight_kg'] as num).toDouble(),
        heightCm: (map['height_cm'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'km',
        themeMode: map['theme_mode'] as String? ?? 'system',
        dailyReminderEnabled: (map['daily_reminder_enabled'] as int? ?? 0) == 1,
        dailyReminderTime: map['daily_reminder_time'] as String? ?? '18:00',
        goalReminderEnabled: (map['goal_reminder_enabled'] as int? ?? 0) == 1,
      );
}

class RoutePoint {
  final double lat;
  final double lng;
  final int t; // milliseconds since epoch
  final double alt; // meters above sea level, 0 if unavailable

  const RoutePoint({required this.lat, required this.lng, required this.t, this.alt = 0});

  Map<String, Object?> toJson() => {'lat': lat, 'lng': lng, 't': t, 'alt': alt};

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        t: (json['t'] as num).toInt(),
        alt: (json['alt'] as num?)?.toDouble() ?? 0,
      );
}

class RunActivity {
  final int? id;
  final String date; // yyyy-MM-dd
  final double distanceKm;
  final int durationSeconds;
  final int avgPaceSecPerKm;
  final int bestPaceSecPerKm;
  final int calories;
  final String routePolyline; // JSON-encoded List<RoutePoint>
  final String? note;
  final String? mood; // emoji
  final String? photoPath;
  final String? locationTag;
  final String createdAt;
  final String activityType; // run | walk | cycle | hike
  final String workoutMode; // free | interval | plan
  final String? intervalConfig; // JSON, nullable
  final int? planDayId;
  final String? audioNotePath;
  final double elevationGainM;
  final double xpEarned;

  const RunActivity({
    this.id,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceSecPerKm,
    required this.bestPaceSecPerKm,
    required this.calories,
    required this.routePolyline,
    this.note,
    this.mood,
    this.photoPath,
    this.locationTag,
    required this.createdAt,
    this.activityType = 'run',
    this.workoutMode = 'free',
    this.intervalConfig,
    this.planDayId,
    this.audioNotePath,
    this.elevationGainM = 0,
    this.xpEarned = 0,
  });

  RunActivity copyWith({
    String? note,
    String? mood,
    String? photoPath,
    String? locationTag,
    String? audioNotePath,
  }) {
    return RunActivity(
      id: id,
      date: date,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      avgPaceSecPerKm: avgPaceSecPerKm,
      bestPaceSecPerKm: bestPaceSecPerKm,
      calories: calories,
      routePolyline: routePolyline,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      photoPath: photoPath ?? this.photoPath,
      locationTag: locationTag ?? this.locationTag,
      createdAt: createdAt,
      activityType: activityType,
      workoutMode: workoutMode,
      intervalConfig: intervalConfig,
      planDayId: planDayId,
      audioNotePath: audioNotePath ?? this.audioNotePath,
      elevationGainM: elevationGainM,
      xpEarned: xpEarned,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'avg_pace_sec_per_km': avgPaceSecPerKm,
        'best_pace_sec_per_km': bestPaceSecPerKm,
        'calories': calories,
        'route_polyline': routePolyline,
        'note': note,
        'mood': mood,
        'photo_path': photoPath,
        'location_tag': locationTag,
        'created_at': createdAt,
        'activity_type': activityType,
        'workout_mode': workoutMode,
        'interval_config': intervalConfig,
        'plan_day_id': planDayId,
        'audio_note_path': audioNotePath,
        'elevation_gain_m': elevationGainM,
        'xp_earned': xpEarned,
      };

  factory RunActivity.fromMap(Map<String, Object?> map) => RunActivity(
        id: map['id'] as int?,
        date: map['date'] as String,
        distanceKm: (map['distance_km'] as num).toDouble(),
        durationSeconds: map['duration_seconds'] as int,
        avgPaceSecPerKm: map['avg_pace_sec_per_km'] as int,
        bestPaceSecPerKm: map['best_pace_sec_per_km'] as int,
        calories: map['calories'] as int,
        routePolyline: map['route_polyline'] as String? ?? '[]',
        note: map['note'] as String?,
        mood: map['mood'] as String?,
        photoPath: map['photo_path'] as String?,
        locationTag: map['location_tag'] as String?,
        createdAt: map['created_at'] as String,
        activityType: map['activity_type'] as String? ?? 'run',
        workoutMode: map['workout_mode'] as String? ?? 'free',
        intervalConfig: map['interval_config'] as String?,
        planDayId: map['plan_day_id'] as int?,
        audioNotePath: map['audio_note_path'] as String?,
        elevationGainM: (map['elevation_gain_m'] as num?)?.toDouble() ?? 0,
        xpEarned: (map['xp_earned'] as num?)?.toDouble() ?? 0,
      );
}

class RunGoal {
  final int? id;
  final String type; // 'weekly' or 'monthly'
  final double targetKm;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final String createdAt;

  const RunGoal({
    this.id,
    required this.type,
    required this.targetKm,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'target_km': targetKm,
        'start_date': startDate,
        'end_date': endDate,
        'created_at': createdAt,
      };

  factory RunGoal.fromMap(Map<String, Object?> map) => RunGoal(
        id: map['id'] as int?,
        type: map['type'] as String,
        targetKm: (map['target_km'] as num).toDouble(),
        startDate: map['start_date'] as String,
        endDate: map['end_date'] as String,
        createdAt: map['created_at'] as String,
      );
}

class RunBadge {
  final int id;
  final String name;
  final String description;
  final String conditionType; // 'total_km', 'streak_days', 'single_run_km'
  final double conditionValue;
  final String icon;
  final String tier; // bronze | silver | gold | single

  const RunBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionType,
    required this.conditionValue,
    required this.icon,
    this.tier = 'single',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'condition_type': conditionType,
        'condition_value': conditionValue,
        'icon': icon,
        'tier': tier,
      };

  factory RunBadge.fromMap(Map<String, Object?> map) => RunBadge(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        conditionType: map['condition_type'] as String,
        conditionValue: (map['condition_value'] as num).toDouble(),
        icon: map['icon'] as String,
        tier: map['tier'] as String? ?? 'single',
      );
}

class UserBadge {
  final int? id;
  final int badgeId;
  final String unlockedAt;

  const UserBadge({this.id, required this.badgeId, required this.unlockedAt});

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'badge_id': badgeId,
        'unlocked_at': unlockedAt,
      };

  factory UserBadge.fromMap(Map<String, Object?> map) => UserBadge(
        id: map['id'] as int?,
        badgeId: map['badge_id'] as int,
        unlockedAt: map['unlocked_at'] as String,
      );
}

class StreakInfo {
  final int id;
  final int currentStreak;
  final int bestStreak;
  final String? lastRunDate;

  const StreakInfo({
    this.id = 1,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastRunDate,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_run_date': lastRunDate,
      };

  factory StreakInfo.fromMap(Map<String, Object?> map) => StreakInfo(
        id: map['id'] as int? ?? 1,
        currentStreak: map['current_streak'] as int? ?? 0,
        bestStreak: map['best_streak'] as int? ?? 0,
        lastRunDate: map['last_run_date'] as String?,
      );
}

class TrainingPlan {
  final int? id;
  final String name;
  final String? description;
  final int totalWeeks;
  final String? level; // beginner | intermediate | advanced

  const TrainingPlan({
    this.id,
    required this.name,
    this.description,
    required this.totalWeeks,
    this.level,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'total_weeks': totalWeeks,
        'level': level,
      };

  factory TrainingPlan.fromMap(Map<String, Object?> map) => TrainingPlan(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        totalWeeks: map['total_weeks'] as int,
        level: map['level'] as String?,
      );
}

class TrainingPlanDay {
  final int? id;
  final int planId;
  final int weekNumber;
  final int dayNumber; // 1-7 within the week
  final String dayType; // rest | easy_run | interval | long_run
  final double? targetDistanceKm;
  final int? targetDurationSeconds;
  final String? description;

  const TrainingPlanDay({
    this.id,
    required this.planId,
    required this.weekNumber,
    required this.dayNumber,
    required this.dayType,
    this.targetDistanceKm,
    this.targetDurationSeconds,
    this.description,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'plan_id': planId,
        'week_number': weekNumber,
        'day_number': dayNumber,
        'day_type': dayType,
        'target_distance_km': targetDistanceKm,
        'target_duration_seconds': targetDurationSeconds,
        'description': description,
      };

  factory TrainingPlanDay.fromMap(Map<String, Object?> map) => TrainingPlanDay(
        id: map['id'] as int?,
        planId: map['plan_id'] as int,
        weekNumber: map['week_number'] as int,
        dayNumber: map['day_number'] as int,
        dayType: map['day_type'] as String,
        targetDistanceKm: (map['target_distance_km'] as num?)?.toDouble(),
        targetDurationSeconds: map['target_duration_seconds'] as int?,
        description: map['description'] as String?,
      );
}

class ActivePlan {
  final int id;
  final int? planId;
  final String? startDate; // yyyy-MM-dd

  const ActivePlan({this.id = 1, this.planId, this.startDate});

  bool get hasActivePlan => planId != null && startDate != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'plan_id': planId,
        'start_date': startDate,
      };

  factory ActivePlan.fromMap(Map<String, Object?> map) => ActivePlan(
        id: map['id'] as int? ?? 1,
        planId: map['plan_id'] as int?,
        startDate: map['start_date'] as String?,
      );
}

class UserLevel {
  final int id;
  final double totalXp;
  final int currentLevel;

  const UserLevel({this.id = 1, this.totalXp = 0, this.currentLevel = 1});

  Map<String, Object?> toMap() => {
        'id': id,
        'total_xp': totalXp,
        'current_level': currentLevel,
      };

  factory UserLevel.fromMap(Map<String, Object?> map) => UserLevel(
        id: map['id'] as int? ?? 1,
        totalXp: (map['total_xp'] as num?)?.toDouble() ?? 0,
        currentLevel: map['current_level'] as int? ?? 1,
      );
}

class WorkoutTemplate {
  final int? id;
  final String name;
  final String configJson; // JSON-encoded list of segments
  final String createdAt;

  const WorkoutTemplate({
    this.id,
    required this.name,
    required this.configJson,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'config_json': configJson,
        'created_at': createdAt,
      };

  factory WorkoutTemplate.fromMap(Map<String, Object?> map) => WorkoutTemplate(
        id: map['id'] as int?,
        name: map['name'] as String,
        configJson: map['config_json'] as String,
        createdAt: map['created_at'] as String,
      );
}

/// One segment of an interval workout template, e.g. "fast 400m" or "recover 200m".
class IntervalSegment {
  final String type; // fast | recover
  final String mode; // distance | duration
  final double value; // meters (mode=distance) or seconds (mode=duration)
  final int? targetPaceSecPerKm;

  const IntervalSegment({
    required this.type,
    required this.mode,
    required this.value,
    this.targetPaceSecPerKm,
  });

  Map<String, Object?> toJson() => {
        'type': type,
        'mode': mode,
        'value': value,
        'targetPaceSecPerKm': targetPaceSecPerKm,
      };

  factory IntervalSegment.fromJson(Map<String, dynamic> json) => IntervalSegment(
        type: json['type'] as String,
        mode: json['mode'] as String,
        value: (json['value'] as num).toDouble(),
        targetPaceSecPerKm: (json['targetPaceSecPerKm'] as num?)?.toInt(),
      );
}

class DailyStepsEntry {
  final String date; // yyyy-MM-dd
  final int baselineSteps;
  final int lastSteps;

  const DailyStepsEntry({
    required this.date,
    required this.baselineSteps,
    required this.lastSteps,
  });

  int get stepsToday => (lastSteps - baselineSteps).clamp(0, 1 << 31);

  Map<String, Object?> toMap() => {
        'date': date,
        'baseline_steps': baselineSteps,
        'last_steps': lastSteps,
      };

  factory DailyStepsEntry.fromMap(Map<String, Object?> map) => DailyStepsEntry(
        date: map['date'] as String,
        baselineSteps: map['baseline_steps'] as int,
        lastSteps: map['last_steps'] as int,
      );
}

class WeeklyChallenge {
  final int? id;
  final String weekStartDate; // yyyy-MM-dd, Monday of the week
  final double targetKm;
  final bool achieved;

  const WeeklyChallenge({
    this.id,
    required this.weekStartDate,
    required this.targetKm,
    this.achieved = false,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'week_start_date': weekStartDate,
        'target_km': targetKm,
        'achieved': achieved ? 1 : 0,
      };

  factory WeeklyChallenge.fromMap(Map<String, Object?> map) => WeeklyChallenge(
        id: map['id'] as int?,
        weekStartDate: map['week_start_date'] as String,
        targetKm: (map['target_km'] as num).toDouble(),
        achieved: (map['achieved'] as int? ?? 0) == 1,
      );
}
