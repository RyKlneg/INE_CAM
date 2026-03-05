import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ine_data.dart';
import 'ine_parser.dart';
import 'ocr_service.dart';

/// Servicio de alto nivel para capturar y procesar INE.
class INEService {
  final OCRService _ocrService = OCRService();
  final INEParser _parser = INEParser();
  final ImagePicker _imagePicker = ImagePicker();

  /// Procesa una imagen de INE y extrae los datos principales.
  /// Acepta File o String path para mayor flexibilidad.
  Future<INEData> processINEImage(dynamic imageInput) async {
    try {
      String imagePath;
      
      // Manejar tanto File como String path
      if (imageInput is File) {
        if (!await imageInput.exists()) {
          throw INEServiceException('El archivo de imagen no existe.');
        }
        imagePath = imageInput.path;
      } else if (imageInput is String) {
        imagePath = imageInput;
      } else {
        throw INEServiceException('Tipo de entrada no válido. Se espera File o String.');
      }

      // Usar la ruta directamente para evitar problemas con File en Windows
      final List<TextBlock> textBlocks =
          await _ocrService.extractTextBlocks(imagePath);

      if (textBlocks.isEmpty) {
        throw INEServiceException('No se detectó texto en la imagen.');
      }

      final ineData = _parser.parseINEData(textBlocks);

      if (!ineData.isValid) {
        throw INEServiceException(
          'No se pudieron extraer suficientes datos. Verifica la calidad de la foto.',
        );
      }

      return ineData;
    } on INEServiceException {
      rethrow;
    } catch (e) {
      throw INEServiceException('Error inesperado al procesar la INE: $e');
    }
  }

  /// Captura una imagen desde la cámara.
  /// Retorna XFile directamente para evitar problemas de conversión en Windows.
  Future<XFile?> captureFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      return photo;
    } catch (e) {
      throw INEServiceException('Error al capturar imagen: $e');
    }
  }

  /// Selecciona una imagen desde la galería.
  /// Retorna XFile directamente para evitar problemas de conversión en Windows.
  Future<XFile?> selectFromGallery() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      throw INEServiceException('Error al seleccionar imagen: $e');
    }
  }

  void dispose() {
    _ocrService.dispose();
  }
}

class INEServiceException implements Exception {
  final String message;
  INEServiceException(this.message);

  @override
  String toString() => message;
}

