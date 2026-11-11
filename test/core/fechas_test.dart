import 'package:book_cut_app/core/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('horaCompatibleConDuracion', () {
    test('en citas de 60 minutos excluye intervalos de 30 minutos como 11:30', () {
      expect(horaCompatibleConDuracion('10:00', 60), isTrue);
      expect(horaCompatibleConDuracion('11:00', 60), isTrue);
      expect(horaCompatibleConDuracion('14:00', 60), isTrue);

      expect(horaCompatibleConDuracion('10:30', 60), isFalse);
      expect(horaCompatibleConDuracion('11:30', 60), isFalse);
      expect(horaCompatibleConDuracion('13:30', 60), isFalse);
    });

    test('en citas de 120 minutos tambien exige horas en punto', () {
      expect(horaCompatibleConDuracion('09:00', 120), isTrue);
      expect(horaCompatibleConDuracion('09:30', 120), isFalse);
    });

    test('en citas de 30 o 20 minutos mantiene bloques con :30', () {
      expect(horaCompatibleConDuracion('11:00', 30), isTrue);
      expect(horaCompatibleConDuracion('11:30', 30), isTrue);
      expect(horaCompatibleConDuracion('11:30', 20), isTrue);
    });
  });

  group('precioBonito', () {
    test('formatea precios en pesos con separador de miles', () {
      expect(precioBonito(0), '\$0');
      expect(precioBonito(18000), '\$18.000');
      expect(precioBonito(88000), '\$88.000');
      expect(precioBonito(1250000), '\$1.250.000');
    });
  });
}
