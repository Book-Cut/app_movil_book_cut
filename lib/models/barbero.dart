class Barbero {
  final int id;
  final String nombre;
  final String especialidad;
  final String? fotoPerfil;

  const Barbero({
    required this.id,
    required this.nombre,
    required this.especialidad,
    this.fotoPerfil,
  });

  factory Barbero.fromJson(Map<String, dynamic> json) {
    return Barbero(
      id: int.tryParse('${json['idUsuario']}') ?? 0,
      nombre: '${json['Nombre'] ?? 'Barbero'}',
      especialidad: _parseEspecialidad(json['especialidad']),
      fotoPerfil: _formatearUrlFoto(json['foto_perfil']),
    );
  }
}

String _parseEspecialidad(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw;
  if (raw is List) {
    return raw
        .map((e) {
          if (e is Map) return e['Nombre']?.toString();
          return e?.toString();
        })
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
  }
  return '$raw';
}

String? _formatearUrlFoto(dynamic valor) {
  if (valor == null) return null;
  final texto = '$valor'.trim();
  if (texto.isEmpty || texto == 'null') return null;
  if (texto.startsWith('http://') || texto.startsWith('https://')) {
    return texto;
  }
  final limpia = texto.startsWith('/') ? texto.substring(1) : texto;
  if (limpia.startsWith('storage/')) {
    return 'https://bookcut.api.adsocidm.com/$limpia';
  }
  return 'https://bookcut.api.adsocidm.com/storage/$limpia';
}
