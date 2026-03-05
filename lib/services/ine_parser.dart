import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ine_data.dart';

/// Se encarga de interpretar los bloques de texto de la INE.
class INEParser {
  // Regex para código postal: 5 dígitos.
  static final RegExp _postalCodeRegex = RegExp(r'\b\d{5}\b');

  /// Parsea bloques de texto para extraer datos de INE.
  INEData parseINEData(List<TextBlock> blocks) {
    String fullName = '';
    String address = '';
    String postalCode = '';

    // Clasificar por zonas usando bounding boxes.
    final zoneData = _classifyByZone(blocks);

    fullName = zoneData['top_left'] ?? '';
    address = zoneData['bottom_left'] ?? '';

    // Buscar código postal en todos los bloques.
    for (final block in blocks) {
      final match = _postalCodeRegex.firstMatch(block.text);
      if (match != null) {
        postalCode = match.group(0) ?? '';
        break;
      }
    }

    return INEData(
      fullName: _cleanText(fullName),
      address: _cleanText(address),
      postalCode: postalCode.trim(),
    );
  }

  /// Clasifica bloques por zona (superior/inferior, izquierda/derecha).
  Map<String, String> _classifyByZone(List<TextBlock> blocks) {
    final Map<String, String> map = {
      'top_left': '',
      'bottom_left': '',
      'top_right': '',
      'bottom_right': '',
    };

    if (blocks.isEmpty) return map;

    double maxWidth = 0;
    double maxHeight = 0;

    for (final block in blocks) {
      final rect = block.boundingBox;
      if (rect.right > maxWidth) maxWidth = rect.right;
      if (rect.bottom > maxHeight) maxHeight = rect.bottom;
    }

    final midX = maxWidth / 2;
    final midY = maxHeight / 2;

    for (final block in blocks) {
      final rect = block.boundingBox;
      final centerX = (rect.left + rect.right) / 2;
      final centerY = (rect.top + rect.bottom) / 2;

      String zone;
      if (centerY < midY) {
        zone = 'top_';
      } else {
        zone = 'bottom_';
      }

      if (centerX < midX) {
        zone += 'left';
      } else {
        zone += 'right';
      }

      if (zone == 'top_left' && map['top_left']!.isEmpty) {
        // El nombre suele estar en la parte superior izquierda; solo tomamos el primer bloque.
        map['top_left'] = block.text;
      } else if (zone == 'bottom_left') {
        // El domicilio suele ocupar varios bloques en la parte inferior izquierda.
        final current = map['bottom_left'] ?? '';
        map['bottom_left'] = (current + ' ' + block.text).trim();
      } else {
        // Guardamos también el resto por si quieres depurar más adelante.
        final current = map[zone] ?? '';
        map[zone] = (current + ' ' + block.text).trim();
      }
    }

    return map;
  }

  /// Limpia texto removiendo caracteres especiales y espacios extra.
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-áéíóúÁÉÍÓÚñÑ/]'), '')
        .trim();
  }
}

