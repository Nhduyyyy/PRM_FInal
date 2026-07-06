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

  const RoutePoint({required this.lat, required this.lng, required this.t});

  Map<String, Object?> toJson() => {'lat': lat, 'lng': lng, 't': t};

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        t: (json['t'] as num).toInt(),
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
  });

  RunActivity copyWith({
    String? note,
    String? mood,
    String? photoPath,
    String? locationTag,
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

  const RunBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionType,
    required this.conditionValue,
    required this.icon,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'condition_type': conditionType,
        'condition_value': conditionValue,
        'icon': icon,
      };

  factory RunBadge.fromMap(Map<String, Object?> map) => RunBadge(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        conditionType: map['condition_type'] as String,
        conditionValue: (map['condition_value'] as num).toDouble(),
        icon: map['icon'] as String,
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
