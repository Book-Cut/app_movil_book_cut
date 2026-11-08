import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/colores.dart';
import '../providers/catalogo_providers.dart';
import 'esqueleto.dart';
import 'tarjeta_servicio.dart';

class SeccionServicios extends ConsumerWidget {
  const SeccionServicios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicios = ref.watch(serviciosProvider);
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
          servicios.when(
            loading: () => const EfectoEsqueleto(
              child: Column(
                children: [
                  _EsqueletoTarjetaServicio(),
                  _EsqueletoTarjetaServicio(),
                  _EsqueletoTarjetaServicio(),
                ],
              ),
            ),
            error: (_, _) => Column(
              children: [
                const Text('No se pudieron cargar los servicios.'),
                TextButton(
                  onPressed: () => ref.invalidate(serviciosProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            data: (datos) => datos.isEmpty
                ? const Text('No hay servicios disponibles.')
                : Column(
                    children: datos
                        .map((servicio) => TarjetaServicio(servicio: servicio))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EsqueletoTarjetaServicio extends StatelessWidget {
  const _EsqueletoTarjetaServicio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BloqueEsqueleto(ancho: 150, alto: 18),
          SizedBox(height: 12),
          BloqueEsqueleto(ancho: double.infinity, alto: 12),
          SizedBox(height: 8),
          BloqueEsqueleto(ancho: 210, alto: 12),
        ],
      ),
    );
  }
}
