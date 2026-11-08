import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../components/esqueleto.dart';
import '../models/cita.dart';
import '../services/citas_service.dart';

class PantallaMisCitas extends StatefulWidget {
  const PantallaMisCitas({super.key});

  @override
  State<PantallaMisCitas> createState() => _PantallaMisCitasState();
}

class _PantallaMisCitasState extends State<PantallaMisCitas> {
  List<Cita>? _citas;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final citas = await listarCitasCliente();
      if (!mounted) return;
      setState(() => _citas = citas);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar tus citas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final citas = _citas ?? const <Cita>[];
    final proximas = citas.where((cita) => !cita.esAnterior).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final anteriores = citas.where((cita) => cita.esAnterior).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Mis citas'),
        backgroundColor: Colores.azulOscuro,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: Colores.carmin,
        onRefresh: _cargarCitas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (_cargando && _citas == null)
              const EfectoEsqueleto(
                child: Column(
                  children: [
                    EsqueletoCita(),
                    EsqueletoCita(),
                    EsqueletoCita(),
                  ],
                ),
              )
            else if (_error != null)
              _errorCitas()
            else ...[
              _seccion(
                titulo: 'Próximas citas',
                citas: proximas,
                mensajeVacio: 'No tienes citas próximas.',
              ),
              const SizedBox(height: 28),
              _seccion(
                titulo: 'Citas anteriores',
                citas: anteriores,
                mensajeVacio: 'No tienes citas anteriores.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorCitas() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        const Icon(Icons.event_busy_outlined, size: 44, color: Colores.gris),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colores.gris),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _cargarCitas,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
  );

  Widget _seccion({
    required String titulo,
    required List<Cita> citas,
    required String mensajeVacio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colores.azulOscuro,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (citas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              mensajeVacio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.gris),
            ),
          )
        else
          ...citas.map(_tarjetaCita),
      ],
    );
  }

  Widget _tarjetaCita(Cita cita) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colores.azulOscuro,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fechaCompleta(cita.inicio),
                    style: const TextStyle(
                      color: Colores.azulOscuro,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${horaBonita(_hora(cita.inicio))} · ${cita.barbero}',
                    style: const TextStyle(color: Colores.gris),
                  ),
                ],
              ),
            ),
            _etiquetaEstado(cita),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        if (cita.servicios.isEmpty)
          const Text(
            'No hay servicios registrados en esta cita.',
            style: TextStyle(color: Colores.gris),
          )
        else
          ...cita.servicios.map(
            (servicio) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 17,
                    color: Colores.carmin,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      servicio.nombre,
                      style: const TextStyle(color: Colores.azulOscuro),
                    ),
                  ),
                  Text(
                    '${horaBonita(_hora(servicio.inicio))}'
                    '${servicio.duracion == null ? '' : ' · ${servicio.duracion} min'}',
                    style: const TextStyle(color: Colores.gris, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 16,
              color: Colores.gris,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${cita.modalidadPago} · Pago ${cita.estadoPago.toLowerCase()}',
                style: const TextStyle(color: Colores.gris, fontSize: 12),
              ),
            ),
          ],
        ),
        if (cita.confirmacionPendiente) ...[
          const SizedBox(height: 10),
          const Text(
            'Tu asistencia requiere confirmación.',
            style: TextStyle(
              color: Colores.carmin,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _etiquetaEstado(Cita cita) {
    final (fondo, texto) = switch (cita.estado) {
      'Confirmado' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'Pendiente' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'Cancelado' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'Finalizado' => (const Color(0xFFE4E4E7), const Color(0xFF3F3F46)),
      _ => (const Color(0xFFE4E4E7), Colores.gris),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cita.estado,
        style: TextStyle(
          color: texto,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _hora(DateTime fecha) =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  String _fechaCompleta(DateTime fecha) =>
      '${fecha.day} de ${nombresMeses[fecha.month - 1].toLowerCase()} de ${fecha.year}';
}
