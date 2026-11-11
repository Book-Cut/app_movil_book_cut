import 'dart:async';

import 'package:flutter/material.dart';

import '../components/esqueleto.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../models/cita.dart';
import '../services/citas_service.dart';
import '../services/disponibilidad_service.dart';
import '../services/valoraciones_service.dart';

class PantallaMisCitas extends StatefulWidget {
  const PantallaMisCitas({super.key});

  @override
  State<PantallaMisCitas> createState() => _PantallaMisCitasState();
}

class _PantallaMisCitasState extends State<PantallaMisCitas> {
  List<Cita>? _citas;
  String? _error;
  bool _cargando = true;
  Timer? _timerRefresco;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
    _timerRefresco = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_cargando) unawaited(_cargarCitas(silencioso: true));
    });
  }

  @override
  void dispose() {
    _timerRefresco?.cancel();
    super.dispose();
  }

  Future<void> _cargarCitas({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final citas = await listarCitasCliente();
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted || silencioso) return;
      setState(() => _error = error.mensaje);
    } catch (_) {
      if (!mounted || silencioso) return;
      setState(() => _error = 'No se pudieron cargar tus citas.');
    } finally {
      if (mounted && !silencioso) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarAsistencia(Cita cita) async {
    final citasPrevias = _citas;
    setState(() {
      _citas = _citas?.map((c) {
        if (c.id == cita.id) {
          return c.copyWith(
            estado: 'Confirmado',
            confirmacionPendiente: false,
          );
        }
        return c;
      }).toList();
    });

    try {
      await confirmarAsistenciaCita(cita.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Asistencia confirmada exitosamente! Tu turno está asegurado.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      final citasActualizadas = await listarCitasCliente();
      if (mounted) setState(() => _citas = citasActualizadas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _citas = citasPrevias);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.mensaje : 'No se pudo confirmar la asistencia.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _dialogoCancelar(Cita cita) async {
    final cancelar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Colores.carmin,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cancelar cita',
                  style: TextStyle(
                    color: Colores.azulOscuro,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Estás seguro de que deseas cancelar esta cita? Esta acción liberará tu turno y no se puede deshacer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colores.gris,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colores.azulOscuro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 22,
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${horaBonita(_hora(cita.inicio))} • ${cita.barbero}',
                                  style: const TextStyle(
                                    color: Colores.gris,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (cita.servicios.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.content_cut,
                              size: 15,
                              color: Colores.carmin,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cita.servicios.map((s) => s.nombre).join(', '),
                                style: const TextStyle(
                                  color: Colores.azulOscuro,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Sí, cancelar cita',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colores.azulOscuro,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Conservar mi cita',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (cancelar == true) {
      final citasPrevias = _citas;
      setState(() {
        _citas = _citas?.map((c) {
          if (c.id == cita.id) {
            return c.copyWith(
              estado: 'Cancelado',
              confirmacionPendiente: false,
            );
          }
          return c;
        }).toList();
      });

      try {
        await cancelarCitaCliente(cita.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        final citasActualizadas = await listarCitasCliente();
        if (mounted) setState(() => _citas = citasActualizadas);
      } catch (e) {
        if (!mounted) return;
        setState(() => _citas = citasPrevias);
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo cancelar',
                      style: TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e is ApiException
                          ? e.mensaje
                          : 'El servidor no pudo procesar la cancelación. Intenta de nuevo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colores.gris,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.azulOscuro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Entendido',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  void _abrirModalReagendar(Cita cita) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalReagendarCita(
        cita: cita,
        onReagendada: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cita reagendada exitosamente!'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarCitas();
        },
      ),
    );
  }

  void _abrirModalCalificar(Cita cita) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalCalificarCita(
        cita: cita,
        onCalificada: (valoracion) {
          setState(() {
            _citas = _citas
                ?.map((c) => c.id == cita.id ? c.copyWith(valoracion: valoracion) : c)
                .toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Gracias por tu calificación!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final citas = _citas ?? const <Cita>[];
    final futuras = citas.where((cita) => !cita.esAnterior).toList();
    final afectadas = futuras
        .where((cita) => cita.afectadaPendiente)
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final proximas = futuras
        .where((cita) => !cita.afectadaPendiente)
        .toList()
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
              if (afectadas.isNotEmpty) ...[
                _seccion(
                  titulo: 'Citas afectadas',
                  subtitulo:
                      'Tu barbero no podrá atender estas citas. Reagéndalas o cancélalas.',
                  citas: afectadas,
                  mensajeVacio: '',
                ),
                const SizedBox(height: 28),
              ],
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
    String? subtitulo,
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
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(color: Colores.gris, fontSize: 13),
          ),
        ],
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

  Widget _tarjetaCita(Cita cita) {
    final tieneAlertaConfirmacion =
        cita.confirmacionPendiente || cita.enVentanaConfirmacion;
    final minutosRestantes = cita.minutosRestantesConfirmacion;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: cita.afectadaPendiente
            ? Border.all(color: const Color(0xFFFCA5A5), width: 1.5)
            : null,
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
                      '${horaBonita(_hora(cita.inicio))} • ${cita.barbero}',
                      style: const TextStyle(color: Colores.gris),
                    ),
                  ],
                ),
              ),
              _etiquetaEstado(cita),
            ],
          ),
          if (cita.afectadaPendiente && cita.motivoAfectada != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Motivo del barbero: ${cita.motivoAfectada}',
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
              ),
            ),
          ],
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
                      '${servicio.duracion == null ? '' : ' • ${servicio.duracion} min'}',
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
                  cita.factura != null && cita.factura!.numero.isNotEmpty
                      ? '${cita.factura!.numero} · ${cita.factura!.metodoPago} · Pago ${cita.estadoPago.toLowerCase()}'
                      : '${cita.modalidadPago} · Pago ${cita.estadoPago.toLowerCase()}',
                  style: const TextStyle(color: Colores.gris, fontSize: 12),
                ),
              ),
              if (cita.total > 0)
                Text(
                  precioBonito(cita.total),
                  style: const TextStyle(
                    color: Colores.azulOscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          if (cita.estado == 'Finalizado') ...[
            const SizedBox(height: 12),
            if (cita.valoracion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < cita.valoracion!.puntuacion
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colores.dorado,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tu calificación: ${cita.valoracion!.puntuacion}/5',
                          style: const TextStyle(
                            color: Colores.azulOscuro,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (cita.valoracion!.comentario != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        cita.valoracion!.comentario!,
                        style: const TextStyle(
                          color: Colores.gris,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirModalCalificar(cita),
                  icon: const Icon(
                    Icons.star_outline_rounded,
                    color: Colores.dorado,
                    size: 18,
                  ),
                  label: const Text(
                    'Calificar cita',
                    style: TextStyle(
                      color: Colores.azulOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colores.dorado),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
          if (tieneAlertaConfirmacion) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colores.carmin,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '¿Asistirás a tu cita?',
                          style: TextStyle(
                            color: Colores.carmin,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (minutosRestantes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            '$minutosRestantes min restantes',
                            style: const TextStyle(
                              color: Colores.carmin,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Esta notificación tiene una duración de 30 minutos. Si no confirmas tu asistencia, la cita se cancelará automáticamente. Si no puedes asistir, puedes reagendarla.',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmarAsistencia(cita),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmar asistencia'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirModalReagendar(cita),
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Colores.carmin,
                      ),
                      label: const Text(
                        'No puedo ir • Reagendar cita',
                        style: TextStyle(color: Colores.carmin, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colores.carmin),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (cita.estado == 'Confirmado' &&
              !cita.puedeReagendar &&
              !cita.esAnterior) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF166534),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asistencia confirmada. No se puede reagendar a menos de 2 horas de la cita.',
                      style: TextStyle(color: Color(0xFF166534), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (cita.puedeCancelar ||
              (cita.puedeReagendar && !tieneAlertaConfirmacion)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cita.puedeReagendar && !tieneAlertaConfirmacion) ...[
                  TextButton.icon(
                    onPressed: () => _abrirModalReagendar(cita),
                    icon: const Icon(
                      Icons.edit_calendar,
                      size: 16,
                      color: Colores.azulOscuro,
                    ),
                    label: const Text(
                      'Reagendar',
                      style: TextStyle(color: Colores.azulOscuro, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (cita.puedeCancelar)
                  TextButton.icon(
                    onPressed: () => _dialogoCancelar(cita),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text(
                      'Cancelar cita',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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

class _ModalCalificarCita extends StatefulWidget {
  final Cita cita;
  final ValueChanged<dynamic> onCalificada;

  const _ModalCalificarCita({
    required this.cita,
    required this.onCalificada,
  });

  @override
  State<_ModalCalificarCita> createState() => _ModalCalificarCitaState();
}

class _ModalCalificarCitaState extends State<_ModalCalificarCita> {
  final _comentarioController = TextEditingController();
  int _puntuacion = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_puntuacion < 1 || _enviando) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final valoracion = await calificarCita(
        widget.cita.id,
        puntuacion: _puntuacion,
        comentario: _comentarioController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCalificada(valoracion);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo enviar tu calificación.';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Califica tu cita',
              style: TextStyle(
                color: Colores.azulOscuro,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atendido por ${widget.cita.barbero}',
              style: const TextStyle(color: Colores.gris, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (indice) {
                final estrella = indice + 1;
                return IconButton(
                  onPressed: _enviando
                      ? null
                      : () => setState(() => _puntuacion = estrella),
                  icon: Icon(
                    estrella <= _puntuacion
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colores.dorado,
                    size: 38,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioController,
              maxLength: 500,
              maxLines: 3,
              enabled: !_enviando,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos cómo fue tu experiencia...',
                filled: true,
                fillColor: Colores.fondo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colores.carmin)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _puntuacion == 0 || _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.carmin,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar calificación',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal interactivo para reagendar una cita existente
class _ModalReagendarCita extends StatefulWidget {
  final Cita cita;
  final VoidCallback onReagendada;

  const _ModalReagendarCita({
    required this.cita,
    required this.onReagendada,
  });

  @override
  State<_ModalReagendarCita> createState() => _ModalReagendarCitaState();
}

class _ModalReagendarCitaState extends State<_ModalReagendarCita> {
  late DateTime _fecha;
  List<String>? _horasDisponibles;
  String? _horaSeleccionada;
  bool _cargandoHoras = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fecha = DateTime(ahora.year, ahora.month, ahora.day);
    _cargarHoras();
  }

  bool _esHoraCompatible(String hora) {
    final todosDeHoraCompleta =
        widget.cita.servicios.isNotEmpty &&
        widget.cita.servicios.every(
          (s) => (s.duracion ?? 0) >= 60 && (s.duracion ?? 0) % 60 == 0,
        );
    if (!todosDeHoraCompleta) return true;
    return horaCompatibleConDuracion(hora, 60);
  }

  Future<void> _cargarHoras() async {
    final barberoId = widget.cita.barberoId;
    if (barberoId == null) {
      setState(() {
        _error = 'No se encontró el barbero asignado a esta cita.';
        _horasDisponibles = [];
      });
      return;
    }

    setState(() {
      _cargandoHoras = true;
      _error = null;
      _horaSeleccionada = null;
    });

    try {
      final horas = await listarHorasDisponibles(
        barberoId: barberoId,
        fecha: _fecha,
        duracion: widget.cita.duracionTotalMinutos,
        citaId: widget.cita.id,
      );
      if (!mounted) return;
      setState(() {
        _horasDisponibles = horas.where(_esHoraCompatible).toList();
        _cargandoHoras = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.mensaje
            : 'No se pudieron consultar los horarios disponibles.';
        _horasDisponibles = [];
        _cargandoHoras = false;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final primeraFecha = DateTime(ahora.year, ahora.month, ahora.day);
    final ultimaFecha = primeraFecha.add(const Duration(days: 60));

    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(primeraFecha) ? primeraFecha : _fecha,
      firstDate: primeraFecha,
      lastDate: ultimaFecha,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colores.carmin,
              onPrimary: Colors.white,
              onSurface: Colores.azulOscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (elegida != null &&
        (elegida.year != _fecha.year ||
            elegida.month != _fecha.month ||
            elegida.day != _fecha.day)) {
      setState(() => _fecha = elegida);
      _cargarHoras();
    }
  }

  Future<void> _confirmar() async {
    if (_horaSeleccionada == null) return;
    setState(() => _guardando = true);
    try {
      await reagendarCitaCliente(
        idCita: widget.cita.id,
        fecha: _fecha,
        hora: _horaSeleccionada!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onReagendada();
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.mensaje : 'No se pudo reagendar la cita.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto =
        '${_fecha.day} de ${nombresMeses[_fecha.month - 1]} de ${_fecha.year}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_calendar, color: Colores.carmin),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Reagendar cita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colores.azulOscuro,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              '${widget.cita.barbero} • ${widget.cita.duracionTotalMinutos} min aprox.',
              style: const TextStyle(color: Colores.gris, fontSize: 13),
            ),
            const Divider(height: 24),
            const Text(
              'Nueva fecha',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colores.grisBorde),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colores.carmin,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fechaTexto,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colores.azulOscuro,
                        ),
                      ),
                    ),
                    const Text(
                      'Cambiar',
                      style: TextStyle(
                        color: Colores.carmin,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Horarios disponibles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colores.azulOscuro,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (_cargandoHoras)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: Colores.carmin),
                ),
              )
            else if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              )
            else if (_horasDisponibles == null || _horasDisponibles!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colores.fondo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No hay horarios disponibles en esta fecha para la duración requerida. Prueba seleccionando otro día.',
                  style: TextStyle(color: Colores.gris, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _horasDisponibles!.map((hora) {
                  final seleccionado = _horaSeleccionada == hora;
                  return ChoiceChip(
                    label: Text(horaBonita(hora)),
                    selected: seleccionado,
                    selectedColor: Colores.carmin,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colores.azulOscuro,
                      fontWeight: seleccionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: seleccionado ? Colores.carmin : Colores.grisBorde,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (val) {
                      setState(() {
                        _horaSeleccionada = val ? hora : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _horaSeleccionada != null && !_guardando
                    ? _confirmar
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.carmin,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmar reagendamiento',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
