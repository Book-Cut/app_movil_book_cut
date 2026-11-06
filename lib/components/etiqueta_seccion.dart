import 'package:flutter/material.dart';

import '../core/colores.dart';

class EtiquetaSeccion extends StatelessWidget {
  final String texto;
  final bool clara;

  const EtiquetaSeccion(this.texto, {super.key, this.clara = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: clara ? Colors.white : Colores.carmin,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(24),
          ),
          boxShadow: clara
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: clara ? Colores.azulOscuro : Colors.white,
          ),
        ),
      ),
    );
  }
}
