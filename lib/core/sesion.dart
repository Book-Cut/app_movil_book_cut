import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

class Sesion {
  static const _almacen = FlutterSecureStorage();
  static const _claves = [
    'bookcut.token',
    'bookcut.nombre',
    'bookcut.telefono',
    'bookcut.correo',
    'bookcut.rol',
    'bookcut.foto',
    'bookcut.usuario_id',
  ];

  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  static String? token;
  static int? usuarioId;
  static String? nombre;
  static String? telefono;
  static String? correo;
  static String? fotoPerfil;
  static int? rolId;
  static void Function()? alExpirar;
  static bool _invalidando = false;

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

  static String? formatearUrlFoto(dynamic valor) {
    if (valor == null) return null;
    final texto = '$valor'.trim();
    if (texto.isEmpty || texto == 'null') return null;
    if (texto.startsWith('http://') || texto.startsWith('https://')) {
      return texto;
    }
    final limpia = texto.startsWith('/') ? texto.substring(1) : texto;
    if (limpia.startsWith('storage/')) {
      return '$apiOrigen/$limpia';
    }
    return '$apiOrigen/storage/$limpia';
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
    fotoPerfil = formatearUrlFoto(valores[5]);
    usuarioId = int.tryParse(valores[6] ?? '');
    cambios.value++;
  }

  static Future<void> guardar({
    required String token,
    int? usuarioId,
    String? nombre,
    String? telefono,
    String? correo,
    int? rolId,
    String? fotoPerfil,
  }) async {
    final fotoFormateada = formatearUrlFoto(fotoPerfil);
    await _almacen.write(key: _claves[1], value: nombre);
    await _almacen.write(key: _claves[2], value: telefono);
    await _almacen.write(key: _claves[3], value: correo);
    await _almacen.write(key: _claves[4], value: rolId?.toString());
    await _almacen.write(key: _claves[5], value: fotoFormateada);
    await _almacen.write(
      key: _claves[6],
      value: (usuarioId ?? Sesion.usuarioId)?.toString(),
    );
    await _almacen.write(key: _claves[0], value: token);

    Sesion.token = token;
    if (usuarioId != null) Sesion.usuarioId = usuarioId;
    Sesion.nombre = nombre;
    Sesion.telefono = telefono;
    Sesion.correo = correo;
    Sesion.rolId = rolId;
    Sesion.fotoPerfil = fotoFormateada;
    cambios.value++;
  }

  static Future<void> actualizarPerfil({
    int? usuarioId,
    required String nombre,
    required String correo,
    required String telefono,
    String? fotoPerfil,
  }) async {
    final tokenActual = token;
    if (tokenActual == null || tokenActual.isEmpty) return;
    await guardar(
      token: tokenActual,
      usuarioId: usuarioId ?? Sesion.usuarioId,
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      rolId: rolId,
      fotoPerfil: fotoPerfil,
    );
  }

  static Future<void> limpiar() async {
    token = null;
    usuarioId = null;
    nombre = null;
    telefono = null;
    correo = null;
    fotoPerfil = null;
    rolId = null;
    await Future.wait(
      _claves.map((clave) => _almacen.write(key: clave, value: null)),
    );
    cambios.value++;
  }

  static Future<void> invalidar(String tokenUsado) async {
    if (!activa || token != tokenUsado || _invalidando) return;
    _invalidando = true;
    try {
      await limpiar();
    } finally {
      _invalidando = false;
      alExpirar?.call();
    }
  }
}
