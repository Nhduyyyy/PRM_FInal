import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../db/activity_dao.dart';
import '../../db/models.dart';
import '../../widgets/empty_state.dart';

enum _HeatmapRange { all, thisMonth, thisYear }

/// Overlays every saved route on one map, low-opacity per line, so areas
/// run repeatedly render visibly darker — a quick visual of "vùng chạy quen thuộc".
class AllRoutesHeatmapScreen extends StatefulWidget {
  const AllRoutesHeatmapScreen({super.key});

  @override
  State<AllRoutesHeatmapScreen> createState() => _AllRoutesHeatmapScreenState();
}

class _AllRoutesHeatmapScreenState extends State<AllRoutesHeatmapScreen> {
  final _activityDao = ActivityDao();
  _HeatmapRange _range = _HeatmapRange.all;
  bool _loading = true;
  List<List<LatLng>> _routes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<RunActivity> activities;
    if (_range == _HeatmapRange.all) {
      activities = await _activityDao.getAll();
    } else {
      final now = DateTime.now();
      final start = _range == _HeatmapRange.thisMonth
          ? DateTime(now.year, now.month, 1)
          : DateTime(now.year, 1, 1);
      activities = await _activityDao.getInRange(
        DateFormat('yyyy-MM-dd').format(start),
        DateFormat('yyyy-MM-dd').format(now),
      );
    }

    final routes = <List<LatLng>>[];
    for (final activity in activities) {
      final points = (jsonDecode(activity.routePolyline) as List)
          .map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
          .toList();
      if (points.length > 1) {
        routes.add(points.map((p) => LatLng(p.lat, p.lng)).toList());
      }
    }

    if (mounted) {
      setState(() {
        _routes = routes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allPoints = _routes.expand((r) => r).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ hoạt động'),
        actions: [
          PopupMenuButton<_HeatmapRange>(
            initialValue: _range,
            onSelected: (v) {
              setState(() => _range = v);
              _load();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: _HeatmapRange.all, child: Text('Toàn bộ thời gian')),
              PopupMenuItem(value: _HeatmapRange.thisMonth, child: Text('Tháng này')),
              PopupMenuItem(value: _HeatmapRange.thisYear, child: Text('Năm nay')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : allPoints.isEmpty
              ? const Center(
                  child: EmptyState(
                    icon: Icons.map_outlined,
                    title: 'Chưa có lộ trình nào',
                    subtitle: 'Hoàn thành vài buổi chạy để xem bản đồ tổng hợp.',
                  ),
                )
              : FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(allPoints),
                      padding: const EdgeInsets.all(32),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_finalproject',
                    ),
                    PolylineLayer(
                      polylines: [
                        for (final route in _routes)
                          Polyline(
                            points: route,
                            strokeWidth: 3,
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
