import 'package:book_cut_app/models/cita.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cita.fromJson', () {
    test('uses the saved service times and orders services by start time', () {
      final cita = Cita.fromJson({
        'idCita': 12,
        'Fecha_hora': '2026-11-09 10:00:00',
        'estado': 'Pendiente',
        'confirmacion_solicitada_at': '2026-11-08 09:00:00',
        'barbero': {'Nombre': 'Andrés'},
        'servicios': [
          {
            'Nombre': 'Barba',
            'pivot': {
              'fecha_hora_servicio': '2026-11-09 10:30:00',
              'duracion_servicio': 20,
              'nombre_servicio': 'Arreglo de barba',
            },
          },
          {
            'Nombre': 'Corte',
            'pivot': {
              'fecha_hora_servicio': '2026-11-09 10:00:00',
              'duracion_servicio': 30,
            },
          },
        ],
      });

      expect(cita.id, 12);
      expect(cita.barbero, 'Andrés');
      expect(cita.confirmacionPendiente, isTrue);
      expect(cita.servicios.map((servicio) => servicio.nombre), [
        'Corte',
        'Arreglo de barba',
      ]);
      expect(cita.inicio.hour, 10);
      expect(cita.fin.minute, 50);
    });

    test('continues legacy services from the appointment start time', () {
      final cita = Cita.fromJson({
        'Fecha_hora': '2026-11-09 09:00:00',
        'servicios': [
          {'Nombre': 'Corte', 'Duracion': 30},
          {'Nombre': 'Barba', 'Duracion': 15},
        ],
      });

      expect(cita.servicios[0].inicio.hour, 9);
      expect(cita.servicios[1].inicio.hour, 9);
      expect(cita.servicios[1].inicio.minute, 30);
      expect(cita.fin.minute, 45);
    });
  });
}
