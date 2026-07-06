import 'package:flutter/material.dart';

/// Maps the `icon` key stored on a badge row to a concrete Material icon.
IconData badgeIconFor(String key) {
  switch (key) {
    case 'flag':
      return Icons.flag;
    case 'directions_run':
      return Icons.directions_run;
    case 'timeline':
      return Icons.timeline;
    case 'emoji_events':
      return Icons.emoji_events;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'whatshot':
      return Icons.whatshot;
    default:
      return Icons.military_tech;
  }
}
