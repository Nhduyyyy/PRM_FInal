import 'package:flutter/material.dart';

import '../db/models.dart';
import '../db/profile_dao.dart';
import '../services/notification_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileDao _profileDao = ProfileDao();

  UserProfile? _profile;
  StreakInfo _streak = const StreakInfo();
  bool _loading = true;

  UserProfile? get profile => _profile;
  StreakInfo get streak => _streak;
  bool get loading => _loading;
  bool get hasProfile => _profile != null;

  ThemeMode get themeMode {
    switch (_profile?.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    _profile = await _profileDao.getProfile();
    _streak = await _profileDao.getStreakInfo();
    _loading = false;
    notifyListeners();
  }

  Future<void> createProfile({
    required String name,
    required double weightKg,
    required double heightCm,
    required String unit,
  }) async {
    final profile = UserProfile(
      name: name,
      weightKg: weightKg,
      heightCm: heightCm,
      unit: unit,
    );
    await _profileDao.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _profileDao.saveProfile(updated);
    _profile = updated;
    notifyListeners();
  }

  Future<void> setThemeMode(String themeMode) async {
    if (_profile == null) return;
    await updateProfile(_profile!.copyWith(themeMode: themeMode));
  }

  Future<void> setUnit(String unit) async {
    if (_profile == null) return;
    await updateProfile(_profile!.copyWith(unit: unit));
  }

  Future<void> setDailyReminder({required bool enabled, required String time}) async {
    if (_profile == null) return;
    await updateProfile(_profile!.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderTime: time,
    ));

    if (enabled) {
      final parts = time.split(':');
      await NotificationService.instance.scheduleDailyReminder(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> setGoalReminder(bool enabled) async {
    if (_profile == null) return;
    await updateProfile(_profile!.copyWith(goalReminderEnabled: enabled));
  }

  Future<void> refreshStreak() async {
    _streak = await _profileDao.getStreakInfo();
    notifyListeners();
  }
}
