import 'dart:convert';

import 'package:http/http.dart' as http;

const apiUrl = 'https://bookcut.api.adsocidm.com/public/api';

/// Pide una lista a la API. Tu backend responde { "data": [...] }
Future<List<dynamic>> obtenerLista(String ruta) async {
  final respuesta = await http.get(
    Uri.parse('$apiUrl$ruta'),
    headers: {'Accept': 'application/json'},
  );
  if (respuesta.statusCode != 200) {
    throw Exception('Error de API (${respuesta.statusCode})');
  }
  final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
  return cuerpo['data'] as List<dynamic>;
}
