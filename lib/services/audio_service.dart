import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  Future<void> playBgm(String assetPath, {double volume = 1.0}) async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource(assetPath), volume: volume);
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> playSfx(String assetPath, {double volume = 1.0}) async {
    await _sfxPlayer.play(AssetSource(assetPath), volume: volume);
  }

  Future<void> setBgmVolume(double volume) async {
    await _bgmPlayer.setVolume(volume);
  }

  Future<void> setSfxVolume(double volume) async {
    await _sfxPlayer.setVolume(volume);
  }
}
