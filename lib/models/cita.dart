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
  final String barbero;
  final String estado;
  final String estadoPago;
  final String modalidadPago;
  final DateTime inicio;
  final DateTime fin;
  final bool confirmacionPendiente;
  final List<ServicioCita> servicios;

  const Cita({
    required this.id,
    required this.barbero,
    required this.estado,
    required this.estadoPago,
    required this.modalidadPago,
    required this.inicio,
    required this.fin,
    required this.confirmacionPendiente,
    required this.servicios,
  });

  bool get esAnterior => !fin.isAfter(DateTime.now());

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
    return Cita(
      id: _entero(json['idCita']) ?? 0,
      barbero: _texto(barbero?['Nombre']) ?? 'Por asignar',
      estado: _texto(json['estado']) ?? 'Sin estado',
      estadoPago: _texto(json['estado_pago']) ?? 'Pendiente',
      modalidadPago: _texto(json['modalidad_pago']) ?? 'Presencial',
      inicio: servicios.isEmpty ? inicioCita : servicios.first.inicio,
      fin: servicios.isEmpty
          ? inicioCita
          : servicios.last.fin,
      confirmacionPendiente:
          json['estado'] == 'Pendiente' &&
          _texto(json['confirmacion_solicitada_at']) != null,
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
