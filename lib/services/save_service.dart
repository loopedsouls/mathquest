import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const String _saveKey = 'game_save';

  Future<void> saveProgress(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, data);
  }

  Future<String?> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_saveKey);
  }

  Future<void> deleteProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}
