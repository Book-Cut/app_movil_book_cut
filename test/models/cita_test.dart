import 'package:book_cut_app/models/barbero.dart';
import 'package:book_cut_app/models/cita.dart';
import 'package:book_cut_app/models/perfil.dart';
import 'package:book_cut_app/models/servicio.dart';
import 'package:book_cut_app/models/valoracion.dart';
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

    test('parsea cliente, factura, valoracion, total y cita afectada', () {
      final cita = Cita.fromJson({
        'idCita': 99,
        'Fecha_hora': '2026-11-12 15:00:00',
        'estado': 'Finalizado',
        'estado_pago': 'Pagado',
        'modalidad_pago': 'Presencial',
        'nombre_cliente': 'Mateo Ruiz',
        'telefono_cliente': '3001112233',
        'barbero': {'idUsuario': 2, 'Nombre': 'Carlos Gomez'},
        'servicios': [
          {
            'idServicio': 3,
            'Nombre': 'Corte y Barba Premium',
            'pivot': {
              'fecha_hora_servicio': '2026-11-12 15:00:00',
              'duracion_servicio': 60,
              'precio_servicio': 35000,
            },
          },
        ],
        'factura': {
          'numero_factura': 'FAC-012',
          'fecha_emision': '2026-11-12 16:00:00',
          'subtotal': 35000,
          'total_pagar': 35000,
          'metodo_pago': 'Nequi',
          'estado_factura': 'Pagada',
        },
        'valora': {
          'Idvalora': 7,
          'EvaluacionBar': 5,
          'Comentario': 'Excelente servicio',
          'Fecha_evaluacion_cita': '2026-11-12 16:10:00',
        },
      });

      expect(cita.clienteNombre, 'Mateo Ruiz');
      expect(cita.clienteTelefono, '3001112233');
      expect(cita.total, 35000);
      expect(cita.factura?.numero, 'FAC-012');
      expect(cita.factura?.metodoPago, 'Nequi');
      expect(cita.valoracion?.puntuacion, 5);
      expect(cita.valoracion?.comentario, 'Excelente servicio');
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
        inicio: ahora.add(const Duration(hours: 1, minutes: 30)),
        fin: ahora.add(const Duration(hours: 2)),
        confirmacionPendiente: false,
        confirmacionSolicitadaAt: null,
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

    test('cita afectada pendiente permite reagendar incluso dentro de las 2 horas', () {
      final ahora = DateTime.now();
      final afectada = Cita(
        id: 88,
        barberoId: 2,
        barbero: 'Carlos Gomez',
        estado: 'Confirmado',
        estadoPago: 'Pendiente',
        modalidadPago: 'Presencial',
        inicio: ahora.add(const Duration(minutes: 45)),
        fin: ahora.add(const Duration(minutes: 105)),
        confirmacionPendiente: false,
        afectadaPendiente: true,
        motivoAfectada: 'Incapacidad médica',
        servicios: const [],
      );

      expect(afectada.puedeReagendar, isTrue);
      expect(afectada.motivoAfectada, 'Incapacidad médica');
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

  group('Modelos de Barbero, Perfil y ValoracionRecibida', () {
    test('Barbero.ofreceServicio valida por nombre y por ids', () {
      final corte = Servicio(
        id: 1,
        nombre: 'Corte Clasico',
        duracion: 30,
        precio: 20000,
      );
      final barba = Servicio(
        id: 2,
        nombre: 'Perfilado de Barba',
        duracion: 20,
        precio: 15000,
      );

      final barberoTexto = Barbero.fromJson({
        'idUsuario': 2,
        'Nombre': 'Carlos',
        'especialidad': 'Corte Clasico',
      });
      expect(barberoTexto.ofreceServicio(corte), isTrue);
      expect(barberoTexto.ofreceServicio(barba), isFalse);

      final barberoLista = Barbero.fromJson({
        'idUsuario': 3,
        'Nombre': 'Andres',
        'especialidad': [
          {'idServicio': 2, 'Nombre': 'Perfilado de Barba'},
        ],
      });
      expect(barberoLista.ofreceServicio(corte), isFalse);
      expect(barberoLista.ofreceServicio(barba), isTrue);
    });

    test('Perfil.fromJson parsea especialidades y horarios de barbero', () {
      final perfil = Perfil.fromJson({
        'idUsuario': 2,
        'Nombre': 'Carlos Gomez',
        'correo': 'carlos@gmail.com',
        'telefono': '3001234567',
        'servicio_ids': [1, 3],
        'horarios': [
          {'diasemana': 'Lunes', 'horainicio': '09:00', 'horafin': '18:00'},
        ],
      });

      expect(perfil.servicioIds, [1, 3]);
      expect(perfil.horarios.length, 1);
      expect(perfil.horarios.first.diasemana, 'Lunes');
      expect(perfil.horarios.first.horainicio, '09:00');
      expect(perfil.horarios.first.horafin, '18:00');
    });

    test('ValoracionRecibida.fromJson normaliza comentario vacio o guion', () {
      final val = ValoracionRecibida.fromJson({
        'idValora': 1,
        'idCita': 10,
        'puntuacion': 4,
        'comentario': '—',
        'Fecha': '10/11/2026',
        'Cliente': 'Luis',
        'Servicios': 'Corte Clasico',
      });

      expect(val.puntuacion, 4);
      expect(val.comentario, isNull);
      expect(val.cliente, 'Luis');
    });

    test(
      'construirHorariosBarberia y reconciliarHorariosConBarberia adaptan franjas',
      () {
        final barberia = construirHorariosBarberia([
          {'diasemana': 'Lunes', 'horainicio': '09:00:00', 'horafin': '19:00:00'},
          {
            'diasemana': 'Miercoles',
            'horainicio': '10:00:00',
            'horafin': '18:00:00',
          },
          {
            'diasemana': 'Sabado',
            'horainicio': '10:00:00',
            'horafin': '20:00:00',
          },
        ]);

        expect(barberia.keys, containsAll(['Lunes', 'Miércoles', 'Sábado']));
        expect(barberia['Miércoles']?.horainicio, '10:00');
        expect(barberia['Sábado']?.horafin, '20:00');

        final sinCambios = reconciliarHorariosConBarberia([
          const HorarioPerfil(
            diasemana: 'Lunes',
            horainicio: '09:00',
            horafin: '19:00',
          ),
        ], barberia);
        expect(sinCambios.ajustado, isFalse);
        expect(sinCambios.horarios.length, 1);

        final conAjustes = reconciliarHorariosConBarberia([
          const HorarioPerfil(
            diasemana: 'Sábado',
            horainicio: '09:00',
            horafin: '21:00',
          ),
          const HorarioPerfil(
            diasemana: 'Domingo',
            horainicio: '10:00',
            horafin: '16:00',
          ),
          const HorarioPerfil(
            diasemana: 'Miércoles',
            horainicio: '09:00',
            horafin: '19:00',
          ),
        ], barberia);

        expect(conAjustes.ajustado, isTrue);
        expect(conAjustes.horarios.map((h) => h.diasemana).toList(), [
          'Miércoles',
          'Sábado',
        ]);
        expect(conAjustes.horarios.first.horainicio, '10:00');
        expect(conAjustes.horarios.first.horafin, '18:00');
        expect(conAjustes.horarios.last.horainicio, '10:00');
        expect(conAjustes.horarios.last.horafin, '20:00');
      },
    );
  });
}
