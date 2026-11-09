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
        'Usuario_idUsuarioBar': 5,
        'barbero': {'idUsuario': 5, 'Nombre': 'Andrés'},
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
      expect(cita.barberoId, 5);
      expect(cita.barbero, 'Andrés');
      expect(cita.confirmacionPendiente, isTrue);
      expect(cita.duracionTotalMinutos, 50);
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

  group('Reglas de confirmacion, reagendamiento y cancelacion', () {
    test('puede reagendar y cancelar con anticipacion mayor a 2 horas', () {
      final citaFutura = Cita(
        id: 1,
        barberoId: 3,
        barbero: 'Carlos',
        estado: 'Confirmado',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: DateTime.now().add(const Duration(hours: 5)),
        fin: DateTime.now().add(const Duration(hours: 5, minutes: 40)),
        confirmacionPendiente: false,
        confirmacionSolicitadaAt: null,
        servicios: const [],
      );

      expect(citaFutura.puedeReagendar, isTrue);
      expect(citaFutura.puedeCancelar, isTrue);
    });

    test('puede reagendar y cancelar durante la ventana de confirmacion de 30 min (2h antes)', () {
      final ahora = DateTime.now();
      final citaEnConfirmacion = Cita(
        id: 2,
        barberoId: 3,
        barbero: 'Carlos',
        estado: 'Pendiente',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: ahora.add(const Duration(hours: 1, minutes: 50)),
        fin: ahora.add(const Duration(hours: 2, minutes: 30)),
        confirmacionPendiente: true,
        confirmacionSolicitadaAt: ahora.subtract(const Duration(minutes: 10)),
        servicios: const [],
      );

      expect(citaEnConfirmacion.enVentanaConfirmacion, isTrue);
      expect(citaEnConfirmacion.minutosRestantesConfirmacion, inInclusiveRange(19, 21));
      expect(citaEnConfirmacion.puedeReagendar, isTrue);
      expect(citaEnConfirmacion.puedeCancelar, isTrue);
    });

    test('NO puede reagendar pero SI puede cancelar si ya confirmo asistencia dentro de las 2 horas', () {
      final ahora = DateTime.now();
      final citaConfirmada = Cita(
        id: 3,
        barberoId: 3,
        barbero: 'Carlos',
        estado: 'Confirmado',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: ahora.add(const Duration(hours: 1, minutes: 30)), // a hora y media
        fin: ahora.add(const Duration(hours: 2)),
        confirmacionPendiente: false,
        confirmacionSolicitadaAt: null, // ya confirmó, por lo que solicitada_at se reseteó
        servicios: const [],
      );

      expect(citaConfirmada.enVentanaConfirmacion, isFalse);
      expect(citaConfirmada.puedeReagendar, isFalse);
      expect(citaConfirmada.puedeCancelar, isTrue);
    });

    test('NO puede reagendar NI cancelar si la cita esta cancelada o finalizada', () {
      final citaCancelada = Cita(
        id: 4,
        barberoId: 3,
        barbero: 'Carlos',
        estado: 'Cancelado',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: DateTime.now().add(const Duration(days: 2)),
        fin: DateTime.now().add(const Duration(days: 2, minutes: 30)),
        confirmacionPendiente: false,
        confirmacionSolicitadaAt: null,
        servicios: const [],
      );

      expect(citaCancelada.puedeReagendar, isFalse);
      expect(citaCancelada.puedeCancelar, isFalse);
    });

    test('copyWith clona y actualiza propiedades correctamente', () {
      final cita = Cita(
        id: 5,
        barberoId: 1,
        barbero: 'Carlos',
        estado: 'Confirmado',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: DateTime.now().add(const Duration(days: 1)),
        fin: DateTime.now().add(const Duration(days: 1, minutes: 30)),
        confirmacionPendiente: false,
        confirmacionSolicitadaAt: null,
        servicios: const [],
      );

      final cancelada = cita.copyWith(estado: 'Cancelado');
      expect(cancelada.id, 5);
      expect(cancelada.estado, 'Cancelado');
      expect(cancelada.puedeCancelar, isFalse);
    });
  });
}
