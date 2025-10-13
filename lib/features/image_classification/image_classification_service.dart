import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

class ImageClassificationService {
  final ImageLabeler _imageLabeler =
      ImageLabeler(options: ImageLabelerOptions());

  Future<List<ImageLabel>> classifyImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labels = await _imageLabeler.processImage(inputImage);
    return labels;
  }

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void dispose() {
    _imageLabeler.close();
  }
}
