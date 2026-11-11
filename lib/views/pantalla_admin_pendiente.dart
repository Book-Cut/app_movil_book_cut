import 'package:flutter/material.dart';

import '../components/dialogos_cuenta.dart';
import '../components/encabezado_usuario.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import 'pantalla_perfil.dart';

class PantallaAdminPendiente extends StatefulWidget {
  const PantallaAdminPendiente({super.key});

  @override
  State<PantallaAdminPendiente> createState() => _PantallaAdminPendienteState();
}

class _PantallaAdminPendienteState extends State<PantallaAdminPendiente> {
  @override
  void initState() {
    super.initState();
    Sesion.cambios.addListener(_alCambiarSesion);
  }

  @override
  void dispose() {
    Sesion.cambios.removeListener(_alCambiarSesion);
    super.dispose();
  }

  void _alCambiarSesion() {
    if (mounted) setState(() {});
  }

  void _abrirMenu() {
    mostrarMenuCuenta(
      context,
      onPerfil: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const PantallaPerfil()),
        );
        if (mounted) setState(() {});
      },
      onLogout: () => confirmarYCerrarSesion(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = Sesion.primerNombre.isNotEmpty
        ? Sesion.primerNombre
        : 'Administrador';

    return Scaffold(
      backgroundColor: Colores.fondo,
      body: Column(
        children: [
          EncabezadoUsuario(
            linea1: 'Panel Admin',
            linea2: 'Hola, $nombre',
            fotoPerfil: Sesion.fotoPerfil,
            onAvatarTap: _abrirMenu,
            accion: IconButton(
              tooltip: 'Cuenta',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _abrirMenu,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colores.grisBorde),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colores.azulOscuro,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'El panel de administrador aún está pendiente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colores.azulOscuro,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PantallaPerfil(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Ir a mi perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.azulOscuro,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => confirmarYCerrarSesion(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Cerrar sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECACA)),
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
          ),
        ],
      ),
    );
  }
}
