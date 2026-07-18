import 'package:shared_preferences/shared_preferences.dart';

/// Holds the currently logged-in user's id in memory, backed by
/// SharedPreferences so the session survives app restarts.
class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  static const _prefsKey = 'current_user_id';

  int? currentUserId;

  bool get isLoggedIn => currentUserId != null;

  /// Requires an active session; throws if called before login.
  int get requireUserId {
    final id = currentUserId;
    if (id == null) {
      throw StateError('SessionService.requireUserId called with no active session');
    }
    return id;
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt(_prefsKey);
  }

  Future<void> setCurrentUser(int userId) async {
    currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, userId);
  }

  Future<void> clear() async {
    currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
