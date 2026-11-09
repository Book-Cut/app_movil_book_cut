class ServicioCita {
  final String nombre;
  final DateTime inicio;
  final int? duracion;

  const ServicioCita({
    required this.nombre,
    required this.inicio,
    required this.duracion,
  });

  DateTime get fin => inicio.add(Duration(minutes: duracion ?? 0));

  factory ServicioCita.fromJson(
    Map<String, dynamic> json, {
    required DateTime inicioSiguiente,
  }) {
    final pivot = _mapFrom(json['pivot']);
    final fechaHora = pivot?['fecha_hora_servicio'];
    final inicio =
        _parseDateTime(fechaHora) ??
        _parseDateTime(json['fecha_hora_servicio']) ??
        inicioSiguiente;

    return ServicioCita(
      nombre:
          _texto(pivot?['nombre_servicio']) ??
          _texto(json['nombre_servicio']) ??
          _texto(json['Nombre']) ??
          'Servicio',
      inicio: inicio,
      duracion:
          _entero(pivot?['duracion_servicio']) ??
          _entero(json['duracion_servicio']) ??
          _entero(json['Duracion']),
    );
  }
}

class Cita {
  final int id;
  final int? barberoId;
  final String barbero;
  final String estado;
  final String estadoPago;
  final String modalidadPago;
  final DateTime inicio;
  final DateTime fin;
  final bool confirmacionPendiente;
  final DateTime? confirmacionSolicitadaAt;
  final List<ServicioCita> servicios;

  const Cita({
    required this.id,
    this.barberoId,
    required this.barbero,
    required this.estado,
    required this.estadoPago,
    required this.modalidadPago,
    required this.inicio,
    required this.fin,
    required this.confirmacionPendiente,
    this.confirmacionSolicitadaAt,
    required this.servicios,
  });

  bool get esAnterior => !fin.isAfter(DateTime.now());

  int get duracionTotalMinutos {
    final suma = servicios.fold<int>(0, (total, s) => total + (s.duracion ?? 0));
    if (suma > 0) return suma;
    final diff = fin.difference(inicio).inMinutes;
    return diff > 0 ? diff : 30;
  }

  /// Indica si está dentro de la ventana de 30 minutos desde que se solicitó confirmación
  bool get enVentanaConfirmacion {
    if (estado != 'Pendiente' || confirmacionSolicitadaAt == null) return false;
    final limite = confirmacionSolicitadaAt!.add(const Duration(minutes: 30));
    final ahora = DateTime.now();
    return ahora.isBefore(limite) && ahora.isBefore(inicio);
  }

  /// Minutos restantes en la ventana de confirmación (máx 30)
  int get minutosRestantesConfirmacion {
    if (confirmacionSolicitadaAt == null) return 0;
    final limite = confirmacionSolicitadaAt!.add(const Duration(minutes: 30));
    final diff = limite.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Regla de negocio de reagendamiento:
  /// - Canceladas o finalizadas: no se pueden reagendar.
  /// - Durante la ventana de confirmación (2h antes de la cita, plazo de 30 min): el cliente puede decidir no asistir y reagendar.
  /// - Antes de las 2 horas de la cita (más de 120 minutos): puede reagendar libremente.
  /// - Si ya confirmó asistencia (estado == 'Confirmado' y faltan menos de 2 horas): ya no puede reagendar.
  bool get puedeReagendar {
    if (estado == 'Cancelado' || estado == 'Finalizado') return false;
    if (esAnterior) return false;
    if (enVentanaConfirmacion) return true;
    final minutosParaInicio = inicio.difference(DateTime.now()).inMinutes;
    return minutosParaInicio > 120;
  }

  /// Regla de negocio de cancelación:
  /// - Canceladas, finalizadas o pasadas: no se pueden cancelar.
  /// - El cliente puede cancelar en cualquier momento antes de que finalice la cita.
  bool get puedeCancelar {
    if (estado == 'Cancelado' || estado == 'Finalizado') return false;
    return !esAnterior;
  }

  Cita copyWith({
    int? id,
    int? barberoId,
    String? barbero,
    String? estado,
    String? estadoPago,
    String? modalidadPago,
    DateTime? inicio,
    DateTime? fin,
    bool? confirmacionPendiente,
    DateTime? confirmacionSolicitadaAt,
    List<ServicioCita>? servicios,
  }) {
    return Cita(
      id: id ?? this.id,
      barberoId: barberoId ?? this.barberoId,
      barbero: barbero ?? this.barbero,
      estado: estado ?? this.estado,
      estadoPago: estadoPago ?? this.estadoPago,
      modalidadPago: modalidadPago ?? this.modalidadPago,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      confirmacionPendiente:
          confirmacionPendiente ?? this.confirmacionPendiente,
      confirmacionSolicitadaAt:
          confirmacionSolicitadaAt ?? this.confirmacionSolicitadaAt,
      servicios: servicios ?? this.servicios,
    );
  }

  factory Cita.fromJson(Map<String, dynamic> json) {
    final inicioCita = _parseDateTime(json['Fecha_hora']);
    if (inicioCita == null) {
      throw const FormatException('La cita no tiene una fecha válida.');
    }
    final rawServicios = json['servicios'];
    var inicioSiguiente = inicioCita;
    final servicios = <ServicioCita>[];
    if (rawServicios is List) {
      for (final servicio in rawServicios) {
        if (servicio is! Map) {
          throw const FormatException('La cita contiene un servicio inválido.');
        }
        final servicioNormalizado = ServicioCita.fromJson(
          Map<String, dynamic>.from(servicio),
          inicioSiguiente: inicioSiguiente,
        );
        servicios.add(servicioNormalizado);
        inicioSiguiente = servicioNormalizado.fin;
      }
    }
    servicios.sort((a, b) => a.inicio.compareTo(b.inicio));

    final barbero = _mapFrom(json['barbero']);
    final solicitadaAt = _parseDateTime(json['confirmacion_solicitada_at']);

    return Cita(
      id: _entero(json['idCita']) ?? 0,
      barberoId: _entero(json['Usuario_idUsuarioBar']) ?? _entero(barbero?['idUsuario']),
      barbero: _texto(barbero?['Nombre']) ?? 'Por asignar',
      estado: _texto(json['estado']) ?? 'Sin estado',
      estadoPago: _texto(json['estado_pago']) ?? 'Pendiente',
      modalidadPago: _texto(json['modalidad_pago']) ?? 'Presencial',
      inicio: servicios.isEmpty ? inicioCita : servicios.first.inicio,
      fin: servicios.isEmpty
          ? inicioCita
          : servicios.last.fin,
      confirmacionPendiente:
          json['estado'] == 'Pendiente' && solicitadaAt != null,
      confirmacionSolicitadaAt: solicitadaAt,
      servicios: servicios,
    );
  }
}

Map<String, dynamic>? _mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _texto(dynamic value) {
  if (value == null) return null;
  final texto = '$value'.trim();
  return texto.isEmpty ? null : texto;
}

int? _entero(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

DateTime? _parseDateTime(dynamic value) {
  final texto = _texto(value);
  if (texto == null) return null;
  return DateTime.tryParse(texto.replaceFirst(' ', 'T'));
}
