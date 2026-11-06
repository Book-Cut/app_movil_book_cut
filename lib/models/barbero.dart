class Barbero {
  final int id;
  final String nombre;
  final String especialidad;

  Barbero({required this.id, required this.nombre, required this.especialidad});

  factory Barbero.fromJson(Map<String, dynamic> json) => Barbero(
    id: int.tryParse('${json['idUsuario']}') ?? 0,
    nombre: '${json['Nombre']}',
    especialidad: json['especialidad'] == null ? '' : '${json['especialidad']}',
  );
}
