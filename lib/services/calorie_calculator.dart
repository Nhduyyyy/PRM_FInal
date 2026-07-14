import '../models/activity_type.dart';

/// Simple MET-based calorie estimate — not medically precise, good enough
/// for a fitness-tracking hobby app.
///
/// calories = MET * weight_kg * duration_hours
class CalorieCalculator {
  /// Picks a MET value from average pace (seconds per km), scaled around the
  /// activity's base MET. Only running/walking speed up meaningfully enough
  /// to shift MET by pace; cycling/hiking use their base MET as-is.
  static double metForPace(int avgPaceSecPerKm, {ActivityType activityType = ActivityType.run}) {
    if (activityType != ActivityType.run) return activityType.baseMet;
    if (avgPaceSecPerKm <= 0) return 9;
    if (avgPaceSecPerKm < 300) return 11;
    if (avgPaceSecPerKm < 390) return 9;
    return 7;
  }

  static int calculateCalories({
    required int durationSeconds,
    required double weightKg,
    required int avgPaceSecPerKm,
    ActivityType activityType = ActivityType.run,
  }) {
    final met = metForPace(avgPaceSecPerKm, activityType: activityType);
    final durationHours = durationSeconds / 3600.0;
    return (met * weightKg * durationHours).round();
  }
}
