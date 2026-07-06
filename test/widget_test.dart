import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_finalproject/db/models.dart';
import 'package:flutter_finalproject/services/calorie_calculator.dart';
import 'package:flutter_finalproject/services/location_service.dart';
import 'package:flutter_finalproject/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('duration formats under an hour as mm:ss', () {
      expect(Formatters.duration(90), '01:30');
    });

    test('duration formats over an hour as hh:mm:ss', () {
      expect(Formatters.duration(3661), '01:01:01');
    });

    test('pace formats seconds per km as m\'ss"/km', () {
      expect(Formatters.pace(330), "5'30\"/km");
    });
  });

  group('CalorieCalculator', () {
    test('picks a higher MET for a faster pace', () {
      expect(CalorieCalculator.metForPace(250), 11);
      expect(CalorieCalculator.metForPace(350), 9);
      expect(CalorieCalculator.metForPace(500), 7);
    });

    test('calculates calories from MET, weight, and duration', () {
      final calories = CalorieCalculator.calculateCalories(
        durationSeconds: 3600,
        weightKg: 60,
        avgPaceSecPerKm: 500,
      );
      expect(calories, 420); // 7 MET * 60kg * 1h
    });
  });

  group('LocationService distance/pace math', () {
    test('totalDistanceMeters sums consecutive point distances', () {
      final points = [
        const RoutePoint(lat: 21.0278, lng: 105.8342, t: 0),
        const RoutePoint(lat: 21.0288, lng: 105.8342, t: 1000),
      ];
      final distance = LocationService.totalDistanceMeters(points);
      expect(distance, greaterThan(0));
    });

    test('bestPaceSecPerKm returns null when route is under 1km', () {
      final points = [
        const RoutePoint(lat: 21.0278, lng: 105.8342, t: 0),
        const RoutePoint(lat: 21.02785, lng: 105.8342, t: 1000),
      ];
      expect(LocationService.bestPaceSecPerKm(points), isNull);
    });
  });
}
