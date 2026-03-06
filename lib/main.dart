import 'dart:io';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/ine_data.dart';
import 'services/ine_service.dart';

void main() {
  runApp(DevicePreview(
    enabled: true,
    builder: (context) => const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escaneo INE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const INEScannerScreen(),
    );
  }
}

class INEScannerScreen extends StatefulWidget {
  const INEScannerScreen({super.key});

  @override
  State<INEScannerScreen> createState() => _INEScannerScreenState();
}

class _INEScannerScreenState extends State<INEScannerScreen> {
  final INEService _ineService = INEService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;

  @override
  void dispose() {
    _ineService.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _scanINEFromCamera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final XFile? xFile = await _ineService.captureFromCamera();
      if (xFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Usar la ruta directamente para evitar problemas con File en Windows
      final INEData ineData = await _ineService.processINEImage(xFile.path);

      // Crear File solo para mostrar la imagen
      final imageFile = File(xFile.path);
      
      setState(() {
        _selectedImage = imageFile;
        _nameController.text = ineData.fullName;
        _addressController.text = ineData.address;
        _postalCodeController.text = ineData.postalCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('INE escaneada exitosamente'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanINEFromGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final XFile? xFile = await _ineService.selectFromGallery();
      if (xFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Usar la ruta directamente para evitar problemas con File en Windows
      final INEData ineData = await _ineService.processINEImage(xFile.path);

      // Crear File solo para mostrar la imagen
      final imageFile = File(xFile.path);

      setState(() {
        _selectedImage = imageFile;
        _nameController.text = ineData.fullName;
        _addressController.text = ineData.address;
        _postalCodeController.text = ineData.postalCode;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de Credencial INE'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Captura la parte frontal de tu INE',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _scanINEFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Escanear INE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _scanINEFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _nameController.clear();
                            _addressController.clear();
                            _postalCodeController.clear();
                            _selectedImage = null;
                            _errorMessage = null;
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Limpiar',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: const [
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 12),
                    Text('Procesando imagen...'),
                  ],
                ),
              ),
            if (_errorMessage != null && _errorMessage!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Datos extraídos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Domicilio',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Código Postal',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos guardados')),
                  );
                  setState(() {
                    _nameController.clear();
                    _addressController.clear();
                    _postalCodeController.clear();
                    _selectedImage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar datos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
