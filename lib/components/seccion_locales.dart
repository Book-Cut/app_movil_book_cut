import 'package:flutter/material.dart';

import '../core/colores.dart';
import 'tarjeta_local.dart';

class SeccionLocales extends StatelessWidget {
  const SeccionLocales({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Text(
            'VISÍTANOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colores.gris,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Encuentra tu Book&Cut',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
          SizedBox(height: 24),
          TarjetaLocal(
            nombre: 'Floridablanca',
            direccion: 'Kilómetro 6 Autopista Floridablanca #50-33, Floridablanca, Santander',
            horario: 'Lunes a viernes, 8:00 a 20:00',
          ),
          TarjetaLocal(
            nombre: 'Bucaramanga',
            direccion: 'Cl. 15 #27-37, Bucaramanga, Santander',
            horario: 'Lunes a viernes, 8:00 a 20:00',
          ),
        ],
      ),
    );
  }
}
