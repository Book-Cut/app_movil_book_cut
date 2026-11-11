import '../core/sesion.dart';
import 'servicio.dart';

class Barbero {
  final int id;
  final String nombre;
  final String especialidad;
  final List<int> servicioIds;
  final List<String> especialidadesNombres;
  final String? fotoPerfil;

  const Barbero({
    required this.id,
    required this.nombre,
    required this.especialidad,
    this.servicioIds = const [],
    this.especialidadesNombres = const [],
    this.fotoPerfil,
  });

  bool ofreceServicio(Servicio servicio) {
    if (servicioIds.isNotEmpty) {
      return servicioIds.contains(servicio.id);
    }
    if (especialidadesNombres.isEmpty) return true;
    final nombreNormalizado = _normalizar(servicio.nombre);
    return especialidadesNombres.any((e) => _normalizar(e) == nombreNormalizado);
  }

  factory Barbero.fromJson(Map<String, dynamic> json) {
    final rawEspecialidad = json['especialidad'];
    final parsed = _parseEspecialidad(rawEspecialidad);
    return Barbero(
      id: int.tryParse('${json['idUsuario']}') ?? 0,
      nombre: '${json['Nombre'] ?? 'Barbero'}',
      especialidad: parsed.texto,
      servicioIds: parsed.ids,
      especialidadesNombres: parsed.nombres,
      fotoPerfil: Sesion.formatearUrlFoto(json['foto_perfil']),
    );
  }
}

String _normalizar(String texto) => texto.trim().toLowerCase();

({String texto, List<int> ids, List<String> nombres}) _parseEspecialidad(
  dynamic raw,
) {
  if (raw == null) return (texto: '', ids: const [], nombres: const []);
  if (raw is String) {
    final partes = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return (texto: raw.trim(), ids: const [], nombres: partes);
  }
  if (raw is List) {
    final ids = <int>[];
    final nombres = <String>[];
    for (final e in raw) {
      if (e is Map) {
        final id = int.tryParse('${e['idServicio']}');
        if (id != null) ids.add(id);
        final nombre = e['Nombre']?.toString().trim();
        if (nombre != null && nombre.isNotEmpty) nombres.add(nombre);
      } else if (e != null) {
        final nombre = e.toString().trim();
        if (nombre.isNotEmpty) nombres.add(nombre);
      }
    }
    return (texto: nombres.join(', '), ids: ids, nombres: nombres);
  }
  final texto = '$raw'.trim();
  return (texto: texto, ids: const [], nombres: texto.isEmpty ? const [] : [texto]);
}
