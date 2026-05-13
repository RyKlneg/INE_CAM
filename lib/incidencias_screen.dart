import 'package:flutter/material.dart';
import 'services/inegi_service.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final InegiService _inegiService = InegiService();
  
  String? _selectedEstadoId;
  String? _selectedMunicipioId;

  List<Map<String, String>> _estados = [];
  List<Map<String, String>> _municipios = [];

  bool _isLoadingGeo = false;
  bool _isLoadingData = false;
  
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _loadEstados();
  }

  Future<void> _loadEstados() async {
    setState(() => _isLoadingGeo = true);
    try {
      final estados = await _inegiService.getEstados();
      setState(() {
        _estados = estados;
        _isLoadingGeo = false;
      });
    } catch (e) {
      setState(() => _isLoadingGeo = false);
      _showError('Error al cargar estados: $e');
    }
  }

  Future<void> _loadMunicipios(String estadoId) async {
    setState(() {
      _isLoadingGeo = true;
      _municipios = [];
      _selectedMunicipioId = null;
    });
    try {
      final municipios = await _inegiService.getMunicipios(estadoId);
      setState(() {
        _municipios = municipios;
        _isLoadingGeo = false;
      });
    } catch (e) {
      setState(() => _isLoadingGeo = false);
      _showError('Error al cargar municipios: $e');
    }
  }



  Future<void> _searchIncidencias() async {
    if (_selectedEstadoId == null || _selectedMunicipioId == null) {
      _showError('Por favor selecciona estado y municipio');
      return;
    }

    final estadoNom = _estados.firstWhere((e) => e['id'] == _selectedEstadoId)['nombre']!;
    final municipioNom = _municipios.firstWhere((m) => m['id'] == _selectedMunicipioId)['nombre']!;

    setState(() => _isLoadingData = true);
    try {
      final data = await _inegiService.getIncidencias(
        estadoId: _selectedEstadoId!,
        municipioId: _selectedMunicipioId!,
        estadoNombre: estadoNom,
        municipioNombre: municipioNom,
      );
      setState(() {
        _results = data;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showError('Error al buscar incidencias: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Módulo de Incidencias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0044CC),
              Color(0xFF001133),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSelectors(),
                const SizedBox(height: 32),
                _buildSearchButton(),
                const SizedBox(height: 40),
                if (_isLoadingData)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else if (_results != null)
                  _buildResults()
                else
                  _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consulta INEGI',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Obtén información sobre servicios y seguridad en tu zona.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _buildDropdown(
            label: 'Estado',
            value: _selectedEstadoId,
            items: _estados,
            onChanged: (val) {
              setState(() => _selectedEstadoId = val);
              if (val != null) _loadMunicipios(val);
            },
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'Municipio',
            value: _selectedMunicipioId,
            items: _municipios,
            onChanged: (val) {
              setState(() => _selectedMunicipioId = val);
            },
            icon: Icons.location_city_outlined,
            enabled: _selectedEstadoId != null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 0.1 : 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // Validación para evitar el error de "Assertion failed"
              value: (items.any((item) => item['id'] == value)) ? value : null,
              isExpanded: true,
              dropdownColor: const Color(0xFF001133),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              hint: Text(
                items.isEmpty && enabled ? 'Cargando...' : 'Selecciona $label', 
                style: const TextStyle(color: Colors.white38)
              ),
              onChanged: enabled && items.isNotEmpty ? onChanged : null,
              items: items.map((Map<String, String> item) {
                return DropdownMenuItem<String>(
                  value: item['id'],
                  child: Text(item['nombre'] ?? ''),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: _isLoadingGeo || _isLoadingData ? null : _searchIncidencias,
        icon: const Icon(Icons.search),
        label: const Text('BUSCAR INCIDENCIAS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mapa de Incidencias 2025',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitoreo en tiempo real de nodos municipales',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        // El Mapa ahora es el protagonista
        _buildMapSection(),
        
        const SizedBox(height: 32),
        const Text(
          'Estadísticas de la Zona',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Las tarjetas ahora son el soporte del mapa
        _buildDynamicCards(),
      ],
    );
  }

  Widget _buildDynamicCards() {
    final List<dynamic> items = _results!['items'] ?? [];
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildResultCard(
          title: item['titulo'] ?? 'Indicador',
          value: item['valor'] ?? 'Sin datos',
          icon: IconData(item['icon'] ?? 0xe3ab, fontFamily: 'MaterialIcons'),
          color: _getColorForTitle(item['titulo']),
        ),
      )).toList(),
    );
  }

  Color _getColorForTitle(String? title) {
    if (title == null) return Colors.blueAccent;
    if (title.contains('Agua')) return Colors.blueAccent;
    if (title.contains('Electricidad')) return Colors.amberAccent;
    if (title.contains('Seguridad')) return Colors.redAccent;
    return Colors.cyanAccent;
  }

  Widget _buildMapSection() {
    var rawZonas = _results!['zonas_afectadas'];
    List<dynamic> zonas = [];
    
    if (rawZonas is List) {
      zonas = rawZonas;
    } else if (rawZonas is String) {
      zonas = rawZonas.split(',').map((e) => {'nombre': e.trim(), 'lat': 0.0, 'lon': 0.0}).toList();
    }

    if (zonas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No hay datos cartográficos disponibles para esta zona en el INEGI',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mapa de Afectaciones (Nodos)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Puntos geográficos detectados en la zona',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withOpacity(0.2)),
              ),
              child: CustomPaint(
                painter: NodeMapPainter(zonas: zonas),
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            isExpanded: true,
            dropdownColor: const Color(0xFF001133),
            hint: const Text('Ver detalles por Colonia', style: TextStyle(color: Colors.white70)),
            items: zonas.map((z) {
              return DropdownMenuItem<String>(
                value: z['nombre'],
                child: Text(z['nombre'], style: const TextStyle(color: Colors.white, fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _showError('Seleccionado: $val\nEstado: Óptimo para reparación');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Selecciona una ubicación para ver las incidencias',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NodeMapPainter extends CustomPainter {
  final List<dynamic> zonas;
  NodeMapPainter({required this.zonas});

  @override
  void paint(Canvas canvas, Size size) {
    if (zonas.isEmpty) return;

    final paintNormal = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final paintIncident = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    final textStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 9,
      fontWeight: FontWeight.w300,
    );

    // Normalización de coordenadas
    double minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (var z in zonas) {
      if (z['lat'] < minLat) minLat = z['lat'];
      if (z['lat'] > maxLat) maxLat = z['lat'];
      if (z['lon'] < minLon) minLon = z['lon'];
      if (z['lon'] > maxLon) maxLon = z['lon'];
    }

    final List<Map<String, dynamic>> points = [];
    for (var z in zonas) {
      double x = (maxLon == minLon) ? size.width / 2 : ((z['lon'] - minLon) / (maxLon - minLon)) * size.width;
      double y = (maxLat == minLat) ? size.height / 2 : (1 - (z['lat'] - minLat) / (maxLat - minLat)) * size.height;
      
      // Ajustar margen para que las etiquetas no se corten
      x = 30 + (x * 0.7);
      y = 30 + (y * 0.7);
      
      points.add({'offset': Offset(x, y), 'nombre': z['nombre']});
    }

    // Dibujar malla de fondo
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        canvas.drawLine(points[i]['offset'], points[j]['offset'], paintLine);
      }
    }

    // Dibujar puntos y etiquetas
    for (int i = 0; i < points.length; i++) {
      final p = points[i]['offset'];
      final String nombre = points[i]['nombre'];
      
      // Si es de las primeras 3 (las que usamos para el reporte), marcar como incidencia
      bool isIncident = i < 3;
      
      if (isIncident) {
        // Efecto de pulso (simulado estáticamente con círculos concéntricos)
        final pulsePaint = Paint()..color = paintIncident.color.withOpacity(0.2)..style = PaintingStyle.fill;
        canvas.drawCircle(p, 10, pulsePaint);
        canvas.drawCircle(p, 6, paintIncident);
      } else {
        canvas.drawCircle(p, 4, paintNormal);
      }

      // Dibujar nombre de la colonia
      final textSpan = TextSpan(text: nombre, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.dx + 8, p.dy - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
