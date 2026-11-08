import 'package:flutter/material.dart';

import '../core/colores.dart';

class IndicadorPasosRegistro extends StatelessWidget {
  final int pasoActual;

  const IndicadorPasosRegistro({super.key, required this.pasoActual})
    : assert(pasoActual == 1 || pasoActual == 2);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PasoRegistro(
          indice: '1',
          texto: 'Datos',
          activo: pasoActual == 1,
          completado: pasoActual > 1,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: pasoActual > 1
                ? Colores.carmin.withValues(alpha: 0.55)
                : const Color(0xFFE4E4E7),
          ),
        ),
        _PasoRegistro(
          indice: '2',
          texto: 'Verificación',
          activo: pasoActual == 2,
        ),
      ],
    );
  }
}

class _PasoRegistro extends StatelessWidget {
  final String indice;
  final String texto;
  final bool activo;
  final bool completado;

  const _PasoRegistro({
    required this.indice,
    required this.texto,
    required this.activo,
    this.completado = false,
  });

  @override
  Widget build(BuildContext context) {
    final destacado = activo || completado;
    final color = destacado ? Colores.carmin : Colores.gris;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: destacado ? Colores.carmin : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: completado
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  indice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: activo ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
