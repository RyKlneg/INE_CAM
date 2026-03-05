import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  late final TextRecognizer _textRecognizer;

  OCRService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Extrae bloques de texto (con bounding boxes) de una imagen.
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw OCRException('El archivo no existe: $imagePath');
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.blocks;
    } catch (e) {
      throw OCRException('Error al procesar imagen: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class OCRException implements Exception {
  final String message;
  OCRException(this.message);

  @override
  String toString() => message;
}

