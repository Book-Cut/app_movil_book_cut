class ValoracionCita {
  final int idValora;
  final int puntuacion;
  final String? comentario;
  final String fecha;

  const ValoracionCita({
    required this.idValora,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
  });

  factory ValoracionCita.fromJson(Map<String, dynamic> json) {
    final rawFecha =
        json['Fecha_evaluacion_cita'] ?? json['fecha_valoracion'] ?? '';
    return ValoracionCita(
      idValora: int.tryParse('${json['Idvalora'] ?? json['idValora']}') ?? 0,
      puntuacion:
          int.tryParse('${json['EvaluacionBar'] ?? json['puntuacion']}') ?? 0,
      comentario: _limpiarTexto(json['Comentario'] ?? json['comentario']),
      fecha: '$rawFecha'.split(RegExp(r'[T ]')).first,
    );
  }
}

class ValoracionRecibida {
  final int idValora;
  final int? idCita;
  final int puntuacion;
  final String? comentario;
  final String fecha;
  final String cliente;
  final String barbero;
  final String servicios;

  const ValoracionRecibida({
    required this.idValora,
    this.idCita,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
    required this.cliente,
    required this.barbero,
    required this.servicios,
  });

  factory ValoracionRecibida.fromJson(Map<String, dynamic> json) {
    final rawFecha =
        json['Fecha'] ?? json['fecha_valoracion'] ?? json['Fecha_hora'] ?? '';
    final fecha = '$rawFecha'.trim();
    final comentarioRaw = _limpiarTexto(json['comentario']);
    return ValoracionRecibida(
      idValora: int.tryParse('${json['idValora']}') ?? 0,
      idCita: int.tryParse('${json['idCita']}'),
      puntuacion: int.tryParse('${json['puntuacion']}') ?? 0,
      comentario: comentarioRaw == '—' ? null : comentarioRaw,
      fecha: fecha.isEmpty ? '—' : fecha,
      cliente: _limpiarTexto(json['Cliente']) ?? 'Cliente',
      barbero: _limpiarTexto(json['Barbero']) ?? '',
      servicios: _limpiarTexto(json['Servicios']) ?? 'Servicio no especificado',
    );
  }
}

class ResumenValoraciones {
  final int total;
  final double? promedio;

  const ResumenValoraciones({required this.total, this.promedio});

  factory ResumenValoraciones.fromJson(Map<String, dynamic> json) {
    final rawPromedio = json['promedio'];
    return ResumenValoraciones(
      total: int.tryParse('${json['total']}') ?? 0,
      promedio: rawPromedio == null ? null : double.tryParse('$rawPromedio'),
    );
  }
}

String? _limpiarTexto(dynamic valor) {
  if (valor == null) return null;
  final texto = '$valor'.trim();
  return texto.isEmpty || texto == 'null' ? null : texto;
}
