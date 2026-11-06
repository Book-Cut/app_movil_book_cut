import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../models/servicio.dart';

class ServicioIcono extends StatelessWidget {
  final Servicio servicio;
  final bool seleccionado;
  final VoidCallback onTap;

  const ServicioIcono({
    super.key,
    required this.servicio,
    required this.seleccionado,
    required this.onTap,
  });

  IconData _icono() {
    final n = servicio.nombre.toLowerCase();
    if (n.contains('barba') || n.contains('afeit')) return Icons.face;
    if (n.contains('tint') || n.contains('color')) return Icons.palette;
    if (n.contains('peina') || n.contains('estilo')) return Icons.brush;
    return Icons.content_cut;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colores.carmin,
                border: Border.all(
                  color: seleccionado ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(_icono(), color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              servicio.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seleccionado ? Colores.rosa : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
