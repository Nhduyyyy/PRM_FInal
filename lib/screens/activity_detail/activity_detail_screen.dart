import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/activity_dao.dart';
import '../../db/models.dart';
import '../../models/activity_type.dart';
import '../../services/location_service.dart';
import '../../services/voice_memo_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/route_map_view.dart';
import 'route_replay_screen.dart';
import 'share_card_preview_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityDao _activityDao = ActivityDao();
  final VoiceMemoService _voiceMemoService = VoiceMemoService();
  RunActivity? _activity;
  bool _playingAudio = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _voiceMemoService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final activity = await _activityDao.getById(widget.activityId);
    if (mounted) setState(() => _activity = activity);
  }

  Future<void> _toggleAudioNote(String path) async {
    if (_playingAudio) {
      await _voiceMemoService.stopPlayback();
      setState(() => _playingAudio = false);
    } else {
      await _voiceMemoService.play(path);
      setState(() => _playingAudio = true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá hoạt động?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) {
      await _activityDao.delete(widget.activityId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _share() {
    final a = _activity;
    if (a == null) return;
    final text =
        'Tôi vừa chạy ${Formatters.distanceKm(a.distanceKm)} trong ${Formatters.duration(a.durationSeconds)} '
        '(pace ${Formatters.pace(a.avgPaceSecPerKm)}) với Run Tracker! 🏃';
    if (a.photoPath != null && File(a.photoPath!).existsSync()) {
      Share.shareXFiles([XFile(a.photoPath!)], text: text);
    } else {
      Share.share(text);
    }
  }

  List<double> _paceSegments(List<RoutePoint> points) {
    if (points.length < 2) return [];
    final n = points.length;
    final cumDist = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      cumDist[i] = cumDist[i - 1] + LocationService.distanceBetween(points[i - 1], points[i]);
    }
    final totalKm = (cumDist[n - 1] / 1000).floor();
    if (totalKm < 1) return [];

    final segments = <double>[];
    var segStartIdx = 0;
    var segStartDist = 0.0;
    for (var km = 1; km <= totalKm; km++) {
      final target = km * 1000.0;
      var idx = segStartIdx;
      while (idx < n && cumDist[idx] < target) {
        idx++;
      }
      if (idx >= n) idx = n - 1;
      final timeMs = points[idx].t - points[segStartIdx].t;
      final distM = cumDist[idx] - segStartDist;
      if (distM > 0) {
        segments.add((timeMs / 1000.0) / (distM / 1000.0));
      }
      segStartIdx = idx;
      segStartDist = cumDist[idx];
    }
    return segments;
  }

  List<FlSpot> _elevationSpots(List<RoutePoint> points) {
    if (points.length < 2) return [];
    final n = points.length;
    final cumDist = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      cumDist[i] = cumDist[i - 1] + LocationService.distanceBetween(points[i - 1], points[i]);
    }
    return [for (var i = 0; i < n; i++) FlSpot(cumDist[i] / 1000, points[i].alt)];
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    if (activity == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final points = (jsonDecode(activity.routePolyline) as List)
        .map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
        .toList();
    final paceSegments = _paceSegments(points);
    final scheme = Theme.of(context).colorScheme;
    final activityType = ActivityType.fromKey(activity.activityType);
    final elevationSpots = _elevationSpots(points);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(activityType.icon, size: 18),
            const SizedBox(width: 8),
            Text(Formatters.dateFriendly(activity.date)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _delete();
              if (value == 'share') _share();
              if (value == 'replay') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RouteReplayScreen(points: points)),
                );
              }
              if (value == 'share_card') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShareCardPreviewScreen(activity: activity, points: points),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'replay', child: Text('Xem lại lộ trình')),
              PopupMenuItem(value: 'share_card', child: Text('Tạo ảnh chia sẻ')),
              PopupMenuItem(value: 'share', child: Text('Chia sẻ nhanh')),
              PopupMenuItem(value: 'delete', child: Text('Xoá')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RouteMapView(points: points, interactive: true),
            ),
          ),
          if (activity.photoPath != null && File(activity.photoPath!).existsSync()) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(File(activity.photoPath!), height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _Stat(label: 'Quãng đường', value: Formatters.distanceKm(activity.distanceKm)),
              _Stat(label: 'Thời gian', value: Formatters.duration(activity.durationSeconds)),
              _Stat(label: 'Pace TB', value: Formatters.pace(activity.avgPaceSecPerKm)),
              _Stat(label: 'Pace tốt nhất', value: Formatters.pace(activity.bestPaceSecPerKm)),
              _Stat(label: 'Calo', value: '${activity.calories} kcal'),
              if (activity.elevationGainM > 0)
                _Stat(label: 'Độ cao leo', value: '${activity.elevationGainM.toStringAsFixed(0)} m'),
              if (activity.mood != null) _Stat(label: 'Cảm nhận', value: activity.mood!),
            ],
          ),
          if (activity.elevationGainM > 0 && elevationSpots.length > 1) ...[
            const SizedBox(height: 24),
            Text('Độ cao theo lộ trình', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: elevationSpots,
                      isCurved: true,
                      color: scheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: scheme.primary.withValues(alpha: 0.15)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (paceSegments.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Pace theo từng km', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}'),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < paceSegments.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(toY: paceSegments[i], color: scheme.primary, width: 16),
                      ]),
                  ],
                ),
              ),
            ),
          ],
          if (activity.audioNotePath != null && File(activity.audioNotePath!).existsSync()) ...[
            const SizedBox(height: 24),
            Text('Ghi âm cảm nhận', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _toggleAudioNote(activity.audioNotePath!),
              icon: Icon(_playingAudio ? Icons.stop : Icons.play_arrow),
              label: Text(_playingAudio ? 'Dừng' : 'Nghe lại'),
            ),
          ],
          if (activity.note != null && activity.note!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Ghi chú', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(activity.note!),
          ],
          if (activity.locationTag != null && activity.locationTag!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Chip(
              avatar: const Icon(Icons.place_outlined, size: 16),
              label: Text(activity.locationTag!),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
