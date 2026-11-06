import '../core/api.dart';
import '../core/fechas.dart';

/// Horas libres de un barbero en un día. Esta ruta pide sesión iniciada.
Future<List<String>> listarHorasDisponibles({
  required int barberoId,
  required DateTime fecha,
  required int duracion,
}) async {
  final datos = await obtenerLista(
    '/disponibilidad',
    parametros: {
      'barbero_id': '$barberoId',
      'fecha': fechaApi(fecha),
      'duracion': '$duracion',
    },
    conToken: true,
  );
  return datos.map((e) => '$e').toList();
}
