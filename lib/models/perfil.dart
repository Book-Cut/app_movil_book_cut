class Perfil {
  final int id;
  final String nombre;
  final String correo;
  final String telefono;
  final String? fotoPerfil;

  const Perfil({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.fotoPerfil,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
    id: int.tryParse('${json['idUsuario']}') ?? 0,
    nombre: '${json['Nombre'] ?? ''}',
    correo: '${json['correo'] ?? ''}',
    telefono: '${json['telefono'] ?? ''}',
    fotoPerfil: json['foto_perfil'] is String
        ? json['foto_perfil'] as String
        : null,
  );
}
