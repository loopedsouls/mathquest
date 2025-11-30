import 'package:flutter/material.dart';
import '../../core/utils/sound_manager.dart';

/// Sound settings provider
class SoundProvider extends ChangeNotifier {
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
    // TODO: Load settings from SharedPreferences
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
    // TODO: Save settings to SharedPreferences
  }
}
