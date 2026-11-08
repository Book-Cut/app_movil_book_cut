class Servicio {
  final int id;
  final String nombre;
  final int duracion;
  final double precio;

  Servicio({
    required this.id,
    required this.nombre,
    required this.duracion,
    this.precio = 0,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: int.tryParse('${json['idServicio']}') ?? 0,
    nombre: '${json['Nombre']}',
    duracion: int.tryParse('${json['Duracion']}') ?? 0,
    precio: double.tryParse('${json['Precio']}') ?? 0,
  );

  String get descripcion =>
      'Servicio de $nombre, con duración de $duracion minutos.';
}
