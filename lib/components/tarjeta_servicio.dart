import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../models/servicio.dart';

class TarjetaServicio extends StatelessWidget {
  final Servicio servicio;

  const TarjetaServicio({super.key, required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.content_cut, size: 40, color: Colores.azulOscuro),
            const SizedBox(height: 12),
            Text(
              servicio.nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              servicio.descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.gris),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Más adelante: ir al detalle del servicio
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.carmin,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Ver servicio y reservar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
