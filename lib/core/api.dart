import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sesion.dart';

const apiUrl = 'https://bookcut.api.adsocidm.com/api';
const _timeoutApi = Duration(seconds: 20);

class ApiException implements Exception {
  final int? codigo;
  final String mensaje;
  ApiException(this.mensaje, {this.codigo});

  @override
  String toString() => mensaje;
}

Future<Map<String, dynamic>> enviarJson(
  String ruta,
  Map<String, dynamic> datos, {
  bool conToken = false,
  Set<int> codigosExitosos = const {200},
}) async {
  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  if (conToken) {
    if (!Sesion.activa) {
      throw ApiException('Inicia sesión para continuar.', codigo: 401);
    }
    headers['Authorization'] = 'Bearer ${Sesion.token}';
  }

  final respuesta = await http
      .post(
        Uri.parse('$apiUrl$ruta'),
        headers: headers,
        body: jsonEncode(datos),
      )
      .timeout(_timeoutApi);
  final cuerpo = _decodificarRespuesta(respuesta);
  if (!codigosExitosos.contains(respuesta.statusCode)) {
    throw ApiException(
      _mensajeError(cuerpo, respuesta.statusCode),
      codigo: respuesta.statusCode,
    );
  }
  return cuerpo;
}

Future<Map<String, dynamic>> obtenerJson(
  String ruta, {
  bool conToken = false,
}) async {
  final headers = _encabezados(conToken: conToken);
  final respuesta = await http
      .get(Uri.parse('$apiUrl$ruta'), headers: headers)
      .timeout(_timeoutApi);
  return _validarRespuesta(respuesta, const {200});
}

Future<Map<String, dynamic>> actualizarJson(
  String ruta,
  Map<String, dynamic> datos, {
  bool conToken = false,
}) async {
  final headers = _encabezados(conToken: conToken, json: true);
  final respuesta = await http
      .patch(
        Uri.parse('$apiUrl$ruta'),
        headers: headers,
        body: jsonEncode(datos),
      )
      .timeout(_timeoutApi);
  return _validarRespuesta(respuesta, const {200});
}

/// Pide una lista a la API. Tu backend responde { "data": [...] }
Future<List<dynamic>> obtenerLista(
  String ruta, {
  Map<String, String>? parametros,
  bool conToken = false,
}) async {
  final headers = _encabezados(conToken: conToken);
  final uri = Uri.parse('$apiUrl$ruta').replace(queryParameters: parametros);
  final respuesta = await http.get(uri, headers: headers).timeout(_timeoutApi);
  if (respuesta.statusCode != 200) {
    throw ApiException(
      _mensajeError(_decodificarRespuesta(respuesta), respuesta.statusCode),
      codigo: respuesta.statusCode,
    );
  }
  final cuerpo = _decodificarRespuesta(respuesta);
  final datos = cuerpo['data'];
  if (datos is! List<dynamic>) {
    throw ApiException('El servidor devolvió una lista inválida.');
  }
  return datos;
}

Map<String, String> _encabezados({bool conToken = false, bool json = false}) {
  final headers = <String, String>{'Accept': 'application/json'};
  if (json) headers['Content-Type'] = 'application/json';
  if (conToken) {
    if (!Sesion.activa) {
      throw ApiException('Inicia sesión para continuar.', codigo: 401);
    }
    headers['Authorization'] = 'Bearer ${Sesion.token}';
  }
  return headers;
}

Map<String, dynamic> _validarRespuesta(
  http.Response respuesta,
  Set<int> codigosExitosos,
) {
  final cuerpo = _decodificarRespuesta(respuesta);
  if (!codigosExitosos.contains(respuesta.statusCode)) {
    throw ApiException(
      _mensajeError(cuerpo, respuesta.statusCode),
      codigo: respuesta.statusCode,
    );
  }
  return cuerpo;
}

Map<String, dynamic> _decodificarRespuesta(http.Response respuesta) {
  try {
    final decoded = jsonDecode(respuesta.body);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    throw ApiException(
      'El servidor devolvió una respuesta inválida.',
      codigo: respuesta.statusCode,
    );
  }
  throw ApiException(
    'El servidor devolvió una respuesta inválida.',
    codigo: respuesta.statusCode,
  );
}

String _mensajeError(Map<String, dynamic> cuerpo, int codigo) {
  final errores = cuerpo['errors'];
  if (errores is Map) {
    for (final error in errores.values) {
      if (error is List && error.isNotEmpty) return '${error.first}';
      if (error is String && error.isNotEmpty) return error;
    }
  }
  final mensaje = cuerpo['message'];
  return mensaje is String && mensaje.isNotEmpty
      ? mensaje
      : 'Error de API ($codigo).';
}
