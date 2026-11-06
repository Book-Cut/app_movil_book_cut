import 'package:flutter/material.dart';

import '../components/encabezado_usuario.dart';
import '../components/etiqueta_seccion.dart';
import '../components/servicio_icono.dart';
import '../components/tarjeta_barbero.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../services/barberos_service.dart';
import '../services/autenticacion_service.dart';
import '../services/servicios_service.dart';
import 'pantalla_agendar.dart';
import 'pantalla_bienvenida.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_perfil.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  List<Servicio>? _servicios;
  List<Barbero>? _barberos;
  String? _errorServicios;
  String? _errorBarberos;
  final Set<int> _elegidos = {};
  bool _verTodos = false;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
    _cargarBarberos();
  }

  Future<void> _cargarServicios() async {
    try {
      final datos = await listarServicios();
      if (!mounted) return;
      setState(() => _servicios = datos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorServicios = 'No se pudieron cargar los servicios.');
    }
  }

  Future<void> _cargarBarberos() async {
    try {
      final datos = await listarBarberos();
      if (!mounted) return;
      setState(() => _barberos = datos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorBarberos = 'No se pudieron cargar los barberos.');
    }
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

  void _elegirBarbero(Barbero barbero) {
    final seleccion = (_servicios ?? [])
        .where((s) => _elegidos.contains(s.id))
        .toList();
    if (seleccion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un servicio')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaAgendar(barbero: barbero, servicios: seleccion),
      ),
    );
  }

  void _abrirCuenta(String accion) {
    if (accion == 'perfil') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaPerfil()),
      );
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
              accion: PopupMenuButton<String>(
                tooltip: 'Cuenta',
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _abrirCuenta,
                itemBuilder: (_) => [
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
                  _bloqueServicios(),
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
              child: _bloqueBarberos(),
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

  Widget _bloqueServicios() {
    if (_errorServicios != null) {
      return _mensajeServicios(
        _errorServicios!,
        accion: TextButton(
          onPressed: () {
            setState(() => _errorServicios = null);
            _cargarServicios();
          },
          child: const Text(
            'Reintentar',
            style: TextStyle(color: Colores.rosa),
          ),
        ),
      );
    }
    final servicios = _servicios;
    if (servicios == null) return _mensajeServicios('Cargando servicios...');
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
          final s = servicios[i];
          return ServicioIcono(
            servicio: s,
            seleccionado: _elegidos.contains(s.id),
            onTap: () => _alternar(s.id),
          );
        },
      ),
    );
  }

  Widget _bloqueBarberos() {
    if (_errorBarberos != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _errorBarberos!,
              style: const TextStyle(color: Colores.gris),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _errorBarberos = null);
              _cargarBarberos();
            },
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colores.carmin),
            ),
          ),
        ],
      );
    }
    final todos = _barberos;
    if (todos == null) {
      return const Text(
        'Cargando barberos...',
        style: TextStyle(color: Colores.gris),
      );
    }
    if (todos.isEmpty) {
      return const Text(
        'No hay barberos disponibles.',
        style: TextStyle(color: Colores.gris),
      );
    }

    final visibles = _verTodos ? todos : todos.take(3).toList();
    return Column(
      children: [
        ...visibles.map(
          (b) => TarjetaBarbero(barbero: b, onTap: () => _elegirBarbero(b)),
        ),
        if (todos.length > 3)
          TextButton.icon(
            onPressed: () => setState(() => _verTodos = !_verTodos),
            icon: Icon(
              _verTodos ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            label: Text(_verTodos ? 'Ver menos' : 'Ver más'),
            style: TextButton.styleFrom(foregroundColor: Colores.azulOscuro),
          ),
      ],
    );
  }
}
