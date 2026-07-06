import 'package:flutter/material.dart';

import '../db/badge_dao.dart';
import '../db/models.dart';

class BadgeWithStatus {
  final RunBadge badge;
  final bool unlocked;
  final String? unlockedAt;

  const BadgeWithStatus({required this.badge, required this.unlocked, this.unlockedAt});
}

class BadgesProvider extends ChangeNotifier {
  final BadgeDao _badgeDao = BadgeDao();

  bool _loading = true;
  List<BadgeWithStatus> _badges = const [];

  bool get loading => _loading;
  List<BadgeWithStatus> get badges => _badges;
  int get unlockedCount => _badges.where((b) => b.unlocked).length;
  int get totalCount => _badges.length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final all = await _badgeDao.getAllBadges();
    final unlocked = await _badgeDao.getUnlockedBadges();
    final unlockedMap = {for (final u in unlocked) u.badgeId: u.unlockedAt};

    _badges = all
        .map((b) => BadgeWithStatus(
              badge: b,
              unlocked: unlockedMap.containsKey(b.id),
              unlockedAt: unlockedMap[b.id],
            ))
        .toList();

    _loading = false;
    notifyListeners();
  }
}
