import 'package:flutter/material.dart';

import '../db/models.dart';
import '../utils/formatters.dart';
import 'route_map_view.dart';

/// A shareable summary card for one activity: mini map + key stats + app
/// branding, captured to an image by [ShareCardPreviewScreen].
class ShareCardView extends StatelessWidget {
  final RunActivity activity;
  final List<RoutePoint> points;
  final Color backgroundColor;

  const ShareCardView({
    super.key,
    required this.activity,
    required this.points,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(height: 160, child: RouteMapView(points: points)),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'Quãng đường', value: Formatters.distanceKm(activity.distanceKm)),
              _Stat(label: 'Thời gian', value: Formatters.duration(activity.durationSeconds)),
              _Stat(label: 'Pace TB', value: Formatters.pace(activity.avgPaceSecPerKm)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.directions_run, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Run Tracker', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
