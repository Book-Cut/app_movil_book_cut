import '../core/api.dart';
import '../core/sesion.dart';
import '../models/perfil.dart';

Future<Perfil> obtenerPerfil() async {
  final respuesta = await obtenerJson('/perfil', conToken: true);
  final datos = respuesta['data'];
  if (datos is! Map<String, dynamic>) {
    throw ApiException('El servidor devolvió un perfil inválido.');
  }
  final perfil = Perfil.fromJson(datos);
  await Sesion.actualizarPerfil(
    nombre: perfil.nombre,
    correo: perfil.correo,
    telefono: perfil.telefono,
    fotoPerfil: perfil.fotoPerfil,
  );
  return perfil;
}

Future<Perfil> actualizarPerfil({
  required String nombre,
  required String correo,
  required String telefono,
  String? contrasenha,
}) async {
  final datos = <String, dynamic>{
    'Nombre': nombre,
    'correo': correo,
    'telefono': telefono,
  };
  if (contrasenha != null && contrasenha.isNotEmpty) {
    datos['contrasenha'] = contrasenha;
  }

  final respuesta = await actualizarJson('/perfil', datos, conToken: true);
  final perfilJson = respuesta['data'];
  if (perfilJson is! Map<String, dynamic>) {
    throw ApiException('El servidor devolvió un perfil inválido.');
  }
  final perfil = Perfil.fromJson(perfilJson);
  await Sesion.actualizarPerfil(
    nombre: perfil.nombre,
    correo: perfil.correo,
    telefono: perfil.telefono,
    fotoPerfil: perfil.fotoPerfil,
  );
  return perfil;
}

Future<Perfil> actualizarFotoPerfil({
  required List<int> bytes,
  required String nombreArchivo,
  required String tipoMime,
}) async {
  final respuesta = await subirArchivo(
    '/perfil/foto',
    campo: 'foto',
    bytes: bytes,
    nombre: nombreArchivo,
    tipoMime: tipoMime,
  );
  final datos = respuesta['data'];
  if (datos is! Map<String, dynamic>) {
    throw ApiException('El servidor devolvió un perfil inválido.');
  }
  final perfil = Perfil.fromJson(datos);
  await Sesion.actualizarPerfil(
    nombre: perfil.nombre,
    correo: perfil.correo,
    telefono: perfil.telefono,
    fotoPerfil: perfil.fotoPerfil,
  );
  return perfil;
}
