import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/encabezado_usuario.dart';
import '../components/etiqueta_seccion.dart';
import '../components/esqueleto.dart';
import '../components/servicio_icono.dart';
import '../components/tarjeta_barbero.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../providers/catalogo_providers.dart';
import '../services/autenticacion_service.dart';
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
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
              onAvatarTap: Sesion.activa ? () => _abrirCuenta('perfil') : null,
              accion: PopupMenuButton<String>(
                tooltip: 'Cuenta',
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _abrirCuenta,
                itemBuilder: (_) => [
                  if (Sesion.activa && Sesion.rolId == 3)
                    const PopupMenuItem(
                      value: 'mis-citas',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.event_note_outlined),
                        title: Text('Mis citas'),
                      ),
                    ),
                  if (Sesion.activa)
                    const PopupMenuItem(
                      value: 'perfil',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person_outline),
                        title: Text('Mi perfil'),
                      ),
                    ),
                  if (Sesion.activa)
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.logout),
                        title: Text('Cerrar sesión'),
                      ),
                    ),
                  if (!Sesion.activa)
                    const PopupMenuItem(
                      value: 'login',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.login),
                        title: Text('Iniciar sesión'),
                      ),
                    ),
                ],
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
        child: SizedBox(
          height: 104,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EsqueletoServicio(),
              _EsqueletoServicio(),
              _EsqueletoServicio(),
              _EsqueletoServicio(),
            ],
          ),
        ),
      ),
      error: (_, _) => _mensajeServicios(
        'No se pudieron cargar los servicios.',
        accion: TextButton(
          onPressed: () => ref.invalidate(serviciosProvider),
          child: const Text(
            'Reintentar',
            style: TextStyle(color: Colores.rosa),
          ),
        ),
      ),
      data: (servicios) {
        if (servicios.isEmpty) {
          return _mensajeServicios('No hay servicios disponibles.');
        }
        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: servicios.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final servicio = servicios[i];
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
      error: (_, _) => Row(
        children: [
          const Expanded(
            child: Text(
              'No se pudieron cargar los barberos.',
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
                            cargandoServicios ? 'Cargando servicios...' : 'No se pudieron cargar los servicios. Intenta de nuevo.',
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
