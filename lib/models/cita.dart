import 'valoracion.dart';

class ServicioCita {
  final String nombre;
  final DateTime inicio;
  final int? duracion;
  final double? precio;

  const ServicioCita({
    required this.nombre,
    required this.inicio,
    required this.duracion,
    this.precio,
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
      precio:
          _decimal(pivot?['precio_servicio']) ??
          _decimal(json['precio_servicio']) ??
          _decimal(json['Precio']),
    );
  }
}

class FacturaCita {
  final String numero;
  final String fecha;
  final double subtotal;
  final double total;
  final String metodoPago;
  final String estado;
  final String? beneficioTitulo;
  final String? beneficioTipo;

  const FacturaCita({
    required this.numero,
    required this.fecha,
    required this.subtotal,
    required this.total,
    required this.metodoPago,
    required this.estado,
    this.beneficioTitulo,
    this.beneficioTipo,
  });

  double get descuento => subtotal > total ? subtotal - total : 0;

  factory FacturaCita.fromJson(Map<String, dynamic> json) {
    final beneficio = _mapFrom(json['beneficio']);
    return FacturaCita(
      numero: _texto(json['numero_factura']) ?? '',
      fecha: (_texto(json['fecha_emision']) ?? '').split(RegExp(r'[T ]')).first,
      subtotal: _decimal(json['subtotal']) ?? 0,
      total: _decimal(json['total_pagar']) ?? 0,
      metodoPago: _texto(json['metodo_pago']) ?? '',
      estado: _texto(json['estado_factura']) ?? '',
      beneficioTitulo: _texto(beneficio?['titulo']),
      beneficioTipo: _texto(beneficio?['Tipo_beneficio']),
    );
  }
}

class Cita {
  final int id;
  final int? barberoId;
  final String barbero;
  final String? clienteNombre;
  final String? clienteTelefono;
  final String estado;
  final String estadoPago;
  final String modalidadPago;
  final String? metodoPago;
  final DateTime inicio;
  final DateTime fin;
  final bool confirmacionPendiente;
  final DateTime? confirmacionSolicitadaAt;
  final bool afectadaPendiente;
  final String? motivoAfectada;
  final FacturaCita? factura;
  final ValoracionCita? valoracion;
  final List<ServicioCita> servicios;

  const Cita({
    required this.id,
    this.barberoId,
    required this.barbero,
    this.clienteNombre,
    this.clienteTelefono,
    required this.estado,
    required this.estadoPago,
    required this.modalidadPago,
    this.metodoPago,
    required this.inicio,
    required this.fin,
    required this.confirmacionPendiente,
    this.confirmacionSolicitadaAt,
    this.afectadaPendiente = false,
    this.motivoAfectada,
    this.factura,
    this.valoracion,
    required this.servicios,
  });

  bool get esAnterior => !fin.isAfter(DateTime.now());

  double get total {
    final sumaServicios = servicios.fold<double>(
      0,
      (suma, s) => suma + (s.precio ?? 0),
    );
    if (sumaServicios > 0) return sumaServicios;
    return factura?.total ?? 0;
  }

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
  /// - Cita afectada por indisponibilidad del barbero: puede reagendarse incluso dentro de las 2 horas.
  /// - Durante la ventana de confirmación (2h antes de la cita, plazo de 30 min): el cliente puede decidir no asistir y reagendar.
  /// - Antes de las 2 horas de la cita (más de 120 minutos): puede reagendar libremente.
  /// - Si ya confirmó asistencia (estado == 'Confirmado' y faltan menos de 2 horas): ya no puede reagendar.
  bool get puedeReagendar {
    if (estado == 'Cancelado' || estado == 'Finalizado') return false;
    if (esAnterior) return false;
    if (afectadaPendiente) return true;
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
    String? clienteNombre,
    String? clienteTelefono,
    String? estado,
    String? estadoPago,
    String? modalidadPago,
    String? metodoPago,
    DateTime? inicio,
    DateTime? fin,
    bool? confirmacionPendiente,
    DateTime? confirmacionSolicitadaAt,
    bool? afectadaPendiente,
    String? motivoAfectada,
    FacturaCita? factura,
    ValoracionCita? valoracion,
    List<ServicioCita>? servicios,
  }) {
    return Cita(
      id: id ?? this.id,
      barberoId: barberoId ?? this.barberoId,
      barbero: barbero ?? this.barbero,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      estado: estado ?? this.estado,
      estadoPago: estadoPago ?? this.estadoPago,
      modalidadPago: modalidadPago ?? this.modalidadPago,
      metodoPago: metodoPago ?? this.metodoPago,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      confirmacionPendiente:
          confirmacionPendiente ?? this.confirmacionPendiente,
      confirmacionSolicitadaAt:
          confirmacionSolicitadaAt ?? this.confirmacionSolicitadaAt,
      afectadaPendiente: afectadaPendiente ?? this.afectadaPendiente,
      motivoAfectada: motivoAfectada ?? this.motivoAfectada,
      factura: factura ?? this.factura,
      valoracion: valoracion ?? this.valoracion,
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
    final cliente = _mapFrom(json['cliente']);
    final solicitadaAt = _parseDateTime(json['confirmacion_solicitada_at']);
    final afectada = _mapFrom(json['afectada_pendiente']);
    final indisponibilidad = _mapFrom(afectada?['indisponibilidad']);

    Map<String, dynamic>? facturaJson = _mapFrom(json['factura']);
    if (facturaJson == null && json['facturas'] is List) {
      final listaFacturas = json['facturas'] as List;
      if (listaFacturas.isNotEmpty) {
        facturaJson = _mapFrom(listaFacturas.first);
      }
    }
    final valoraJson = _mapFrom(json['valora']);

    return Cita(
      id: _entero(json['idCita']) ?? 0,
      barberoId:
          _entero(json['Usuario_idUsuarioBar']) ??
          _entero(barbero?['idUsuario']),
      barbero: _texto(barbero?['Nombre']) ?? 'Por asignar',
      clienteNombre:
          _texto(json['nombre_cliente']) ?? _texto(cliente?['Nombre']),
      clienteTelefono:
          _texto(json['telefono_cliente']) ?? _texto(cliente?['telefono']),
      estado: _texto(json['estado']) ?? 'Sin estado',
      estadoPago: _texto(json['estado_pago']) ?? 'Pendiente',
      modalidadPago: _texto(json['modalidad_pago']) ?? 'Presencial',
      metodoPago: _texto(json['metodo_pago']),
      inicio: servicios.isEmpty ? inicioCita : servicios.first.inicio,
      fin: servicios.isEmpty ? inicioCita : servicios.last.fin,
      confirmacionPendiente:
          json['estado'] == 'Pendiente' && solicitadaAt != null,
      confirmacionSolicitadaAt: solicitadaAt,
      afectadaPendiente: afectada != null,
      motivoAfectada: _texto(indisponibilidad?['motivo']),
      factura: facturaJson != null ? FacturaCita.fromJson(facturaJson) : null,
      valoracion: valoraJson != null ? ValoracionCita.fromJson(valoraJson) : null,
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

double? _decimal(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

DateTime? _parseDateTime(dynamic value) {
  final texto = _texto(value);
  if (texto == null) return null;
  return DateTime.tryParse(texto.replaceFirst(' ', 'T'));
}
