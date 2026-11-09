import '../core/api.dart';
import '../models/servicio.dart';

List<Servicio>? _cacheServicios;
DateTime? _expiracionServicios;

Future<List<Servicio>> listarServicios({bool forzar = false}) async {
  final ahora = DateTime.now();
  if (!forzar &&
      _cacheServicios != null &&
      _expiracionServicios != null &&
      ahora.isBefore(_expiracionServicios!)) {
    return _cacheServicios!;
  }

  final datos = await obtenerLista('/servicios');
  final lista = datos
      .map((e) => Servicio.fromJson(e as Map<String, dynamic>))
      .toList();

  _cacheServicios = lista;
  _expiracionServicios = ahora.add(const Duration(minutes: 5));
  return lista;
}

void limpiarCacheServicios() {
  _cacheServicios = null;
  _expiracionServicios = null;
}
