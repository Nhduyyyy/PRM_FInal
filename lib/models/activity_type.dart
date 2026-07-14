import 'package:flutter/material.dart';

enum ActivityType {
  run('run', 'Chạy bộ', Icons.directions_run),
  walk('walk', 'Đi bộ', Icons.directions_walk),
  cycle('cycle', 'Đạp xe', Icons.directions_bike),
  hike('hike', 'Leo núi', Icons.terrain);

  final String key;
  final String label;
  final IconData icon;

  const ActivityType(this.key, this.label, this.icon);

  static ActivityType fromKey(String key) => ActivityType.values.firstWhere(
        (e) => e.key == key,
        orElse: () => ActivityType.run,
      );

  /// Base MET value at a moderate pace for this activity type; run further
  /// scales MET by pace in [CalorieCalculator.metForPace].
  double get baseMet => switch (this) {
        ActivityType.run => 9,
        ActivityType.walk => 3.5,
        ActivityType.cycle => 7.5,
        ActivityType.hike => 6,
      };
}
