import 'package:flutter/material.dart';

import '../core/colores.dart';

class EncabezadoUsuario extends StatelessWidget {
  final String linea1;
  final String linea2;
  final VoidCallback? onAtras;
  final Widget? hijo;
  final Widget? accion;

  const EncabezadoUsuario({
    super.key,
    required this.linea1,
    required this.linea2,
    this.onAtras,
    this.hijo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colores.azulOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onAtras != null)
                    IconButton(
                      onPressed: onAtras,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Colores.gris,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              linea1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              linea2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colores.rosa,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ?accion,
                    ],
                  ),
                ],
              ),
            ),
            if (hijo != null) ...[hijo!, const SizedBox(height: 20)],
          ],
        ),
      ),
    );
  }
}
