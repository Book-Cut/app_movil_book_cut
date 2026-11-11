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

/// 35000 -> "$35.000"
String precioBonito(num valor) {
  final negativo = valor < 0;
  final entero = valor.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    final indiceDesdeFin = entero.length - i;
    if (i > 0 && indiceDesdeFin % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(entero[i]);
  }
  return '${negativo ? '-' : ''}\$${buffer.toString()}';
}

/// En servicios de 60 minutos (o múltiplos exactos de 60), solo se muestran horas en punto (sin :30).
bool horaCompatibleConDuracion(String hora, int duracion) {
  if (duracion >= 60 && duracion % 60 == 0) {
    final partes = hora.split(':');
    if (partes.length < 2) return false;
    final min = int.tryParse(partes[1]);
    return min != null && min % 60 == 0;
  }
  return true;
}
