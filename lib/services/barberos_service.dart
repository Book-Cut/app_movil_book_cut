import '../core/api.dart';
import '../models/barbero.dart';

Future<List<Barbero>> listarBarberos() async {
  final datos = await obtenerLista('/barberos');
  return datos.map((e) => Barbero.fromJson(e as Map<String, dynamic>)).toList();
}
