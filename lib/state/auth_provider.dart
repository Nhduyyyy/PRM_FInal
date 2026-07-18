import 'package:flutter/foundation.dart';

import '../db/user_dao.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  final UserDao _userDao = UserDao();

  bool _isLoggedIn = false;
  String? errorMessage;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> restoreSession() async {
    await SessionService.instance.restore();
    _isLoggedIn = SessionService.instance.isLoggedIn;
    notifyListeners();
  }

  Future<bool> register(String username, String password) async {
    errorMessage = null;
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.';
      notifyListeners();
      return false;
    }
    if (await _userDao.usernameExists(trimmed)) {
      errorMessage = 'Tên đăng nhập đã tồn tại.';
      notifyListeners();
      return false;
    }

    final userId = await _userDao.createUser(trimmed, password);
    await SessionService.instance.setCurrentUser(userId);
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> login(String username, String password) async {
    errorMessage = null;
    final userId = await _userDao.verifyPassword(username.trim(), password);
    if (userId == null) {
      errorMessage = 'Tên đăng nhập hoặc mật khẩu không đúng.';
      notifyListeners();
      return false;
    }

    await SessionService.instance.setCurrentUser(userId);
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await SessionService.instance.clear();
    _isLoggedIn = false;
    notifyListeners();
  }
}
