import '../core/api.dart';
import '../core/sesion.dart';

Future<void> iniciarSesion({
  required String correo,
  required String contrasenha,
}) async {
  final respuesta = await enviarJson('/login', {
    'correo': correo,
    'contrasenha': contrasenha,
  });
  await _guardarSesion(respuesta);
}

Future<void> registrarUsuario({
  required String nombre,
  required String correo,
  required String telefono,
  required String contrasenha,
}) async {
  final respuesta = await enviarJson(
    '/registro',
    {
      'Nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'contrasenha': contrasenha,
    },
    codigosExitosos: const {201},
  );
  await _guardarSesion(respuesta);
}

Future<void> cerrarSesion() async {
  try {
    if (Sesion.activa) {
      await enviarJson('/logout', {}, conToken: true);
    }
  } catch (_) {
    // Clear the local session even when the device is offline.
  } finally {
    await Sesion.limpiar();
  }
}

Future<void> _guardarSesion(Map<String, dynamic> respuesta) async {
  final token = respuesta['token'];
  final usuario = respuesta['user'];
  if (respuesta['result'] != 'ok' ||
      token is! String ||
      usuario is! Map<String, dynamic>) {
    throw ApiException('El servidor devolvió una respuesta incompleta.');
  }

  final nombre = usuario['Nombre'];
  final correo = usuario['correo'];
  final telefono = usuario['telefono'];
  final rol = usuario['Roles_IDRol'];
  await Sesion.guardar(
    token: token,
    nombre: nombre is String ? nombre : null,
    correo: correo is String ? correo : null,
    telefono: telefono is String ? telefono : null,
    rolId: int.tryParse('$rol'),
  );
}
