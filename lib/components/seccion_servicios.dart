import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../models/servicio.dart';
import '../services/servicios_service.dart';
import 'tarjeta_servicio.dart';

class SeccionServicios extends StatefulWidget {
  const SeccionServicios({super.key});

  @override
  State<SeccionServicios> createState() => _SeccionServiciosState();
}

class _SeccionServiciosState extends State<SeccionServicios> {
  late Future<List<Servicio>> _servicios;

  @override
  void initState() {
    super.initState();
    _servicios = listarServicios();
  }

  void _reintentar() {
    setState(() {
      _servicios = listarServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const Text(
            'TU PRÓXIMO LOOK EMPIEZA AQUÍ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colores.gris,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NUESTROS SERVICIOS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colores.azulOscuro,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Servicio>>(
            future: _servicios,
            builder: (contexto, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Text('Cargando servicios...');
              }
              if (snap.hasError) {
                return Column(
                  children: [
                    const Text('No se pudieron cargar los servicios.'),
                    TextButton(
                      onPressed: _reintentar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                );
              }
              final servicios = snap.data ?? [];
              if (servicios.isEmpty) {
                return const Text('No hay servicios disponibles.');
              }
              return Column(
                children: servicios
                    .map((s) => TarjetaServicio(servicio: s))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
