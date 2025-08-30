import 'package:flutter/services.dart';

class AssetLoader {
  /// Carrega asset de imagem de forma assíncrona
  static Future<Uint8List> loadImage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  /// Carrega múltiplos assets em paralelo
  static Future<List<Uint8List>> preloadImages(List<String> assetPaths) async {
    return Future.wait(assetPaths.map(loadImage));
  }
}
