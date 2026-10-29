import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan ID pengguna yang sedang login agar sesi bertahan
/// setelah aplikasi ditutup (pengecekan sesi pada UC-01).
class SessionRepository {
  static const String _keyUserId = 'session_user_id';

  Future<int?> getSavedUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<void> saveUserId(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
