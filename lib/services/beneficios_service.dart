import '../core/api.dart';
import '../models/beneficio.dart';

List<Beneficio>? _cacheBeneficios;
DateTime? _expiracionBeneficios;

Future<List<Beneficio>> listarBeneficiosVigentes({bool forzar = false}) async {
  final ahora = DateTime.now();
  if (!forzar &&
      _cacheBeneficios != null &&
      _expiracionBeneficios != null &&
      ahora.isBefore(_expiracionBeneficios!)) {
    return _cacheBeneficios!;
  }

  final datos = await obtenerLista('/beneficios-vigentes');
  final lista = datos
      .map((e) => Beneficio.fromJson(e as Map<String, dynamic>))
      .toList();

  _cacheBeneficios = lista;
  _expiracionBeneficios = ahora.add(const Duration(minutes: 5));
  return lista;
}

void limpiarCacheBeneficios() {
  _cacheBeneficios = null;
  _expiracionBeneficios = null;
}
