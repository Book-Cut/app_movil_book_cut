import 'package:flutter/material.dart';

import '../components/calendario_mes.dart';
import '../components/encabezado_usuario.dart';
import '../components/etiqueta_seccion.dart';
import '../components/selector_horas.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../services/citas_service.dart';
import '../services/disponibilidad_service.dart';
import 'pantalla_inicio_sesion.dart';

DateTime _hoy() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class PantallaAgendar extends StatefulWidget {
  final Barbero barbero;
  final List<Servicio> servicios;

  const PantallaAgendar({
    super.key,
    required this.barbero,
    required this.servicios,
  });

  @override
  State<PantallaAgendar> createState() => _PantallaAgendarState();
}

class _PantallaAgendarState extends State<PantallaAgendar> {
  DateTime _fecha = _hoy();
  String? _hora;
  List<String>? _horas;
  bool _cargando = false;
  bool _reservando = false;
  bool _requiereSesion = false;
  String? _error;

  int get _duracion {
    final total = widget.servicios.fold<int>(0, (suma, s) => suma + s.duracion);
    return total < 1 ? 1 : total;
  }

  @override
  void initState() {
    super.initState();
    _cargarHoras();
  }

  Future<void> _cargarHoras() async {
    final fechaPedida = _fecha;
    setState(() {
      _cargando = true;
      _error = null;
      _requiereSesion = false;
      _hora = null;
      _horas = null;
    });
    try {
      final horas = await listarHorasDisponibles(
        barberoId: widget.barbero.id,
        fecha: fechaPedida,
        duracion: _duracion,
      );
      if (!mounted || fechaPedida != _fecha) return;
      setState(() {
        _horas = horas;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted || fechaPedida != _fecha) return;
      setState(() {
        _cargando = false;
        if (e.codigo == 401) {
          _requiereSesion = true;
        } else {
          _error = 'No se pudieron cargar los horarios.';
        }
      });
    } catch (_) {
      if (!mounted || fechaPedida != _fecha) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los horarios.';
      });
    }
  }

  Future<void> _iniciarSesion() async {
    final inicioCorrecto = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PantallaInicioSesion(volverAlOrigen: true),
      ),
    );
    if (inicioCorrecto == true && mounted) await _cargarHoras();
  }

  Future<void> _reservar() async {
    final hora = _hora;
    if (hora == null || _reservando) return;

    if (!Sesion.activa) {
      await _iniciarSesion();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Confirma tu cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barbero: ${widget.barbero.nombre}'),
            const SizedBox(height: 4),
            Text(
              'Servicios: ${widget.servicios.map((s) => s.nombre).join(', ')}',
            ),
            const SizedBox(height: 4),
            Text('Fecha: ${fechaLarga(_fecha)}'),
            const SizedBox(height: 4),
            Text('Hora: ${horaBonita(hora)}'),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contexto, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.carmin,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar reserva'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _reservando = true);
    try {
      await crearCita(
        barbero: widget.barbero,
        servicios: widget.servicios,
        fecha: _fecha,
        hora: hora,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Cita reservada'),
          content: const Text('Tu cita se guardó correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contexto),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      if (mounted) await _cargarHoras();
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.codigo == 401) {
        setState(() {
          _requiereSesion = true;
          _horas = null;
          _hora = null;
        });
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.mensaje)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la cita.')),
      );
    } finally {
      if (mounted) setState(() => _reservando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoUsuario(
              linea1: 'Reserva con',
              linea2: widget.barbero.nombre,
              onAtras: () => Navigator.pop(context),
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EtiquetaSeccion('Elige tu fecha'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CalendarioMes(
                      seleccionada: _fecha,
                      onSeleccionar: (f) {
                        setState(() => _fecha = f);
                        _cargarHoras();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const EtiquetaSeccion('Elige tu hora', clara: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                '${widget.servicios.map((s) => s.nombre).join(', ')} · $_duracion min',
                style: const TextStyle(color: Colores.gris, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _bloqueHoras(),
              ),
            ),
            Center(
              child: SizedBox(
                width: 240,
                height: 50,
                child: ElevatedButton(
                  onPressed: _hora == null || _reservando ? null : _reservar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE4E4E7),
                    disabledForegroundColor: Colores.gris,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _reservando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reservar ahora'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _bloqueHoras() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: Colores.carmin),
        ),
      );
    }
    if (_requiereSesion) {
      return Column(
        children: [
          const Text(
            'Inicia sesión para ver los horarios disponibles.',
            style: TextStyle(color: Colores.gris),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _iniciarSesion,
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión'),
          ),
        ],
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: Colores.gris)),
          TextButton(
            onPressed: _cargarHoras,
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colores.carmin),
            ),
          ),
        ],
      );
    }
    final horas = _horas ?? [];
    if (horas.isEmpty) {
      return const Text(
        'No hay horarios libres este día. Prueba con otra fecha.',
        style: TextStyle(color: Colores.gris),
      );
    }
    return SelectorHoras(
      horas: horas,
      seleccionada: _hora,
      onSeleccionar: (h) => setState(() => _hora = h),
    );
  }
}
