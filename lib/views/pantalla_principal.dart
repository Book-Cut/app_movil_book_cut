import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/encabezado_usuario.dart';
import '../components/esqueleto.dart';
import '../components/etiqueta_seccion.dart';
import '../components/servicio_icono.dart';
import '../components/tarjeta_barbero.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../providers/catalogo_providers.dart';
import '../services/autenticacion_service.dart';
import '../services/citas_service.dart';
import 'pantalla_agendar.dart';
import 'pantalla_bienvenida.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_mis_citas.dart';
import 'pantalla_perfil.dart';

class PantallaPrincipal extends ConsumerStatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  ConsumerState<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends ConsumerState<PantallaPrincipal> {
  final Set<int> _elegidos = {};
  bool _verTodos = false;
  bool _alertaConfirmacion = false;

  @override
  void initState() {
    super.initState();
    _revisarConfirmaciones();
  }

  Future<void> _revisarConfirmaciones() async {
    if (!Sesion.activa || Sesion.rolId != 3) return;
    try {
      final citas = await listarCitasCliente();
      final tienePendiente = citas.any(
        (c) => c.confirmacionPendiente || c.enVentanaConfirmacion,
      );
      if (mounted) {
        setState(() => _alertaConfirmacion = tienePendiente);
      }
    } catch (_) {}
  }

  void _alternar(int id) {
    setState(() {
      if (_elegidos.contains(id)) {
        _elegidos.remove(id);
      } else {
        _elegidos.add(id);
      }
    });
  }

  void _elegirBarbero(
    Barbero? barbero,
    List<Servicio> servicios,
    List<Barbero> barberos,
  ) {
    final seleccion = servicios.where((s) => _elegidos.contains(s.id)).toList();
    if (seleccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un servicio')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaAgendar(
          barbero: barbero,
          barberos: barberos,
          servicios: seleccion,
          catalogoServicios: servicios,
        ),
      ),
    );
  }

  Future<void> _abrirCuenta(String accion) async {
    if (accion == 'mis-citas') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const PantallaMisCitas()),
      );
      _revisarConfirmaciones();
    } else if (accion == 'perfil') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const PantallaPerfil()),
      );
      if (mounted) setState(() {});
    } else if (accion == 'login') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
      );
    } else if (accion == 'logout') {
      _cerrarSesion();
    }
  }

  Future<void> _cerrarSesion() async {
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
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
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
                  '¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a ingresar tus credenciales para agendar citas.',
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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PantallaBienvenida()),
      (_) => false,
    );
  }

  void _mostrarMenuCuenta() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior de arrastre
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
              // Tarjeta resumen del usuario
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

            if (Sesion.activa && Sesion.rolId == 3)
              _itemMenuSheet(
                ctx,
                icono: Icons.calendar_month_rounded,
                colorIcono: const Color(0xFF2563EB),
                fondoIcono: const Color(0xFFEFF6FF),
                titulo: 'Mis citas',
                subtitulo: 'Revisa tus citas programadas e historial',
                onTap: () => _abrirCuenta('mis-citas'),
              ),

            if (Sesion.activa)
              _itemMenuSheet(
                ctx,
                icono: Icons.person_rounded,
                colorIcono: Colores.carmin,
                fondoIcono: const Color(0xFFFFF1F2),
                titulo: 'Mi perfil',
                subtitulo: 'Datos personales, contacto y foto',
                onTap: () => _abrirCuenta('perfil'),
              ),

            if (Sesion.activa)
              _itemMenuSheet(
                ctx,
                icono: Icons.logout_rounded,
                colorIcono: Colors.red.shade600,
                fondoIcono: const Color(0xFFFEF2F2),
                titulo: 'Cerrar sesión',
                subtitulo: 'Salir de tu cuenta en este teléfono',
                esPeligro: true,
                onTap: () => _abrirCuenta('logout'),
              ),

            if (!Sesion.activa)
              _itemMenuSheet(
                ctx,
                icono: Icons.login_rounded,
                colorIcono: Colores.carmin,
                fondoIcono: const Color(0xFFFFF1F2),
                titulo: 'Iniciar sesión',
                subtitulo: 'Accede para gestionar y agendar citas',
                onTap: () => _abrirCuenta('login'),
              ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final servicios = ref.watch(serviciosProvider);
    final barberos = ref.watch(barberosProvider);
    final nombre = Sesion.activa && Sesion.primerNombre.isNotEmpty
        ? Sesion.primerNombre
        : 'Bienvenido';

    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoUsuario(
              linea1: 'Hola',
              linea2: '$nombre!',
              fotoPerfil: Sesion.fotoPerfil,
              onAvatarTap: _mostrarMenuCuenta,
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
                onPressed: _mostrarMenuCuenta,
              ),
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EtiquetaSeccion('Servicios'),
                  const SizedBox(height: 16),
                  _bloqueServicios(servicios),
                ],
              ),
            ),

            if (_alertaConfirmacion)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaMisCitas(),
                      ),
                    );
                    _revisarConfirmaciones();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colores.carmin,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Confirmación de asistencia requerida!',
                                style: TextStyle(
                                  color: Colores.carmin,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tienes una cita próxima. Confirma tu asistencia o reagéndala antes de 30 min.',
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colores.carmin),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const EtiquetaSeccion('Barberos disponibles', clara: true),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text(
                'Elige tus servicios arriba y luego toca un barbero.',
                style: TextStyle(color: Colores.gris, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _bloqueBarberos(
                barberos,
                servicios.value,
                servicios.isLoading,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _mensajeServicios(String texto, {Widget? accion}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: const TextStyle(color: Colors.white70)),
          ),
          ?accion,
        ],
      ),
    );
  }

  Widget _bloqueServicios(AsyncValue<List<Servicio>> estado) {
    return estado.when(
      loading: () => const EfectoEsqueleto(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _EsqueletoServicio(),
              SizedBox(width: 16),
              _EsqueletoServicio(),
              SizedBox(width: 16),
              _EsqueletoServicio(),
              SizedBox(width: 16),
              _EsqueletoServicio(),
            ],
          ),
        ),
      ),
      error: (e, _) => _mensajeServicios(
        'No pudimos cargar los servicios.',
        accion: TextButton(
          onPressed: () => ref.invalidate(serviciosProvider),
          child: const Text(
            'Reintentar',
            style: TextStyle(color: Colores.rosa),
          ),
        ),
      ),
      data: (todos) {
        if (todos.isEmpty) {
          return _mensajeServicios('No hay servicios disponibles por ahora.');
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: todos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final servicio = todos[index];
              return ServicioIcono(
                servicio: servicio,
                seleccionado: _elegidos.contains(servicio.id),
                onTap: () => _alternar(servicio.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _bloqueBarberos(
    AsyncValue<List<Barbero>> estado,
    List<Servicio>? servicios,
    bool cargandoServicios,
  ) {
    return estado.when(
      loading: () => const EfectoEsqueleto(
        child: Column(
          children: [
            EsqueletoBarbero(),
            EsqueletoBarbero(),
            EsqueletoBarbero(),
          ],
        ),
      ),
      error: (e, _) => Row(
        children: [
          const Expanded(
            child: Text(
              'No pudimos cargar los barberos.',
              style: TextStyle(color: Colores.gris),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(barberosProvider),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colores.carmin),
            ),
          ),
        ],
      ),
      data: (todos) {
        if (todos.isEmpty) {
          return const Text(
            'No hay barberos disponibles.',
            style: TextStyle(color: Colores.gris),
          );
        }
        final visibles = _verTodos ? todos : todos.take(3).toList();
        return Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 1.5,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: servicios == null
                    ? cargandoServicios
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cargando servicios...'),
                              ),
                            )
                          : null
                    : () => _elegirBarbero(null, servicios, todos),
                leading: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE4E4E7),
                  child: Icon(Icons.person, size: 34, color: Color(0xFFA1A1AA)),
                ),
                title: const Text(
                  'Cualquier barbero disponible',
                  style: TextStyle(
                    color: Colores.azulOscuro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Asignaremos un profesional para tu cita.',
                  style: TextStyle(color: Colores.gris, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colores.gris),
              ),
            ),
            ...visibles.map(
              (barbero) => TarjetaBarbero(
                barbero: barbero,
                onTap: servicios == null
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            cargandoServicios
                                ? 'Cargando servicios...'
                                : 'No se pudieron cargar los servicios. Intenta de nuevo.',
                          ),
                        ),
                      )
                    : () => _elegirBarbero(barbero, servicios, todos),
              ),
            ),
            if (todos.length > 3)
              TextButton.icon(
                onPressed: () => setState(() => _verTodos = !_verTodos),
                icon: Icon(
                  _verTodos
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                label: Text(_verTodos ? 'Ver menos' : 'Ver más'),
                style: TextButton.styleFrom(
                  foregroundColor: Colores.azulOscuro,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EsqueletoServicio extends StatelessWidget {
  const _EsqueletoServicio();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 84,
      child: Column(
        children: [
          BloqueEsqueleto(
            ancho: 60,
            alto: 60,
            radio: 30,
            color: Color(0xFF3B4252),
          ),
          SizedBox(height: 8),
          BloqueEsqueleto(ancho: 60, alto: 10, color: Color(0xFF3B4252)),
          SizedBox(height: 4),
          BloqueEsqueleto(ancho: 44, alto: 10, color: Color(0xFF3B4252)),
        ],
      ),
    );
  }
}
