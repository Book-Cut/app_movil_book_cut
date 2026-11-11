import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/dialogos_cuenta.dart';
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
import '../services/citas_service.dart';
import 'navegacion_rol.dart';
import 'pantalla_agendar.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_mis_citas.dart';
import 'pantalla_perfil.dart';
import 'pantalla_registro.dart';

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
    Sesion.cambios.addListener(_alCambiarSesion);
    _revisarConfirmaciones();
  }

  @override
  void dispose() {
    Sesion.cambios.removeListener(_alCambiarSesion);
    super.dispose();
  }

  void _alCambiarSesion() {
    if (!mounted) return;
    setState(() {});
    _revisarConfirmaciones();
  }

  Future<void> _revisarConfirmaciones() async {
    if (!Sesion.activa || Sesion.rolId != 3) {
      if (_alertaConfirmacion && mounted) {
        setState(() => _alertaConfirmacion = false);
      }
      return;
    }
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

  Future<void> _recargarCatalogo() async {
    ref.invalidate(serviciosProvider);
    ref.invalidate(barberosProvider);
    await _revisarConfirmaciones();
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

  Future<void> _elegirBarbero(
    Barbero? barbero,
    List<Servicio> servicios,
    List<Barbero> barberos,
  ) async {
    final seleccion = servicios.where((s) => _elegidos.contains(s.id)).toList();
    if (seleccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un servicio')),
      );
      return;
    }

    if (!Sesion.activa) {
      final accion = await pedirAccesoParaReservar(
        context,
        nombreBarbero: barbero?.nombre,
        cantidadServicios: seleccion.length,
      );
      if (!mounted || accion == null) return;

      final ok = await _autenticarDesdeInvitado(accion);
      if (!mounted || ok != true || !Sesion.activa) return;

      ref.invalidate(barberosProvider);
      if (Sesion.rolId != 3) {
        irAInicioPorRol(context);
        return;
      }
    } else if (Sesion.rolId != 3) {
      irAInicioPorRol(context);
      return;
    }

    await Navigator.push<void>(
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
    _revisarConfirmaciones();
  }

  Future<bool?> _autenticarDesdeInvitado(String accion) {
    if (accion == 'registro') {
      return Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PantallaRegistro()),
      );
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaInicioSesion(
          volverAlOrigen: true,
          mensajeInfo:
              'Inicia sesión o regístrate para ver los horarios disponibles y confirmar tu reserva.',
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
    } else if (accion == 'login' || accion == 'registro') {
      final ok = await _autenticarDesdeInvitado(accion);
      if (!mounted || ok != true || !Sesion.activa) return;
      ref.invalidate(barberosProvider);
      if (Sesion.rolId != 3) {
        irAInicioPorRol(context);
      } else {
        setState(() {});
        _revisarConfirmaciones();
      }
    } else if (accion == 'logout') {
      await confirmarYCerrarSesion(context);
    }
  }

  void _mostrarMenu() {
    mostrarMenuCuenta(
      context,
      onMisCitas: () => _abrirCuenta('mis-citas'),
      onPerfil: () => _abrirCuenta('perfil'),
      onLogin: () => _abrirCuenta('login'),
      onRegistro: () => _abrirCuenta('registro'),
      onLogout: () => _abrirCuenta('logout'),
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
      body: Column(
        children: [
          EncabezadoUsuario(
            linea1: 'Hola',
            linea2: '$nombre!',
            fotoPerfil: Sesion.fotoPerfil,
            redondearAbajo: false,
            onAvatarTap: _mostrarMenu,
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
              onPressed: _mostrarMenu,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colores.carmin,
              onRefresh: _recargarCatalogo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 4, bottom: 20),
                      decoration: const BoxDecoration(
                        color: Colores.azulOscuro,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EtiquetaSeccion('Servicios'),
                          const SizedBox(height: 14),
                          _bloqueServicios(servicios),
                        ],
                      ),
                    ),
                    if (!Sesion.activa) _bannerInvitado(),
                    if (_alertaConfirmacion) _bannerConfirmacion(),
                    const SizedBox(height: 22),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerInvitado() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_person_outlined, color: Colores.carmin, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Inicia sesión para reservar',
                  style: TextStyle(
                    color: Colores.azulOscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Para consultar horarios disponibles y confirmar tu cita, debes iniciar sesión o registrarte.',
            style: TextStyle(color: Colores.gris, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _abrirCuenta('login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _abrirCuenta('registro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colores.azulOscuro),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _bannerConfirmacion() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: InkWell(
      onTap: () => _abrirCuenta('mis-citas'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icon(Icons.timer_outlined, color: Colores.carmin, size: 24),
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
                    style: TextStyle(color: Color(0xFF991B1B), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colores.carmin),
          ],
        ),
      ),
    ),
  );

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
        ],
      ),
    );
  }
}
