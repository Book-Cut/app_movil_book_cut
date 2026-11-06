import 'package:flutter/material.dart';

import '../core/fechas.dart';

class CalendarioMes extends StatefulWidget {
  final DateTime seleccionada;
  final ValueChanged<DateTime> onSeleccionar;

  const CalendarioMes({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  State<CalendarioMes> createState() => _CalendarioMesState();
}

class _CalendarioMesState extends State<CalendarioMes> {
  static const _dias = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
  late DateTime _mes; // primer día del mes que se está viendo

  @override
  void initState() {
    super.initState();
    _mes = DateTime(widget.seleccionada.year, widget.seleccionada.month);
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final elegida = DateTime(
      widget.seleccionada.year,
      widget.seleccionada.month,
      widget.seleccionada.day,
    );
    final diasDelMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final huecos =
        DateTime(_mes.year, _mes.month, 1).weekday % 7; // domingo = 0
    final puedeRetroceder = _mes.isAfter(DateTime(ahora.year, ahora.month));

    final celdas = <Widget>[
      for (var i = 0; i < huecos; i++) const SizedBox.shrink(),
      for (var d = 1; d <= diasDelMes; d++)
        _celdaDia(DateTime(_mes.year, _mes.month, d), hoy, elegida),
    ];

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: puedeRetroceder ? () => _cambiarMes(-1) : null,
              color: Colors.white,
              disabledColor: Colors.white24,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${nombresMeses[_mes.month - 1]} ${_mes.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _cambiarMes(1),
              color: Colors.white,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: _dias
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: celdas,
        ),
      ],
    );
  }

  Widget _celdaDia(DateTime fecha, DateTime hoy, DateTime elegida) {
    final pasado = fecha.isBefore(hoy);
    final esElegida = fecha == elegida;
    return GestureDetector(
      onTap: pasado ? null : () => widget.onSeleccionar(fecha),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: esElegida ? const Color(0xFFE11D48) : Colors.transparent,
          ),
          child: Text(
            '${fecha.day}',
            style: TextStyle(
              color: pasado ? Colors.white38 : Colors.white,
              fontWeight: esElegida ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
