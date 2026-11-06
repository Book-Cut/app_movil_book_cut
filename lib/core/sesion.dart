import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Sesion {
  static const _almacen = FlutterSecureStorage();
  static const _claves = [
    'bookcut.token',
    'bookcut.nombre',
    'bookcut.telefono',
    'bookcut.correo',
    'bookcut.rol',
    'bookcut.foto',
  ];

  static String? token;
  static String? nombre;
  static String? telefono;
  static String? correo;
  static String? fotoPerfil;
  static int? rolId;

  static bool get activa => token != null && token!.isNotEmpty;

  static String get rol => switch (rolId) {
    1 => 'Administrador',
    2 => 'Barbero',
    3 => 'Cliente',
    _ => 'Usuario',
  };

  static String get primerNombre {
    final n = (nombre ?? '').trim();
    return n.isEmpty ? '' : n.split(RegExp(r'\s+')).first;
  }

  static Future<void> restaurar() async {
    final valores = await Future.wait(
      _claves.map((clave) => _almacen.read(key: clave)),
    );
    token = valores[0];
    nombre = valores[1];
    telefono = valores[2];
    correo = valores[3];
    rolId = int.tryParse(valores[4] ?? '');
    fotoPerfil = valores[5];
  }

  static Future<void> guardar({
    required String token,
    String? nombre,
    String? telefono,
    String? correo,
    int? rolId,
    String? fotoPerfil,
  }) async {
    await _almacen.write(key: _claves[1], value: nombre);
    await _almacen.write(key: _claves[2], value: telefono);
    await _almacen.write(key: _claves[3], value: correo);
    await _almacen.write(key: _claves[4], value: rolId?.toString());
    await _almacen.write(key: _claves[5], value: fotoPerfil);
    await _almacen.write(key: _claves[0], value: token);

    Sesion.token = token;
    Sesion.nombre = nombre;
    Sesion.telefono = telefono;
    Sesion.correo = correo;
    Sesion.rolId = rolId;
    Sesion.fotoPerfil = fotoPerfil;
  }

  static Future<void> actualizarPerfil({
    required String nombre,
    required String correo,
    required String telefono,
    String? fotoPerfil,
  }) async {
    final tokenActual = token;
    if (tokenActual == null || tokenActual.isEmpty) return;
    await guardar(
      token: tokenActual,
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      rolId: rolId,
      fotoPerfil: fotoPerfil,
    );
  }

  static Future<void> limpiar() async {
    token = null;
    nombre = null;
    telefono = null;
    correo = null;
    fotoPerfil = null;
    rolId = null;
    await Future.wait(
      _claves.map((clave) => _almacen.write(key: clave, value: null)),
    );
  }
}
