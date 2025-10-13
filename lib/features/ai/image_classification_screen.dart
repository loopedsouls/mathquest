import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'image_classification_service.dart';

class ImageClassificationScreen extends StatefulWidget {
  const ImageClassificationScreen({super.key});

  @override
  State<ImageClassificationScreen> createState() =>
      _ImageClassificationScreenState();
}

class _ImageClassificationScreenState extends State<ImageClassificationScreen> {
  final ImageClassificationService _service = ImageClassificationService();
  File? _selectedImage;
  List<ImageLabel> _labels = [];
  bool _isLoading = false;

  Future<void> _pickAndClassifyImage() async {
    setState(() {
      _isLoading = true;
    });

    final image = await _service.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });

      final labels = await _service.classifyImage(image);
      setState(() {
        _labels = labels;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificação de Imagem'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndClassifyImage,
              child: const Text('Selecionar Imagem'),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_labels.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _labels.length,
                  itemBuilder: (context, index) {
                    final label = _labels[index];
                    return ListTile(
                      title: Text(label.label),
                      subtitle: Text(
                          'Confiança: ${(label.confidence * 100).toStringAsFixed(2)}%'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
