import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../core/api.dart';
import '../core/sesion.dart';
import 'barberos_service.dart';

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

Future<String> solicitarRecuperacionContrasenha({
  required String correo,
}) async {
  final respuesta = await enviarJson('/forgot-password', {
    'correo': correo.trim(),
  });
  final mensaje = respuesta['message'];
  return mensaje is String && mensaje.isNotEmpty
      ? mensaje
      : 'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.';
}

Future<void> iniciarSesionSocial({required String proveedor}) async {
  await _autenticarSocial(proveedor);
}

Future<void> registrarConSocial({
  required String proveedor,
  required String telefono,
}) async {
  final respuesta = await enviarJson('/auth/mobile/social/register', {
    'telefono': telefono,
    'terminos_aceptados': true,
  });
  final registro = respuesta['registration'];
  if (registro is! String || registro.isEmpty) {
    throw ApiException('El servidor no pudo iniciar el registro social.');
  }
  await _autenticarSocial(proveedor, registro: registro);
}

Future<void> _autenticarSocial(String proveedor, {String? registro}) async {
  if (proveedor != 'google') {
    throw ArgumentError.value(proveedor, 'proveedor');
  }

  final uri = Uri.parse('$apiUrl/auth/$proveedor/redirect');
  final url = registro == null
      ? uri.toString()
      : uri.replace(queryParameters: {'registration': registro}).toString();
  late final String callbackUrl;
  try {
    callbackUrl = await FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: 'bookcut',
    );
  } on PlatformException catch (error) {
    if (error.code == 'CANCELED') {
      throw ApiException('Inicio de sesión cancelado.');
    }
    rethrow;
  }
  final callback = Uri.parse(callbackUrl);
  final error = callback.queryParameters['error'];
  if (error != null) {
    throw ApiException(switch (error) {
      'provider_not_configured' =>
        'El acceso con $proveedor todavía no está configurado.',
      'account_not_found' =>
        'No hay una cuenta con ese correo. Regístrate primero.',
      'email_unavailable' => 'El proveedor no compartió un correo electrónico.',
      'email_unverified' => 'Verifica tu correo antes de continuar.',
      'invalid_state' => 'La solicitud expiró. Inténtalo de nuevo.',
      'cancelled' => 'Inicio de sesión cancelado.',
      'provider_error' => 'El proveedor no pudo completar la autenticación.',
      'registration_expired' => 'El registro expiró. Inténtalo nuevamente.',
      'email_domain_not_allowed' =>
        'Usa un correo de Gmail, Hotmail, Outlook o sena.edu.co.',
      _ => 'No se pudo completar el acceso con $proveedor.',
    });
  }

  final code = callback.queryParameters['code'];
  if (code == null || code.isEmpty) {
    throw ApiException('El proveedor no devolvió un código de acceso.');
  }

  final respuesta = await enviarJson('/auth/mobile/exchange', {'code': code});
  await _guardarSesion(respuesta);
}

Future<void> enviarCodigoRegistro({
  required String nombre,
  required String correo,
  required String telefono,
  required String contrasenha,
  required bool terminosAceptados,
}) async {
  await enviarJson('/registro/send-code', {
    'Nombre': nombre,
    'correo': correo,
    'telefono': telefono,
    'contrasenha': contrasenha,
    'terminos_aceptados': terminosAceptados,
  });
}

Future<void> verificarCodigoRegistro({
  required String correo,
  required String codigo,
}) async {
  final respuesta = await enviarJson(
    '/registro/verify',
    {'correo': correo, 'codigo': codigo},
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
    limpiarCacheBarberos();
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

  final idUsuario = usuario['idUsuario'];
  final nombre = usuario['Nombre'];
  final correo = usuario['correo'];
  final telefono = usuario['telefono'];
  final rol = usuario['Roles_IDRol'];
  final fotoPerfil = usuario['foto_perfil'];

  limpiarCacheBarberos();
  await Sesion.guardar(
    token: token,
    usuarioId: int.tryParse('$idUsuario'),
    nombre: nombre is String ? nombre : null,
    correo: correo is String ? correo : null,
    telefono: telefono is String ? telefono : null,
    rolId: int.tryParse('$rol'),
    fotoPerfil: fotoPerfil is String ? fotoPerfil : null,
  );
}
