import 'package:flutter/material.dart';

import '../core/colores.dart';

class TarjetaLocal extends StatelessWidget {
  final String nombre;
  final String direccion;
  final String horario;

  const TarjetaLocal({
    super.key,
    required this.nombre,
    required this.direccion,
    required this.horario,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(direccion),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colores.azulOscuro,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(horario)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
