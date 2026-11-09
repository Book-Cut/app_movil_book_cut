import '../core/api.dart';
import '../core/fechas.dart';

/// Horas libres de un barbero en un día. Esta ruta pide sesión iniciada.
Future<List<String>> listarHorasDisponibles({
  required int barberoId,
  required DateTime fecha,
  required int duracion,
  int? citaId,
}) async {
  final params = <String, String>{
    'barbero_id': '$barberoId',
    'fecha': fechaApi(fecha),
    'duracion': '$duracion',
  };
  if (citaId != null) {
    params['cita_id'] = '$citaId';
  }
  final datos = await obtenerLista(
    '/disponibilidad',
    parametros: params,
    conToken: true,
  );
  return datos.map((e) => '$e').toList();
}
