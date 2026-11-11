import 'package:flutter/material.dart';

import '../core/colores.dart';
import '../core/sesion.dart';
import '../services/autenticacion_service.dart';
import '../views/pantalla_bienvenida.dart';

Future<void> confirmarYCerrarSesion(BuildContext context) async {
  final confirmar = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (contexto) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colores.azulOscuro,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a ingresar tus credenciales para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colores.gris,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(contexto, true),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Sí, cerrar sesión',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(contexto, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Permanecer en la cuenta',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (confirmar != true) return;

  try {
    await cerrarSesion();
  } catch (_) {}
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const PantallaBienvenida()),
    (_) => false,
  );
}

void mostrarMenuCuenta(
  BuildContext context, {
  VoidCallback? onMisCitas,
  VoidCallback? onPerfil,
  VoidCallback? onLogin,
  VoidCallback? onRegistro,
  VoidCallback? onLogout,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (Sesion.activa) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colores.fondo,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colores.azulOscuro,
                      child: ClipOval(
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Sesion.fotoPerfil != null &&
                                  Sesion.fotoPerfil!.isNotEmpty
                              ? Image.network(
                                  Sesion.fotoPerfil!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Sesion.nombre ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Sesion.correo ?? Sesion.telefono ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colores.gris,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colores.carmin.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              Sesion.rol,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colores.carmin,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (Sesion.activa && Sesion.rolId == 3 && onMisCitas != null)
              _itemMenuSheet(
                ctx,
                icono: Icons.calendar_month_rounded,
                colorIcono: const Color(0xFF2563EB),
                fondoIcono: const Color(0xFFEFF6FF),
                titulo: 'Mis citas',
                subtitulo: 'Revisa tus citas programadas e historial',
                onTap: onMisCitas,
              ),
            if (Sesion.activa && onPerfil != null)
              _itemMenuSheet(
                ctx,
                icono: Icons.person_rounded,
                colorIcono: Colores.carmin,
                fondoIcono: const Color(0xFFFFF1F2),
                titulo: 'Mi perfil',
                subtitulo: Sesion.rolId == 2
                    ? 'Datos, foto, especialidad y horarios'
                    : 'Datos personales, contacto y foto',
                onTap: onPerfil,
              ),
            if (Sesion.activa && onLogout != null)
              _itemMenuSheet(
                ctx,
                icono: Icons.logout_rounded,
                colorIcono: Colors.red.shade600,
                fondoIcono: const Color(0xFFFEF2F2),
                titulo: 'Cerrar sesión',
                subtitulo: 'Salir de tu cuenta en este teléfono',
                esPeligro: true,
                onTap: onLogout,
              ),
            if (!Sesion.activa && onLogin != null)
              _itemMenuSheet(
                ctx,
                icono: Icons.login_rounded,
                colorIcono: Colores.carmin,
                fondoIcono: const Color(0xFFFFF1F2),
                titulo: 'Iniciar sesión',
                subtitulo: 'Accede para ver horarios y agendar citas',
                onTap: onLogin,
              ),
            if (!Sesion.activa && onRegistro != null)
              _itemMenuSheet(
                ctx,
                icono: Icons.person_add_alt_1_rounded,
                colorIcono: Colores.azulOscuro,
                fondoIcono: const Color(0xFFF1F5F9),
                titulo: 'Crear cuenta',
                subtitulo: 'Regístrate en pocos pasos para reservar',
                onTap: onRegistro,
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _itemMenuSheet(
  BuildContext ctx, {
  required IconData icono,
  required Color colorIcono,
  required Color fondoIcono,
  required String titulo,
  required String subtitulo,
  required VoidCallback onTap,
  bool esPeligro = false,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    decoration: BoxDecoration(
      color: esPeligro ? const Color(0xFFFFF5F5) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: esPeligro ? const Color(0xFFFED7D7) : const Color(0xFFE4E4E7),
      ),
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: fondoIcono,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: colorIcono, size: 22),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: esPeligro ? Colors.red.shade700 : Colores.azulOscuro,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          color: esPeligro ? Colors.red.shade400 : Colores.gris,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: esPeligro ? Colors.red.shade300 : Colores.gris,
        size: 20,
      ),
    ),
  );
}

/// Muestra un aviso claro cuando un invitado intenta reservar y lo dirige a registrarse o iniciar sesión.
/// Devuelve `'registro'`, `'login'` o `null`.
Future<String?> pedirAccesoParaReservar(
  BuildContext context, {
  String? nombreBarbero,
  int cantidadServicios = 1,
}) {
  final resumen = nombreBarbero == null
      ? '$cantidadServicios ${cantidadServicios == 1 ? 'servicio seleccionado' : 'servicios seleccionados'}'
      : '$cantidadServicios ${cantidadServicios == 1 ? 'servicio' : 'servicios'} con $nombreBarbero';

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colores.carmin,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inicia sesión para reservar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colores.azulOscuro,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para consultar los horarios disponibles y confirmar tu cita ($resumen), necesitas iniciar sesión o crear una cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colores.gris,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'registro'),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    'Crear cuenta para reservar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'login'),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    'Ya tengo cuenta · Iniciar sesión',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
