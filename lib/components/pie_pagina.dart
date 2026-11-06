import 'package:flutter/material.dart';

import '../core/colores.dart';

class PiePagina extends StatelessWidget {
  const PiePagina({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colores.azulOscuro,
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Text(
            'INFORMACIÓN DE CONTACTO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Kilómetro 6 Autopista Floridablanca #50-33, Floridablanca, Santander',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Gmail: Luis@bookcut.com',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 4),
          Text('Tel: +57 3175647890', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
