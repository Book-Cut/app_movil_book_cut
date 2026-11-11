import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colores.dart';

class EncabezadoUsuario extends StatelessWidget {
  final String linea1;
  final String linea2;
  final VoidCallback? onAtras;
  final VoidCallback? onAvatarTap;
  final String? fotoPerfil;
  final Widget? hijo;
  final Widget? accion;
  final bool redondearAbajo;

  const EncabezadoUsuario({
    super.key,
    required this.linea1,
    required this.linea2,
    this.onAtras,
    this.onAvatarTap,
    this.fotoPerfil,
    this.hijo,
    this.accion,
    this.redondearAbajo = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colores.azulOscuro,
          borderRadius: redondearAbajo
              ? const BorderRadius.vertical(bottom: Radius.circular(32))
              : BorderRadius.zero,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  onAtras != null ? 4 : 12,
                  20,
                  hijo != null || redondearAbajo ? 18 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onAtras != null)
                      IconButton(
                        tooltip: 'Volver',
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
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: fotoPerfil == null || fotoPerfil!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 38,
                                        color: Colores.gris,
                                      )
                                    : Image.network(
                                        fotoPerfil!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          size: 38,
                                          color: Colores.gris,
                                        ),
                                      ),
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
                                linea1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                              ),
                              Text(
                                linea2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colores.rosa,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
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
              if (hijo != null) ...[hijo!, const SizedBox(height: 18)],
            ],
          ),
        ),
      ),
    );
  }
}
