/// Simple MET-based calorie estimate — not medically precise, good enough
/// for a fitness-tracking hobby app.
///
/// calories = MET * weight_kg * duration_hours
class CalorieCalculator {
  /// Picks a MET value from average pace (seconds per km):
  /// faster than 5:00/km -> 11, faster than 6:30/km -> 9, otherwise 7.
  static double metForPace(int avgPaceSecPerKm) {
    if (avgPaceSecPerKm <= 0) return 9;
    if (avgPaceSecPerKm < 300) return 11;
    if (avgPaceSecPerKm < 390) return 9;
    return 7;
  }

  static int calculateCalories({
    required int durationSeconds,
    required double weightKg,
    required int avgPaceSecPerKm,
  }) {
    final met = metForPace(avgPaceSecPerKm);
    final durationHours = durationSeconds / 3600.0;
    return (met * weightKg * durationHours).round();
  }
}
