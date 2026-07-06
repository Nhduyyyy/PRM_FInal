import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../db/models.dart';

/// Renders a route polyline (and optionally a live position marker) on an
/// OpenStreetMap tile layer. Used by Running, Run Summary, and Activity
/// Detail screens.
class RouteMapView extends StatelessWidget {
  final List<RoutePoint> points;
  final bool interactive;
  final double borderRadius;

  const RouteMapView({
    super.key,
    required this.points,
    this.interactive = false,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latLngs = points.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = latLngs.isNotEmpty
        ? latLngs.last
        : const LatLng(21.0278, 105.8342); // Hanoi fallback when no GPS fix yet

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: latLngs.isEmpty
          ? Container(
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(Icons.map_outlined, color: scheme.onSurfaceVariant, size: 40),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                interactionOptions: InteractionOptions(
                  flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_finalproject',
                ),
                if (latLngs.length > 1)
                  PolylineLayer(polylines: [
                    Polyline(points: latLngs, strokeWidth: 4, color: scheme.primary),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    point: latLngs.last,
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}
