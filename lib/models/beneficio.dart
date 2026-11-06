class Beneficio {
  final String titulo;
  final String tipo;
  final String fechaInicio;
  final String fechaFin;
  final String? imagenUrl;

  Beneficio({
    required this.titulo,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    this.imagenUrl,
  });

  factory Beneficio.fromJson(Map<String, dynamic> json) => Beneficio(
    titulo: '${json['titulo']}',
    tipo: '${json['Tipo_beneficio']}',
    fechaInicio: '${json['Fecha_inicio']}',
    fechaFin: '${json['Fecha_fin']}',
    imagenUrl: json['imagen_url'] as String?,
  );
}
