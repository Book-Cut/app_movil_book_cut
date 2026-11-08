import 'package:book_cut_app/models/servicio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Servicio.fromJson reads duration and price from the catalog', () {
    final servicio = Servicio.fromJson({
      'idServicio': 4,
      'Nombre': 'Corte',
      'Duracion': '30',
      'Precio': '25000.00',
    });

    expect(servicio.id, 4);
    expect(servicio.nombre, 'Corte');
    expect(servicio.duracion, 30);
    expect(servicio.precio, 25000);
  });
}
