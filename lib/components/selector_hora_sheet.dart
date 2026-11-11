import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../core/fechas.dart';

enum _PeriodoDia { manhana, tarde, noche }

/// Muestra una hoja inferior en español acotada al horario de atención de la barbería.
Future<String?> mostrarSelectorHora({
  required BuildContext context,
  required String titulo,
  required String horaActual,
  required String horaApertura,
  required String horaCierre,
  String? horaMinimaExclusiva,
  String? horaMaximaExclusiva,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SelectorHoraSheet(
      titulo: titulo,
      horaActual: horaActual,
      horaApertura: horaApertura,
      horaCierre: horaCierre,
      horaMinimaExclusiva: horaMinimaExclusiva,
      horaMaximaExclusiva: horaMaximaExclusiva,
    ),
  );
}

/// Genera franjas cada 30 minutos entre [apertura] y [cierre] inclusive.
List<String> generarHorasFranja(String apertura, String cierre) {
  final minInicio = _minutosDesdeHora(_normalizarHora(apertura));
  final minFin = _minutosDesdeHora(_normalizarHora(cierre));
  if (minInicio == null || minFin == null || minInicio >= minFin) {
    return const [];
  }
  final horas = <String>[];
  for (var m = minInicio; m <= minFin; m += 30) {
    horas.add(_formatearMinutos(m));
  }
  final cierreNorm = _formatearMinutos(minFin);
  if (horas.isEmpty || horas.last != cierreNorm) {
    horas.add(cierreNorm);
  }
  return horas;
}

/// Ajusta la hora de fin al tope [horaCierre] si la nueva hora de inicio la alcanza o supera.
String ajustarHoraFinTrasInicio(
  String nuevaInicio,
  String finActual, {
  String horaCierre = '23:30',
}) {
  final inicioNorm = _normalizarHora(nuevaInicio);
  final finNorm = _normalizarHora(finActual);
  final cierreNorm = _normalizarHora(horaCierre);
  if (inicioNorm.compareTo(finNorm) < 0) {
    return finNorm.compareTo(cierreNorm) > 0 ? cierreNorm : finNorm;
  }

  final minInicio = _minutosDesdeHora(inicioNorm) ?? 9 * 60;
  final minCierre = _minutosDesdeHora(cierreNorm) ?? (23 * 60 + 30);
  final destino = minInicio + 60 > minCierre ? minCierre : minInicio + 60;
  return _formatearMinutos(destino);
}

int? _minutosDesdeHora(String hhMm) {
  final partes = hhMm.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String _formatearMinutos(int minutos) {
  final hh = (minutos ~/ 60).toString().padLeft(2, '0');
  final mm = (minutos % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _normalizarHora(String hora) {
  final partes = hora.trim().split(':');
  if (partes.length < 2) return hora.trim();
  final hh = partes[0].padLeft(2, '0');
  final mm = partes[1].padLeft(2, '0');
  return '$hh:$mm';
}

class SelectorHoraSheet extends StatefulWidget {
  final String titulo;
  final String horaActual;
  final String horaApertura;
  final String horaCierre;
  final String? horaMinimaExclusiva;
  final String? horaMaximaExclusiva;

  const SelectorHoraSheet({
    super.key,
    required this.titulo,
    required this.horaActual,
    required this.horaApertura,
    required this.horaCierre,
    this.horaMinimaExclusiva,
    this.horaMaximaExclusiva,
  });

  @override
  State<SelectorHoraSheet> createState() => _SelectorHoraSheetState();
}

class _SelectorHoraSheetState extends State<SelectorHoraSheet> {
  late final Map<_PeriodoDia, List<String>> _franjasPorPeriodo;
  late final List<_PeriodoDia> _periodosDisponibles;
  late _PeriodoDia _periodo;
  late final String _actualNormalizada;
  late final String _aperturaNormalizada;
  late final String _cierreNormalizada;

  @override
  void initState() {
    super.initState();
    _actualNormalizada = _normalizarHora(widget.horaActual);
    _aperturaNormalizada = _normalizarHora(widget.horaApertura);
    _cierreNormalizada = _normalizarHora(widget.horaCierre);
    final todas = generarHorasFranja(_aperturaNormalizada, _cierreNormalizada);

    final manhana = <String>[];
    final tarde = <String>[];
    final noche = <String>[];
    for (final hora in todas) {
      switch (_periodoDeHora(hora)) {
        case _PeriodoDia.manhana:
          manhana.add(hora);
        case _PeriodoDia.tarde:
          tarde.add(hora);
        case _PeriodoDia.noche:
          noche.add(hora);
      }
    }

    _franjasPorPeriodo = {
      if (manhana.isNotEmpty) _PeriodoDia.manhana: manhana,
      if (tarde.isNotEmpty) _PeriodoDia.tarde: tarde,
      if (noche.isNotEmpty) _PeriodoDia.noche: noche,
    };
    _periodosDisponibles = _franjasPorPeriodo.keys.toList();

    final preferido = _periodoDeHora(_actualNormalizada);
    _periodo = _periodosDisponibles.contains(preferido)
        ? preferido
        : (_periodosDisponibles.isNotEmpty
              ? _periodosDisponibles.first
              : _PeriodoDia.manhana);
  }

  _PeriodoDia _periodoDeHora(String hhMm) {
    final hora = int.tryParse(hhMm.split(':').first) ?? 9;
    if (hora < 12) return _PeriodoDia.manhana;
    if (hora < 18) return _PeriodoDia.tarde;
    return _PeriodoDia.noche;
  }

  String _etiquetaPeriodo(_PeriodoDia p) => switch (p) {
    _PeriodoDia.manhana => 'Mañana',
    _PeriodoDia.tarde => 'Tarde',
    _PeriodoDia.noche => 'Noche',
  };

  bool _estaHabilitada(String hhMm) {
    final min = widget.horaMinimaExclusiva == null
        ? null
        : _normalizarHora(widget.horaMinimaExclusiva!);
    final max = widget.horaMaximaExclusiva == null
        ? null
        : _normalizarHora(widget.horaMaximaExclusiva!);
    if (min != null && hhMm.compareTo(min) <= 0) return false;
    if (max != null && hhMm.compareTo(max) >= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.horaMinimaExclusiva == null
        ? null
        : _normalizarHora(widget.horaMinimaExclusiva!);
    final rangoShop =
        'Barbería: ${horaBonita(_aperturaNormalizada)} – ${horaBonita(_cierreNormalizada)}';
    final subtitulo = min != null
        ? '$rangoShop · Posterior a ${horaBonita(min)}'
        : rangoShop;
    final horas = _franjasPorPeriodo[_periodo] ?? const <String>[];
    final totalFilas = (horas.length + 2) ~/ 3;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: const TextStyle(
                          color: Colores.azulOscuro,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: Colores.gris,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colores.gris),
                ),
              ],
            ),
            if (_periodosDisponibles.length > 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: _periodosDisponibles
                      .map((p) => _tabPeriodo(p, _etiquetaPeriodo(p)))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...List.generate(totalFilas, (fila) {
              return Padding(
                padding: EdgeInsets.only(bottom: fila == totalFilas - 1 ? 0 : 10),
                child: Row(
                  children: List.generate(3, (col) {
                    final idx = fila * 3 + col;
                    if (idx >= horas.length) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: col == 2 ? 0 : 8),
                          child: const SizedBox(height: 44),
                        ),
                      );
                    }
                    final hhMm = horas[idx];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: col == 2 ? 0 : 8),
                        child: _celdaHora(
                          hhMm: hhMm,
                          seleccionada: hhMm == _actualNormalizada,
                          habilitada: _estaHabilitada(hhMm),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tabPeriodo(_PeriodoDia periodo, String etiqueta) {
    final activo = _periodo == periodo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _periodo = periodo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: activo ? Colores.azulOscuro : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            etiqueta,
            style: TextStyle(
              color: activo ? Colors.white : Colores.gris,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _celdaHora({
    required String hhMm,
    required bool seleccionada,
    required bool habilitada,
  }) {
    final colorFondo = !habilitada
        ? const Color(0xFFF8FAFC)
        : seleccionada
        ? Colores.carmin
        : Colors.white;
    final colorBorde = !habilitada
        ? const Color(0xFFE2E8F0)
        : seleccionada
        ? Colores.carmin
        : Colores.grisBorde;
    final colorTexto = !habilitada
        ? const Color(0xFF94A3B8)
        : seleccionada
        ? Colors.white
        : Colores.azulOscuro;

    return Material(
      color: colorFondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: habilitada ? () => Navigator.pop(context, hhMm) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorBorde),
          ),
          child: Text(
            horaBonita(hhMm),
            style: TextStyle(
              color: colorTexto,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
