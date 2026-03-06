import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ine_data.dart';

/// Se encarga de interpretar los bloques de texto de la INE.
class INEParser {
  static final RegExp _postalCodeRegex = RegExp(r'\b\d{5}\b');

  /// Parsea bloques de texto para extraer datos de INE.
  INEData parseINEData(List<TextBlock> blocks) {
    // Ordenar bloques de arriba a abajo y concatenar en un único string.
    final sorted = List<TextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final allText = sorted.map((b) => b.text).join('\n');

    // Nombre: texto entre "NOMBRE" y "DOMICILIO".
    // Filtra la línea de SEXO y tokens cortos de ruido (e.g. "EA", "H").
    String fullName = _extractBetween(
      allText,
      RegExp(r'NOMBRE', caseSensitive: false),
      RegExp(r'DOMICILIO', caseSensitive: false),
      skipLine: RegExp(
        r'^\s*SEXO\b|^[A-Z]{1,3}$',
        caseSensitive: false,
      ),
    );

    // Domicilio: texto entre "DOMICILIO" y el primero de los marcadores de fin.
    // Se usan múltiples marcadores porque según la orientación de la foto, los
    // bloques de CURP/CLAVE o FECHA pueden aparecer en distinto orden Y.
    String address = _extractBetween(
      allText,
      RegExp(r'DOMICILIO', caseSensitive: false),
      RegExp(
        r'CURP|CLAVE\s+DE\s+ELECTOR|FECHA\s+DE\s+NACIMIENTO|AÑO\s+DE\s+REGISTRO',
        caseSensitive: false,
      ),
    );

    final postalCode = _extractPostalCode(blocks);

    // Fallback a clasificación por zona si los keywords no se encontraron.
    if (fullName.isEmpty || address.isEmpty) {
      final zoneData = _classifyByZone(blocks);
      if (fullName.isEmpty) fullName = zoneData['top_left'] ?? '';
      if (address.isEmpty) address = zoneData['bottom_left'] ?? '';
    }

    return INEData(
      fullName: _cleanLine(fullName),
      address: address.trim(),
      postalCode: postalCode.trim(),
    );
  }

  /// Extrae el texto que está entre [start] y [end] en [text].
  /// Omite líneas vacías y líneas que coincidan con [skipLine].
  String _extractBetween(
    String text,
    RegExp start,
    RegExp end, {
    RegExp? skipLine,
  }) {
    final startMatch = start.firstMatch(text);
    if (startMatch == null) return '';

    final afterStart = text.substring(startMatch.end);
    final endMatch = end.firstMatch(afterStart);
    final section = endMatch != null
        ? afterStart.substring(0, endMatch.start)
        : afterStart;

    return section
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !(skipLine?.hasMatch(l) ?? false))
        .join('\n');
  }

  /// Busca un código postal de 5 dígitos en todos los bloques.
  String _extractPostalCode(List<TextBlock> blocks) {
    for (final block in blocks) {
      final match = _postalCodeRegex.firstMatch(block.text);
      if (match != null) return match.group(0)!;
    }
    return '';
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

      final zone =
          '${centerY < midY ? 'top' : 'bottom'}_${centerX < midX ? 'left' : 'right'}';

      if (zone == 'top_left' && map['top_left']!.isEmpty) {
        map['top_left'] = block.text;
      } else if (zone == 'bottom_left') {
        final current = map['bottom_left'] ?? '';
        map['bottom_left'] = '$current ${block.text}'.trim();
      } else {
        final current = map[zone] ?? '';
        map[zone] = '$current ${block.text}'.trim();
      }
    }

    return map;
  }

  /// Limpia una línea de texto removiendo caracteres especiales y espacios extra.
  String _cleanLine(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-áéíóúÁÉÍÓÚñÑ/]'), '')
        .trim();
  }
}
