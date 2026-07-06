import 'package:geolocator/geolocator.dart';

import '../db/models.dart';

enum LocationAccessResult { granted, serviceDisabled, permissionDenied, permissionDeniedForever, error }

class LocationService {
  static const LocationSettings settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  /// Checks service availability and requests permission if needed.
  /// Never throws — platform-level failures (e.g. missing Info.plist keys)
  /// are reported as [LocationAccessResult.error] instead of crashing.
  Future<LocationAccessResult> ensureAccess() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationAccessResult.serviceDisabled;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return LocationAccessResult.permissionDenied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationAccessResult.permissionDeniedForever;
      }
      return LocationAccessResult.granted;
    } catch (_) {
      return LocationAccessResult.error;
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition();
  }

  static double distanceBetween(RoutePoint a, RoutePoint b) {
    return Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
  }

  static double totalDistanceMeters(List<RoutePoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distanceBetween(points[i - 1], points[i]);
    }
    return total;
  }

  /// Pace over the trailing [windowMeters] of the route, for a smoother
  /// "current pace" readout than an instantaneous point-to-point speed.
  static int? currentPaceSecPerKm(List<RoutePoint> points, {double windowMeters = 250}) {
    if (points.length < 2) return null;

    var dist = 0.0;
    var startIdx = points.length - 1;
    for (var i = points.length - 1; i > 0; i--) {
      dist += distanceBetween(points[i - 1], points[i]);
      startIdx = i - 1;
      if (dist >= windowMeters) break;
    }
    if (dist <= 0) return null;

    final timeMs = points.last.t - points[startIdx].t;
    if (timeMs <= 0) return null;

    final paceSecPerKm = (timeMs / 1000.0) / (dist / 1000.0);
    return paceSecPerKm.round();
  }

  static int avgPaceSecPerKm(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0) return 0;
    return (durationSeconds / (distanceMeters / 1000.0)).round();
  }

  /// Best (fastest) pace of any contiguous 1km segment of the route.
  static int? bestPaceSecPerKm(List<RoutePoint> points) {
    final n = points.length;
    if (n < 2) return null;

    final cumDist = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      cumDist[i] = cumDist[i - 1] + distanceBetween(points[i - 1], points[i]);
    }
    if (cumDist[n - 1] < 1000) return null;

    var bestPace = double.infinity;
    var j = 0;
    for (var i = 0; i < n; i++) {
      if (j < i) j = i;
      while (j < n && cumDist[j] - cumDist[i] < 1000) {
        j++;
      }
      if (j >= n) break;

      final distWindow = cumDist[j] - cumDist[i];
      if (distWindow <= 0) continue;
      final timeWindowMs = points[j].t - points[i].t;
      if (timeWindowMs <= 0) continue;

      final scaledPaceSec = (timeWindowMs / 1000.0) * (1000 / distWindow);
      if (scaledPaceSec < bestPace) bestPace = scaledPaceSec;
    }

    return bestPace.isFinite ? bestPace.round() : null;
  }
}
