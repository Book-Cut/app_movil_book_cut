import '../core/api.dart';
import '../models/servicio.dart';

Future<List<Servicio>> listarServicios() async {
  final datos = await obtenerLista('/servicios');
  return datos
      .map((e) => Servicio.fromJson(e as Map<String, dynamic>))
      .toList();
}
