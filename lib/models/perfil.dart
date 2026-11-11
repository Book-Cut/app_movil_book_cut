import '../core/sesion.dart';

const List<String> diasSemanaOrden = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Horarios base de la barbería definidos por `HorarioSeeder` en el backend.
const Map<String, HorarioPerfil> horariosBarberiaPorDefecto = {
  'Lunes': HorarioPerfil(
    diasemana: 'Lunes',
    horainicio: '09:00',
    horafin: '19:00',
  ),
  'Martes': HorarioPerfil(
    diasemana: 'Martes',
    horainicio: '09:00',
    horafin: '19:00',
  ),
  'Miércoles': HorarioPerfil(
    diasemana: 'Miércoles',
    horainicio: '09:00',
    horafin: '19:00',
  ),
  'Jueves': HorarioPerfil(
    diasemana: 'Jueves',
    horainicio: '09:00',
    horafin: '19:00',
  ),
  'Viernes': HorarioPerfil(
    diasemana: 'Viernes',
    horainicio: '09:00',
    horafin: '19:00',
  ),
  'Sábado': HorarioPerfil(
    diasemana: 'Sábado',
    horainicio: '10:00',
    horafin: '20:00',
  ),
};

class HorarioPerfil {
  final String diasemana;
  final String horainicio;
  final String horafin;

  const HorarioPerfil({
    required this.diasemana,
    required this.horainicio,
    required this.horafin,
  });

  factory HorarioPerfil.fromJson(Map<String, dynamic> json) => HorarioPerfil(
    diasemana: '${json['diasemana'] ?? 'Lunes'}',
    horainicio: _cortarHora('${json['horainicio'] ?? '09:00'}'),
    horafin: _cortarHora('${json['horafin'] ?? '17:00'}'),
  );

  Map<String, dynamic> toJson() => {
    'diasemana': diasemana,
    'horainicio': horainicio,
    'horafin': horafin,
  };

  HorarioPerfil copyWith({
    String? diasemana,
    String? horainicio,
    String? horafin,
  }) => HorarioPerfil(
    diasemana: diasemana ?? this.diasemana,
    horainicio: horainicio ?? this.horainicio,
    horafin: horafin ?? this.horafin,
  );
}

String _cortarHora(String raw) {
  final partes = raw.trim().split(':');
  if (partes.length < 2) return raw.trim();
  return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
}

String _normalizarDiaSemana(String raw) {
  final limpio = raw.trim().toLowerCase();
  for (final dia in diasSemanaOrden) {
    if (dia.toLowerCase() == limpio) return dia;
  }
  switch (limpio) {
    case 'miercoles':
      return 'Miércoles';
    case 'sabado':
      return 'Sábado';
    default:
      return raw.trim();
  }
}

/// Construye las franjas de atención de la barbería por día a partir de `/horario`.
Map<String, HorarioPerfil> construirHorariosBarberia(List<dynamic> filas) {
  final resultado = <String, HorarioPerfil>{};
  for (final item in filas) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final dia = _normalizarDiaSemana('${map['diasemana'] ?? ''}');
    if (!diasSemanaOrden.contains(dia)) continue;
    final inicio = _cortarHora('${map['horainicio'] ?? ''}');
    final fin = _cortarHora('${map['horafin'] ?? ''}');
    if (inicio.length < 5 || fin.length < 5 || inicio.compareTo(fin) >= 0) {
      continue;
    }
    final previo = resultado[dia];
    if (previo == null) {
      resultado[dia] = HorarioPerfil(
        diasemana: dia,
        horainicio: inicio,
        horafin: fin,
      );
    } else {
      resultado[dia] = HorarioPerfil(
        diasemana: dia,
        horainicio:
            inicio.compareTo(previo.horainicio) < 0 ? inicio : previo.horainicio,
        horafin: fin.compareTo(previo.horafin) > 0 ? fin : previo.horafin,
      );
    }
  }
  return resultado;
}

/// Ajusta un horario de barbero para que quede dentro de la franja de la barbería.
HorarioPerfil ajustarHorarioAFranja(
  HorarioPerfil horario,
  HorarioPerfil franjaBarberia,
) {
  final inicio = horario.horainicio.compareTo(franjaBarberia.horainicio) < 0
      ? franjaBarberia.horainicio
      : horario.horainicio;
  final fin = horario.horafin.compareTo(franjaBarberia.horafin) > 0
      ? franjaBarberia.horafin
      : horario.horafin;
  if (inicio.compareTo(fin) >= 0) {
    return franjaBarberia.copyWith(diasemana: horario.diasemana);
  }
  return horario.copyWith(horainicio: inicio, horafin: fin);
}

class ResultadoReconciliacionHorarios {
  final List<HorarioPerfil> horarios;
  final bool ajustado;

  const ResultadoReconciliacionHorarios({
    required this.horarios,
    required this.ajustado,
  });
}

/// Ordena y acomoda las franjas del barbero al horario vigente de la barbería.
ResultadoReconciliacionHorarios reconciliarHorariosConBarberia(
  List<HorarioPerfil> horariosBarbero,
  Map<String, HorarioPerfil> horariosBarberia,
) {
  final ordenados = List<HorarioPerfil>.of(horariosBarbero)
    ..sort(
      (a, b) => diasSemanaOrden
          .indexOf(_normalizarDiaSemana(a.diasemana))
          .compareTo(
            diasSemanaOrden.indexOf(_normalizarDiaSemana(b.diasemana)),
          ),
    );
  if (horariosBarberia.isEmpty) {
    return ResultadoReconciliacionHorarios(
      horarios: ordenados,
      ajustado: false,
    );
  }

  var ajustado = false;
  final resultado = <HorarioPerfil>[];
  for (final h in ordenados) {
    final dia = _normalizarDiaSemana(h.diasemana);
    final limite = horariosBarberia[dia];
    if (limite == null) {
      ajustado = true;
      continue;
    }
    final normalizado = h.copyWith(diasemana: dia);
    final acomodado = ajustarHorarioAFranja(normalizado, limite);
    if (acomodado.horainicio != normalizado.horainicio ||
        acomodado.horafin != normalizado.horafin) {
      ajustado = true;
    }
    resultado.add(acomodado);
  }
  return ResultadoReconciliacionHorarios(
    horarios: resultado,
    ajustado: ajustado,
  );
}

class Perfil {
  final int id;
  final String nombre;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final List<int> servicioIds;
  final List<HorarioPerfil> horarios;

  const Perfil({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.fotoPerfil,
    this.servicioIds = const [],
    this.horarios = const [],
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    final rawServicios = json['servicio_ids'];
    final servicioIds = rawServicios is List
        ? rawServicios
              .map((e) => int.tryParse('$e'))
              .whereType<int>()
              .toList()
        : const <int>[];

    final rawHorarios = json['horarios'];
    final horarios = rawHorarios is List
        ? rawHorarios
              .whereType<Map>()
              .map((e) => HorarioPerfil.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const <HorarioPerfil>[];

    return Perfil(
      id: int.tryParse('${json['idUsuario']}') ?? 0,
      nombre: '${json['Nombre'] ?? ''}',
      correo: '${json['correo'] ?? ''}',
      telefono: '${json['telefono'] ?? ''}',
      fotoPerfil: Sesion.formatearUrlFoto(json['foto_perfil']),
      servicioIds: servicioIds,
      horarios: horarios,
    );
  }
}
