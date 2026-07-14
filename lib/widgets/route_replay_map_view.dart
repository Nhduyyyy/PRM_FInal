import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../db/models.dart';

/// Animates a marker along a saved route, driven by the real timestamps of
/// [RoutePoint.t], with play/pause and speed controls.
class RouteReplayMapView extends StatefulWidget {
  final List<RoutePoint> points;
  const RouteReplayMapView({super.key, required this.points});

  @override
  State<RouteReplayMapView> createState() => _RouteReplayMapViewState();
}

class _RouteReplayMapViewState extends State<RouteReplayMapView> {
  final MapController _mapController = MapController();
  Timer? _timer;
  double _elapsedMs = 0;
  double _speed = 1;
  bool _playing = false;
  late final List<int> _offsets;
  late final int _totalMs;

  @override
  void initState() {
    super.initState();
    final t0 = widget.points.isNotEmpty ? widget.points.first.t : 0;
    _offsets = widget.points.map((p) => p.t - t0).toList();
    _totalMs = _offsets.isEmpty ? 0 : _offsets.last;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  LatLng _positionAtElapsed(double elapsedMs) {
    final points = widget.points;
    if (points.length == 1) return LatLng(points[0].lat, points[0].lng);

    var idx = 0;
    while (idx < _offsets.length - 1 && _offsets[idx + 1] < elapsedMs) {
      idx++;
    }
    if (idx >= _offsets.length - 1) {
      final last = points.last;
      return LatLng(last.lat, last.lng);
    }

    final segStart = _offsets[idx];
    final segEnd = _offsets[idx + 1];
    final segDur = segEnd - segStart;
    final t = segDur <= 0 ? 0.0 : (elapsedMs - segStart) / segDur;
    final p1 = points[idx];
    final p2 = points[idx + 1];
    return LatLng(
      p1.lat + (p2.lat - p1.lat) * t,
      p1.lng + (p2.lng - p1.lng) * t,
    );
  }

  void _play() {
    if (_totalMs <= 0) return;
    if (_elapsedMs >= _totalMs) _elapsedMs = 0;
    _timer?.cancel();
    const tickMs = 100;
    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      setState(() {
        _elapsedMs += tickMs * _speed;
        if (_elapsedMs >= _totalMs) {
          _elapsedMs = _totalMs.toDouble();
          _pause();
        }
      });
      _followMarker();
    });
    setState(() => _playing = true);
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _followMarker() {
    try {
      final pos = _positionAtElapsed(_elapsedMs);
      _mapController.move(pos, _mapController.camera.zoom);
    } catch (_) {
      // Map not laid out yet; skip this frame's camera follow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latLngs = widget.points.map((p) => LatLng(p.lat, p.lng)).toList();
    if (latLngs.isEmpty) {
      return Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.map_outlined, color: scheme.onSurfaceVariant, size: 40),
      );
    }

    final markerPos = _positionAtElapsed(_elapsedMs);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latLngs.first,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_finalproject',
              ),
              PolylineLayer(polylines: [
                Polyline(points: latLngs, strokeWidth: 4, color: scheme.primary.withValues(alpha: 0.5)),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: markerPos,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _elapsedMs.clamp(0, _totalMs.toDouble()),
                  min: 0,
                  max: _totalMs <= 0 ? 1 : _totalMs.toDouble(),
                  onChanged: _totalMs <= 0
                      ? null
                      : (v) {
                          _pause();
                          setState(() => _elapsedMs = v);
                          _followMarker();
                        },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36),
                      onPressed: _totalMs <= 0 ? null : (_playing ? _pause : _play),
                    ),
                    Row(
                      children: [
                        for (final s in [1.0, 2.0, 4.0])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('${s.toInt()}x'),
                              selected: _speed == s,
                              onSelected: (_) => setState(() => _speed = s),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
