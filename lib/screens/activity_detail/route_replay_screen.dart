import 'package:flutter/material.dart';

import '../../db/models.dart';
import '../../widgets/route_replay_map_view.dart';

class RouteReplayScreen extends StatelessWidget {
  final List<RoutePoint> points;
  const RouteReplayScreen({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem lại lộ trình')),
      body: RouteReplayMapView(points: points),
    );
  }
}
