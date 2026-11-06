import '../core/api.dart';
import '../models/beneficio.dart';

Future<List<Beneficio>> listarBeneficiosVigentes() async {
  final datos = await obtenerLista('/beneficios-vigentes');
  return datos
      .map((e) => Beneficio.fromJson(e as Map<String, dynamic>))
      .toList();
}
