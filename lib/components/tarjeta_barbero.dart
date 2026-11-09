import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../models/barbero.dart';

class TarjetaBarbero extends StatelessWidget {
  final Barbero barbero;
  final VoidCallback onTap;

  const TarjetaBarbero({super.key, required this.barbero, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tieneFoto =
        barbero.fotoPerfil != null && barbero.fotoPerfil!.isNotEmpty;

    return Card(
      color: Colors.white,
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE4E4E7),
                child: ClipOval(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: tieneFoto
                        ? Image.network(
                            barbero.fotoPerfil!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              size: 34,
                              color: Color(0xFFA1A1AA),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 34,
                            color: Color(0xFFA1A1AA),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barbero.nombre,
                      style: const TextStyle(
                        color: Colores.carmin,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (barbero.especialidad.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        barbero.especialidad,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colores.gris,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colores.gris),
            ],
          ),
        ),
      ),
    );
  }
}
