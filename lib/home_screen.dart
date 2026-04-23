import 'package:flutter/material.dart';
import 'main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0044CC), // Blue
              Color(0xFF001133), // Dark Blue
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Optional logo or icon can go here
            _buildHomeButton(
              context,
              icon: Icons.assignment_ind_outlined,
              label: 'REGISTRAR INE',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const INEScannerScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.people_alt_outlined,
              label: 'POBLACIÓN',
              onPressed: () {
                // Implement later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Módulo de Población en desarrollo')),
                );
              },
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onPressed
  }) {
    return Container(
      width: 300,
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
