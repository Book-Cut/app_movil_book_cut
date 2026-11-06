class Servicio {
  final int id;
  final String nombre;
  final int duracion;

  Servicio({required this.id, required this.nombre, required this.duracion});

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: int.tryParse('${json['idServicio']}') ?? 0,
    nombre: '${json['Nombre']}',
    duracion: int.tryParse('${json['Duracion']}') ?? 0,
  );

  String get descripcion =>
      'Servicio de $nombre, con duración de $duracion minutos.';
}
