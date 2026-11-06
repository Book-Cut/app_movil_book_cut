import 'package:flutter/material.dart';

import '../core/colores.dart';
import 'carrusel_beneficios.dart';

class HeroInicio extends StatelessWidget {
  final VoidCallback onReservar;
  final VoidCallback onBajar;

  const HeroInicio({
    super.key,
    required this.onReservar,
    required this.onBajar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Text(
            'ESTILO, PRECISIÓN Y CUIDADO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colores.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu estilo merece\nun buen corte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Encuentra tu servicio ideal y reserva tu próxima visita en Book&Cut.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colores.gris),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onReservar,
            icon: const Icon(Icons.event_available),
            label: const Text('Reservar cita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.carmin,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const CarruselBeneficios(),
          IconButton(
            onPressed: onBajar,
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 36,
            color: Colores.azulOscuro,
          ),
        ],
      ),
    );
  }
}
