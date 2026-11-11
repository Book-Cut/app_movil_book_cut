import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/calendario_mes.dart';
import '../components/encabezado_usuario.dart';
import '../components/etiqueta_seccion.dart';
import '../components/esqueleto.dart';
import '../components/selector_horas.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../core/sesion.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../services/citas_service.dart';
import '../services/disponibilidad_service.dart';
import 'navegacion_rol.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_registro.dart';

DateTime _hoy() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class PantallaAgendar extends StatefulWidget {
  final Barbero? barbero;
  final List<Barbero> barberos;
  final List<Servicio> servicios;
  final List<Servicio> catalogoServicios;

  const PantallaAgendar({
    super.key,
    required this.barbero,
    required this.barberos,
    required this.servicios,
    required this.catalogoServicios,
  });

  @override
  State<PantallaAgendar> createState() => _PantallaAgendarState();
}

class _PantallaAgendarState extends State<PantallaAgendar> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  DateTime _fecha = _hoy();
  late final List<Servicio?> _serviciosSeleccionados;
  late final List<int> _idsLineasServicio;
  int _proximoIdLineaServicio = 0;
  final Map<int, Map<int, List<String>>> _horasPorServicioBarbero = {};
  final Map<int, String> _horasSeleccionadasPorIndice = {};
  bool _cargando = false;
  bool _reservando = false;
  bool _requiereSesion = false;
  bool _mostrarServicios = false;
  String? _error;
  int _solicitudDisponibilidad = 0;

  List<Servicio> get _servicios =>
      _serviciosSeleccionados.whereType<Servicio>().toList();

  double get _total =>
      _servicios.fold<double>(0, (total, servicio) => total + servicio.precio);

  @override
  void initState() {
    super.initState();
    _serviciosSeleccionados = List<Servicio?>.of(widget.servicios);
    _idsLineasServicio = List<int>.generate(
      widget.servicios.length,
      (indice) => indice,
    );
    _proximoIdLineaServicio = _idsLineasServicio.length;
    _nombreController.text = Sesion.nombre ?? '';
    _telefonoController.text = Sesion.telefono ?? '';
    if (!Sesion.activa) {
      _requiereSesion = true;
    } else {
      _cargarHoras();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _agregarServicio() {
    setState(() {
      _serviciosSeleccionados.add(null);
      _idsLineasServicio.add(_proximoIdLineaServicio++);
    });
  }

  void _cambiarServicio(int indice, int? id) {
    if (id == null) return;
    Servicio? nuevo;
    for (final servicio in widget.catalogoServicios) {
      if (servicio.id == id) {
        nuevo = servicio;
        break;
      }
    }
    if (nuevo == null) return;
    setState(() {
      _serviciosSeleccionados[indice] = nuevo;
      _horasPorServicioBarbero.clear();
      _horasSeleccionadasPorIndice.clear();
    });
    _cargarHoras();
  }

  void _eliminarServicio(int indice) {
    if (_serviciosSeleccionados.length <= 1) return;
    setState(() {
      _serviciosSeleccionados.removeAt(indice);
      _idsLineasServicio.removeAt(indice);
      _horasPorServicioBarbero.clear();
      _horasSeleccionadasPorIndice.clear();
    });
    _cargarHoras();
  }

  Future<void> _cargarHoras() async {
    if (!Sesion.activa) {
      setState(() {
        _cargando = false;
        _requiereSesion = true;
        _horasSeleccionadasPorIndice.clear();
        _horasPorServicioBarbero.clear();
      });
      return;
    }

    final fechaPedida = _fecha;
    final solicitud = ++_solicitudDisponibilidad;
    setState(() {
      _cargando = true;
      _error = null;
      _requiereSesion = false;
      _horasSeleccionadasPorIndice.clear();
      _horasPorServicioBarbero.clear();
    });
    try {
      final servicios = _servicios;
      final respuestas = await Future.wait(
        servicios.map((servicio) async {
          final duracion = servicio.duracion < 1 ? 1 : servicio.duracion;
          if (widget.barbero != null) {
            if (!widget.barbero!.ofreceServicio(servicio)) {
              return <int, List<String>>{widget.barbero!.id: const <String>[]};
            }
            final horas = await listarHorasDisponibles(
              barberoId: widget.barbero!.id,
              fecha: fechaPedida,
              duracion: duracion,
              servicioId: servicio.id,
            );
            return {widget.barbero!.id: horas};
          }

          final candidatos = widget.barberos
              .where((b) => b.ofreceServicio(servicio))
              .toList();
          if (candidatos.isEmpty) {
            return <int, List<String>>{};
          }
          final horarios = await Future.wait(
            candidatos.map(
              (barbero) => listarHorasDisponibles(
                barberoId: barbero.id,
                fecha: fechaPedida,
                duracion: duracion,
                servicioId: servicio.id,
              ),
            ),
          );
          return {
            for (var i = 0; i < candidatos.length; i++)
              candidatos[i].id: horarios[i],
          };
        }),
      );
      if (!mounted ||
          solicitud != _solicitudDisponibilidad ||
          fechaPedida != _fecha) {
        return;
      }
      setState(() {
        for (var i = 0; i < servicios.length; i++) {
          _horasPorServicioBarbero[servicios[i].id] = respuestas[i];
        }
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted ||
          solicitud != _solicitudDisponibilidad ||
          fechaPedida != _fecha) {
        return;
      }
      setState(() {
        _cargando = false;
        if (e.codigo == 401) {
          _requiereSesion = true;
        } else {
          _error = 'No se pudieron cargar los horarios de los servicios.';
        }
      });
    } catch (_) {
      if (!mounted ||
          solicitud != _solicitudDisponibilidad ||
          fechaPedida != _fecha) {
        return;
      }
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los horarios de los servicios.';
      });
    }
  }

  int? _minutosDesdeMedianoche(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return null;
    final horas = int.tryParse(partes[0]);
    final minutos = int.tryParse(partes[1]);
    if (horas == null ||
        minutos == null ||
        horas < 0 ||
        horas > 23 ||
        minutos < 0 ||
        minutos > 59) {
      return null;
    }
    return horas * 60 + minutos;
  }

  bool _seCruzan(
    String primeraHora,
    int primeraDuracion,
    String segundaHora,
    int segundaDuracion,
  ) {
    final inicioPrimero = _minutosDesdeMedianoche(primeraHora);
    final inicioSegundo = _minutosDesdeMedianoche(segundaHora);
    if (inicioPrimero == null || inicioSegundo == null) return true;
    final finPrimero =
        inicioPrimero + (primeraDuracion < 1 ? 1 : primeraDuracion);
    final finSegundo =
        inicioSegundo + (segundaDuracion < 1 ? 1 : segundaDuracion);
    return inicioPrimero < finSegundo && inicioSegundo < finPrimero;
  }

  List<String> _horasDisponiblesPara(int indice, Servicio servicio) {
    final horariosPorBarbero =
        _horasPorServicioBarbero[servicio.id] ?? const <int, List<String>>{};
    final candidatas = horariosPorBarbero.values
        .expand((horas) => horas)
        .toSet();
    return candidatas.where((hora) {
      if (!horaCompatibleConDuracion(hora, servicio.duracion)) {
        return false;
      }
      for (final entrada in _serviciosSeleccionados.asMap().entries) {
        if (entrada.key == indice || entrada.value == null) continue;
        final otroServicio = entrada.value!;
        final otraHora = _horasSeleccionadasPorIndice[entrada.key];
        if (otraHora != null &&
            _seCruzan(
              hora,
              servicio.duracion,
              otraHora,
              otroServicio.duracion,
            )) {
          return false;
        }
      }
      final barberosCandidatos = widget.barbero == null
          ? widget.barberos
          : [widget.barbero!];
      return barberosCandidatos.any((barbero) {
        if (!barbero.ofreceServicio(servicio)) return false;
        if (!(horariosPorBarbero[barbero.id]?.contains(hora) ?? false)) {
          return false;
        }
        return _serviciosSeleccionados.asMap().entries.every((entrada) {
          if (entrada.key == indice || entrada.value == null) return true;
          final otroServicio = entrada.value!;
          final otraHora = _horasSeleccionadasPorIndice[entrada.key];
          if (!barbero.ofreceServicio(otroServicio)) return false;
          return otraHora == null ||
              (_horasPorServicioBarbero[otroServicio.id]?[barbero.id]?.contains(
                    otraHora,
                  ) ??
                  false);
        });
      });
    }).toList()..sort();
  }

  Future<void> _autenticar({bool registro = false}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => registro
            ? const PantallaRegistro()
            : const PantallaInicioSesion(
                volverAlOrigen: true,
                mensajeInfo:
                    'Inicia sesión o regístrate para ver horarios disponibles y confirmar tu reserva.',
              ),
      ),
    );
    if (!mounted || ok != true || !Sesion.activa) return;
    if (Sesion.rolId != 3) {
      irAInicioPorRol(context);
      return;
    }
    if (_nombreController.text.trim().isEmpty) {
      _nombreController.text = Sesion.nombre ?? '';
    }
    if (_telefonoController.text.trim().isEmpty) {
      _telefonoController.text = Sesion.telefono ?? '';
    }
    await _cargarHoras();
  }

  Future<void> _reservar() async {
    if (!Sesion.activa) {
      await _autenticar();
      return;
    }

    if (_servicios.isEmpty ||
        _serviciosSeleccionados.any((servicio) => servicio == null) ||
        _horasSeleccionadasPorIndice.length != _servicios.length ||
        _reservando ||
        !_formKey.currentState!.validate()) {
      return;
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Colores.carmin,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirma tu cita',
                            style: TextStyle(
                              color: Colores.azulOscuro,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Revisa el resumen antes de agendar',
                            style: TextStyle(
                              color: Colores.gris,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colores.carmin,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Barbero: ${widget.barbero?.nombre ?? 'Cualquiera disponible'}',
                              style: const TextStyle(
                                color: Colores.azulOscuro,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colores.carmin,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fechaLarga(_fecha),
                              style: const TextStyle(
                                color: Colores.azulOscuro,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      const Text(
                        'Servicios seleccionados:',
                        style: TextStyle(
                          color: Colores.gris,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._serviciosSeleccionados.asMap().entries.map((entrada) {
                        final serv = entrada.value!;
                        final hora = _horasSeleccionadasPorIndice[entrada.key];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  serv.nombre,
                                  style: const TextStyle(
                                    color: Colores.azulOscuro,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (hora != null)
                                Text(
                                  horaBonita(hora),
                                  style: const TextStyle(
                                    color: Colores.gris,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar:',
                            style: TextStyle(
                              color: Colores.azulOscuro,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              precioBonito(_total),
                              style: const TextStyle(
                                color: Colores.carmin,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(contexto, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.carmin,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar reserva',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
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
                      'Volver a revisar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
    if (confirmar != true || !mounted) return;

    setState(() => _reservando = true);
    try {
      await crearCita(
        barbero: widget.barbero,
        servicios: _servicios,
        fecha: _fecha,
        horasPorServicio: List.generate(
          _serviciosSeleccionados.length,
          (indice) => _horasSeleccionadasPorIndice[indice],
        ),
        nombreCliente: _nombreController.text,
        telefonoCliente: _telefonoController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (contexto) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF16A34A),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Cita reservada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colores.azulOscuro,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu cita se guardó correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colores.gris,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(contexto),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.carmin,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.codigo == 401) {
        setState(() {
          _requiereSesion = true;
          _horasPorServicioBarbero.clear();
          _horasSeleccionadasPorIndice.clear();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.mensaje)),
      );
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
      body: _mostrarServicios ? _vistaServicios() : _vistaCalendario(),
      bottomNavigationBar: _barraAccion(),
    );
  }

  Widget _vistaCalendario() => Column(
    children: [
      EncabezadoUsuario(
        linea1: 'Reserva con',
        linea2: widget.barbero?.nombre ?? 'Cualquier barbero',
        fotoPerfil: widget.barbero?.fotoPerfil,
        redondearAbajo: false,
        onAtras: () => Navigator.pop(context),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 18),
                decoration: const BoxDecoration(
                  color: Colores.azulOscuro,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EtiquetaSeccion('Elige tu fecha'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CalendarioMes(
                        seleccionada: _fecha,
                        onSeleccionar: (fecha) {
                          setState(() => _fecha = fecha);
                          _cargarHoras();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: _resumenSeleccion(),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _vistaServicios() => Column(
    children: [
      EncabezadoUsuario(
        linea1: 'Completa tu cita',
        linea2: 'Servicios y horarios',
        fotoPerfil: widget.barbero?.fotoPerfil,
        onAtras: () => setState(() => _mostrarServicios = false),
        hijo: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${fechaLarga(_fecha)} · ${widget.barbero?.nombre ?? 'Cualquier barbero'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_requiereSesion) _tarjetaRequiereSesion(),
              const EtiquetaSeccion('Servicios de tu cita', clara: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...List.generate(
                        _serviciosSeleccionados.length,
                        (indice) => KeyedSubtree(
                          key: ValueKey(_idsLineasServicio[indice]),
                          child: _bloqueServicio(indice),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _agregarServicio,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar otro servicio'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colores.azulOscuro,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _resumenTotal(),
                      if (!_requiereSesion) _datosConfirmacion(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _tarjetaRequiereSesion() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
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
          const Text(
            'Inicia sesión o regístrate para ver horarios',
            style: TextStyle(
              color: Colores.azulOscuro,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Necesitas una cuenta activa para consultar horarios disponibles y confirmar tu cita.',
            style: TextStyle(color: Colores.gris, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _autenticar(registro: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Registrarse'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _autenticar(registro: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Iniciar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _resumenSeleccion() => Container(
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.content_cut, color: Colores.carmin, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_servicios.length} ${_servicios.length == 1 ? 'servicio seleccionado' : 'servicios seleccionados'}',
                style: const TextStyle(
                  color: Colores.azulOscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              precioBonito(_total),
              style: const TextStyle(
                color: Colores.azulOscuro,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _servicios.map((servicio) => servicio.nombre).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colores.gris, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _barraAccion() {
    final puedeContinuar =
        _servicios.isNotEmpty &&
        !_serviciosSeleccionados.any((servicio) => servicio == null);
    final puedeReservar =
        !_requiereSesion &&
        puedeContinuar &&
        _horasSeleccionadasPorIndice.length == _servicios.length &&
        !_reservando &&
        !_cargando;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _mostrarServicios
                ? (_requiereSesion
                      ? () => _autenticar(registro: true)
                      : (puedeReservar ? _reservar : null))
                : (puedeContinuar
                      ? () => setState(() => _mostrarServicios = true)
                      : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.carmin,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE4E4E7),
              disabledForegroundColor: Colores.gris,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
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
                : Text(
                    _mostrarServicios
                        ? (_requiereSesion
                              ? 'Regístrate para reservar'
                              : 'Confirmar reserva · ${precioBonito(_total)}')
                        : 'Elegir horarios y servicios',
                  ),
          ),
        ),
      ),
    );
  }

  Widget _bloqueServicio(int indice) {
    final servicio = _serviciosSeleccionados[indice];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Servicio ${indice + 1}',
                  style: const TextStyle(
                    color: Colores.gris,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (_serviciosSeleccionados.length > 1)
                TextButton(
                  onPressed: () => _eliminarServicio(indice),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colores.carmin),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: servicio?.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Servicio',
              filled: true,
              fillColor: Colores.fondo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            hint: const Text('Selecciona un servicio'),
            items: widget.catalogoServicios
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.nombre} · ${precioBonito(item.precio)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _cargando ? null : (id) => _cambiarServicio(indice, id),
            validator: (id) => id == null ? 'Selecciona un servicio.' : null,
          ),
          if (servicio != null) ...[
            const SizedBox(height: 8),
            Text(
              '${servicio.duracion} min · ${precioBonito(servicio.precio)}',
              style: const TextStyle(color: Colores.gris, fontSize: 13),
            ),
            if (!_requiereSesion) ...[
              const SizedBox(height: 14),
              const Text(
                'Hora disponible',
                style: TextStyle(
                  color: Colores.gris,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              _selectorHoras(indice, servicio),
            ],
          ],
        ],
      ),
    );
  }

  Widget _selectorHoras(int indice, Servicio servicio) {
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    if (_cargando) {
      return const EfectoEsqueleto(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
          ],
        ),
      );
    }
    final horas = _horasDisponiblesPara(indice, servicio);
    if (horas.isEmpty) {
      final noOfrece =
          widget.barbero != null && !widget.barbero!.ofreceServicio(servicio);
      return Text(
        noOfrece
            ? '${widget.barbero!.nombre} no ofrece este servicio.'
            : 'No hay horarios compatibles para este servicio en la fecha seleccionada.',
        style: const TextStyle(color: Colores.gris),
      );
    }
    return SelectorHoras(
      horas: horas,
      seleccionada: _horasSeleccionadasPorIndice[indice],
      onSeleccionar: (hora) {
        setState(() => _horasSeleccionadasPorIndice[indice] = hora);
      },
    );
  }

  Widget _resumenTotal() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F1F3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'TOTAL (${_servicios.length} ${_servicios.length == 1 ? 'SERVICIO' : 'SERVICIOS'})',
            style: const TextStyle(
              color: Colores.gris,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          precioBonito(_total),
          style: const TextStyle(
            color: Colores.azulOscuro,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _datosConfirmacion() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Datos de confirmación',
          style: TextStyle(
            color: Colores.azulOscuro,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _nombreController,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Nombre completo',
          prefixIcon: const Icon(Icons.person_outline),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (valor) =>
            (valor ?? '').trim().isEmpty ? 'Ingresa tu nombre completo.' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _telefonoController,
        keyboardType: TextInputType.number,
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: 'Teléfono / WhatsApp',
          prefixIcon: const Icon(Icons.phone_outlined),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (valor) {
          final telefono = (valor ?? '').trim();
          if (telefono.isEmpty) {
            return 'Ingresa un teléfono de contacto.';
          }
          if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
            return 'El teléfono debe tener 10 dígitos.';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'El pago se realiza en la barbería al finalizar la cita.',
          style: TextStyle(color: Colores.gris, fontSize: 12),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
