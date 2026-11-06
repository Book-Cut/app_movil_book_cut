const nombresMeses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// 2026-11-09, el formato que pide la API
String fechaApi(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

/// 9 de noviembre de 2026
String fechaLarga(DateTime f) =>
    '${f.day} de ${nombresMeses[f.month - 1].toLowerCase()} de ${f.year}';

/// "14:30" -> "2:30 PM"
String horaBonita(String hora) {
  final partes = hora.split(':');
  final h = int.tryParse(partes.first) ?? 0;
  final m = partes.length > 1 ? partes[1] : '00';
  final sufijo = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $sufijo';
}
