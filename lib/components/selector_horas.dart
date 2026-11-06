import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../core/fechas.dart';

class SelectorHoras extends StatelessWidget {
  final List<String> horas;
  final String? seleccionada;
  final ValueChanged<String> onSeleccionar;

  const SelectorHoras({
    super.key,
    required this.horas,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: horas.map((h) {
        final elegida = h == seleccionada;
        return GestureDetector(
          onTap: () => onSeleccionar(h),
          child: Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: elegida ? Colores.carmin : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: elegida ? Colores.carmin : const Color(0xFFE4E4E7),
              ),
            ),
            child: Text(
              horaBonita(h),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: elegida ? Colors.white : Colores.azulOscuro,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
