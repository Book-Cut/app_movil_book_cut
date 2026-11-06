import '../core/api.dart';
import '../core/fechas.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';

Future<void> crearCita({
  required Barbero barbero,
  required List<Servicio> servicios,
  required DateTime fecha,
  required String hora,
}) async {
  final nombre = Sesion.nombre?.trim();
  final telefono = Sesion.telefono?.trim();
  if (nombre == null ||
      nombre.isEmpty ||
      telefono == null ||
      telefono.isEmpty) {
    throw ApiException(
      'Tu cuenta no tiene un teléfono registrado. Actualízalo antes de reservar.',
    );
  }

  await enviarJson(
    '/citas',
    {
      'Fecha_hora': '${fechaApi(fecha)} $hora:00',
      'Usuario_idUsuarioBar': barbero.id,
      'nombre_cliente': nombre,
      'telefono_cliente': telefono,
      'es_continuo': true,
      'modalidad_pago': 'Presencial',
      'servicios': servicios
          .map((servicio) => {'idServicio': servicio.id})
          .toList(),
    },
    conToken: true,
    codigosExitosos: const {201},
  );
}
