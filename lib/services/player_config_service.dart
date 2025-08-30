import 'package:shared_preferences/shared_preferences.dart';

class PlayerConfigService {
  static const String _bgmVolumeKey = 'player_bgm_volume';
  static const String _sfxVolumeKey = 'player_sfx_volume';
  static const String _textSpeedKey = 'player_text_speed';

  Future<void> setBgmVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_bgmVolumeKey, value);
  }

  Future<double> getBgmVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_bgmVolumeKey) ?? 1.0;
  }

  Future<void> setSfxVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sfxVolumeKey, value);
  }

  Future<double> getSfxVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sfxVolumeKey) ?? 1.0;
  }

  Future<void> setTextSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSpeedKey, value);
  }

  Future<double> getTextSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textSpeedKey) ?? 40.0;
  }
}
