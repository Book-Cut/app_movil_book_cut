import '../core/api.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';

List<Barbero>? _cacheBarberos;
DateTime? _expiracionBarberos;

Future<List<Barbero>> listarBarberos({bool forzar = false}) async {
  final ahora = DateTime.now();
  if (!forzar &&
      _cacheBarberos != null &&
      _expiracionBarberos != null &&
      ahora.isBefore(_expiracionBarberos!)) {
    return _cacheBarberos!;
  }

  // Si hay sesión iniciada de cliente, /usuarios devuelve barberos con foto_perfil completa desde la BD
  if (Sesion.activa && Sesion.rolId == 3) {
    try {
      final respuesta = await obtenerJson('/usuarios', conToken: true);
      final data = respuesta['data'];
      if (data is Map && data['barberos'] is List) {
        final barberosRaw = data['barberos'] as List;
        final lista = barberosRaw
            .whereType<Map>()
            .map((e) => Barbero.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (lista.isNotEmpty) {
          _cacheBarberos = lista;
          _expiracionBarberos = ahora.add(const Duration(minutes: 5));
          return lista;
        }
      }
    } catch (_) {
      // Si falla o no tiene permisos, continúa con el endpoint público
    }
  }

  final datos = await obtenerLista('/barberos');
  final lista =
      datos.map((e) => Barbero.fromJson(e as Map<String, dynamic>)).toList();

  _cacheBarberos = lista;
  _expiracionBarberos = ahora.add(const Duration(minutes: 5));
  return lista;
}

void limpiarCacheBarberos() {
  _cacheBarberos = null;
  _expiracionBarberos = null;
}
