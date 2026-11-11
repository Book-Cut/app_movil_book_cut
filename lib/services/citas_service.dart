import '../core/api.dart';
import '../core/fechas.dart';
import '../models/barbero.dart';
import '../models/cita.dart';
import '../models/servicio.dart';

Future<List<Cita>> listarCitas() async {
  final datos = await obtenerLista('/citas', conToken: true);
  try {
    return datos.map((cita) {
      if (cita is! Map) {
        throw const FormatException('La cita tiene un formato inválido.');
      }
      return Cita.fromJson(Map<String, dynamic>.from(cita));
    }).toList();
  } on FormatException {
    throw ApiException('El servidor devolvió una cita inválida.');
  }
}

Future<List<Cita>> listarCitasCliente() => listarCitas();

Future<void> crearCita({
  required Barbero? barbero,
  required List<Servicio> servicios,
  required DateTime fecha,
  required List<String?> horasPorServicio,
  required String nombreCliente,
  required String telefonoCliente,
}) async {
  final nombre = nombreCliente.trim();
  final telefono = telefonoCliente.trim();
  if (nombre.isEmpty || telefono.isEmpty) {
    throw ApiException('Ingresa tu nombre y teléfono antes de reservar.');
  }

  if (servicios.isEmpty) {
    throw ApiException('Selecciona al menos un servicio para reservar.');
  }

  if (horasPorServicio.length != servicios.length) {
    throw ApiException('Selecciona un horario para cada servicio.');
  }

  final serviciosConHorario = List.generate(servicios.length, (indice) {
    final servicio = servicios[indice];
    final hora = horasPorServicio[indice];
    if (hora == null) {
      throw ApiException('Selecciona un horario para cada servicio.');
    }
    return {
      'idServicio': servicio.id,
      'fecha_hora_servicio': '${fechaApi(fecha)} $hora:00',
    };
  }).toList();
  final horasSeleccionadas = horasPorServicio.whereType<String>().toList();
  final primeraHora = horasSeleccionadas.reduce(
    (primera, hora) => hora.compareTo(primera) < 0 ? hora : primera,
  );

  final payload = <String, dynamic>{
    'Fecha_hora': '${fechaApi(fecha)} $primeraHora:00',
    if (barbero != null) 'Usuario_idUsuarioBar': barbero.id,
    'nombre_cliente': nombre,
    'telefono_cliente': telefono,
    'es_continuo': false,
    'modalidad_pago': 'Presencial',
    'servicios': serviciosConHorario,
  };

  await enviarJson(
    '/citas',
    payload,
    conToken: true,
    codigosExitosos: const {201},
  );
}

Future<void> confirmarAsistenciaCita(int idCita) async {
  await actualizarJson(
    '/citas/$idCita/confirmar-asistencia',
    {},
    conToken: true,
  );
}

Future<void> cancelarCitaCliente(int idCita) async {
  await eliminarJson('/citas/$idCita', conToken: true);
}

Future<bool> cancelarCitaBarbero(int idCita, {required String motivo}) async {
  final motivoLimpio = motivo.trim();
  if (motivoLimpio.isEmpty) {
    throw ApiException('Ingresa el motivo de la cancelación.');
  }
  final respuesta = await eliminarJson(
    '/citas/$idCita',
    datos: {'motivo': motivoLimpio},
    conToken: true,
  );
  return respuesta['correo_enviado'] == true;
}

Future<void> finalizarCita(int idCita) async {
  await actualizarJson('/citas/$idCita/finalizar', {}, conToken: true);
}

Future<void> registrarPagoCita(int idCita, {required String metodoPago}) async {
  await enviarJson(
    '/citas/$idCita/pago',
    {'metodo_pago': metodoPago},
    conToken: true,
  );
}

Future<void> reagendarCitaCliente({
  required int idCita,
  required DateTime fecha,
  required String hora,
}) async {
  await actualizarJson(
    '/citas/$idCita/reagendar',
    {'fecha': fechaApi(fecha), 'hora': hora},
    conToken: true,
  );
}
