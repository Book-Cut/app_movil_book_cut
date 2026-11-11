import '../core/api.dart';
import '../models/valoracion.dart';

Future<ValoracionCita> calificarCita(
  int idCita, {
  required int puntuacion,
  String? comentario,
}) async {
  final datos = <String, dynamic>{'puntuacion': puntuacion};
  final comentarioLimpio = (comentario ?? '').trim();
  if (comentarioLimpio.isNotEmpty) {
    datos['comentario'] = comentarioLimpio;
  }

  final respuesta = await enviarJson(
    '/citas/$idCita/valoracion',
    datos,
    conToken: true,
  );
  final data = respuesta['data'];
  if (data is! Map) {
    throw ApiException('El servidor devolvió una valoración inválida.');
  }
  return ValoracionCita.fromJson(Map<String, dynamic>.from(data));
}

Future<({List<ValoracionRecibida> valoraciones, ResumenValoraciones resumen})>
listarValoracionesRecibidas() async {
  final respuesta = await obtenerJson('/valoraciones', conToken: true);
  final rawLista = respuesta['data'];
  final rawResumen = respuesta['resumen'];
  if (rawLista is! List) {
    throw ApiException('El servidor devolvió una lista de valoraciones inválida.');
  }
  final valoraciones = rawLista
      .whereType<Map>()
      .map((e) => ValoracionRecibida.fromJson(Map<String, dynamic>.from(e)))
      .toList();
  final resumen = rawResumen is Map
      ? ResumenValoraciones.fromJson(Map<String, dynamic>.from(rawResumen))
      : ResumenValoraciones(total: valoraciones.length);
  return (valoraciones: valoraciones, resumen: resumen);
}
