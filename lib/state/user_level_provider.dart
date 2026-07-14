import 'package:flutter/material.dart';

import '../db/models.dart';
import '../db/user_level_dao.dart';

class UserLevelProvider extends ChangeNotifier {
  final UserLevelDao _dao = UserLevelDao();

  bool _loading = true;
  UserLevel _userLevel = const UserLevel();

  bool get loading => _loading;
  UserLevel get userLevel => _userLevel;
  LevelInfo get info => UserLevelDao.levelInfoForXp(_userLevel.totalXp);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _userLevel = await _dao.getUserLevel();
    _loading = false;
    notifyListeners();
  }
}
