import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/sound_manager.dart';

/// Sound settings provider
class SoundProvider extends ChangeNotifier {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _soundVolumeKey = 'sound_volume';
  static const String _musicVolumeKey = 'music_volume';

  final SoundManager _soundManager;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;

  SoundProvider(this._soundManager);

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _soundVolume = prefs.getDouble(_soundVolumeKey) ?? 1.0;
    _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.5;
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
    _saveSettings();
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    notifyListeners();
    _saveSettings();
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume;
    notifyListeners();
    _saveSettings();
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    notifyListeners();
    _saveSettings();
  }

  void playCorrectSound() {
    if (_soundEnabled) {
      _soundManager.playCorrect();
    }
  }

  void playWrongSound() {
    if (_soundEnabled) {
      _soundManager.playWrong();
    }
  }

  void playSuccessSound() {
    if (_soundEnabled) {
      _soundManager.playSuccess();
    }
  }

  void playClickSound() {
    if (_soundEnabled) {
      _soundManager.playClick();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, _soundEnabled);
    await prefs.setBool(_musicEnabledKey, _musicEnabled);
    await prefs.setDouble(_soundVolumeKey, _soundVolume);
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
  }
}
