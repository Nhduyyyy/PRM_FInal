import 'package:intl/intl.dart';

class Formatters {
  static String duration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// e.g. 1800 -> "5'30\"/km"
  static String pace(int secPerKm) {
    if (secPerKm <= 0) return "--'--\"";
    final m = secPerKm ~/ 60;
    final s = secPerKm % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }

  static String distanceKm(double km) => '${km.toStringAsFixed(2)} km';

  static String dateFriendly(String yyyyMMdd) {
    final date = DateTime.parse(yyyyMMdd);
    return DateFormat("EEEE, d 'Th'M", 'vi').format(date);
  }

  static String dateShort(String yyyyMMdd) {
    final date = DateTime.parse(yyyyMMdd);
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
