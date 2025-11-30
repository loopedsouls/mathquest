import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// import 'package:audioplayers/audioplayers.dart';
import '../constants/asset_paths.dart';

/// Manager for sound effects and music
/// Note: Requires audioplayers package to be added to pubspec.yaml
class SoundManager {
  SoundManager._();

  static final SoundManager _instance = SoundManager._();
  static SoundManager get instance => _instance;

  // Placeholder for AudioPlayer instances when package is added
  // final AudioPlayer _sfxPlayer = AudioPlayer();
  // final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isSfxEnabled = true;
  bool _isMusicEnabled = true;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.5;

  /// Initialize sound manager
  Future<void> init() async {
    // Load preferences
    if (kDebugMode) {
      print('SoundManager initialized');
    }
  }

  /// Play correct answer sound
  Future<void> playCorrect() async {
    if (!_isSfxEnabled) return;
    await _playSfx(AssetPaths.correctSound);
  }

  /// Play incorrect answer sound
  Future<void> playIncorrect() async {
    if (!_isSfxEnabled) return;
    await _playSfx(AssetPaths.incorrectSound);
  }

  /// Alias for playIncorrect
  Future<void> playWrong() async => playIncorrect();

  /// Play level complete sound
  Future<void> playLevelComplete() async {
    if (!_isSfxEnabled) return;
    await _playSfx(AssetPaths.levelCompleteSound);
  }

  /// Alias for playLevelComplete
  Future<void> playSuccess() async => playLevelComplete();

  /// Play button click sound
  Future<void> playButtonClick() async {
    if (!_isSfxEnabled) return;
    // Light haptic feedback as alternative
    HapticFeedback.lightImpact();
    await _playSfx(AssetPaths.buttonClickSound);
  }

  /// Alias for playButtonClick
  Future<void> playClick() async => playButtonClick();

  /// Play achievement unlock sound
  Future<void> playAchievementUnlock() async {
    if (!_isSfxEnabled) return;
    HapticFeedback.heavyImpact();
    await _playSfx(AssetPaths.achievementUnlockSound);
  }

  /// Play streak milestone sound
  Future<void> playStreakMilestone() async {
    if (!_isSfxEnabled) return;
    HapticFeedback.mediumImpact();
    await _playSfx(AssetPaths.streakMilestoneSound);
  }

  /// Start menu music
  Future<void> startMenuMusic() async {
    if (!_isMusicEnabled) return;
    await _playMusic(AssetPaths.menuTheme);
  }

  /// Start gameplay music
  Future<void> startGameplayMusic() async {
    if (!_isMusicEnabled) return;
    await _playMusic(AssetPaths.gameplayTheme);
  }

  /// Stop music
  Future<void> stopMusic() async {
    // await _musicPlayer.stop();
    if (kDebugMode) {
      print('Music stopped');
    }
  }

  /// Pause music
  Future<void> pauseMusic() async {
    // await _musicPlayer.pause();
    if (kDebugMode) {
      print('Music paused');
    }
  }

  /// Resume music
  Future<void> resumeMusic() async {
    if (!_isMusicEnabled) return;
    // await _musicPlayer.resume();
    if (kDebugMode) {
      print('Music resumed');
    }
  }

  /// Toggle sound effects
  void toggleSfx() {
    _isSfxEnabled = !_isSfxEnabled;
  }

  /// Toggle music
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      stopMusic();
    }
  }

  /// Set SFX volume (0.0 to 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Set music volume (0.0 to 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    // _musicPlayer.setVolume(_musicVolume);
  }

  /// Get SFX enabled status
  bool get isSfxEnabled => _isSfxEnabled;

  /// Get music enabled status
  bool get isMusicEnabled => _isMusicEnabled;

  /// Get SFX volume
  double get sfxVolume => _sfxVolume;

  /// Get music volume
  double get musicVolume => _musicVolume;

  Future<void> _playSfx(String assetPath) async {
    try {
      // await _sfxPlayer.setVolume(_sfxVolume);
      // await _sfxPlayer.play(AssetSource(assetPath));
      if (kDebugMode) {
        print('Playing SFX: $assetPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing SFX: $e');
      }
    }
  }

  Future<void> _playMusic(String assetPath) async {
    try {
      // await _musicPlayer.setVolume(_musicVolume);
      // await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      // await _musicPlayer.play(AssetSource(assetPath));
      if (kDebugMode) {
        print('Playing music: $assetPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing music: $e');
      }
    }
  }

  /// Dispose sound manager
  void dispose() {
    // _sfxPlayer.dispose();
    // _musicPlayer.dispose();
  }
}
