import 'package:flutter/material.dart';

import '../core/colores.dart';

class EncabezadoUsuario extends StatelessWidget {
  final String linea1;
  final String linea2;
  final VoidCallback? onAtras;
  final VoidCallback? onAvatarTap;
  final String? fotoPerfil;
  final Widget? hijo;
  final Widget? accion;

  const EncabezadoUsuario({
    super.key,
    required this.linea1,
    required this.linea2,
    this.onAtras,
    this.onAvatarTap,
    this.fotoPerfil,
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
                      InkWell(
                        onTap: onAvatarTap,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: SizedBox(
                              width: 68,
                              height: 68,
                              child: fotoPerfil == null || fotoPerfil!.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Colores.gris,
                                    )
                                  : Image.network(
                                      fotoPerfil!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person,
                                        size: 42,
                                        color: Colores.gris,
                                      ),
                                    ),
                            ),
                          ),
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
