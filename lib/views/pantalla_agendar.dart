import 'package:flutter/material.dart';

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
import 'pantalla_inicio_sesion.dart';

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
    _cargarHoras();
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
            final horas = await listarHorasDisponibles(
              barberoId: widget.barbero!.id,
              fecha: fechaPedida,
              duracion: duracion,
            );
            return {widget.barbero!.id: horas};
          }
          final horarios = await Future.wait(
            widget.barberos.map(
              (barbero) => listarHorasDisponibles(
                barberoId: barbero.id,
                fecha: fechaPedida,
                duracion: duracion,
              ),
            ),
          );
          return {
            for (var i = 0; i < widget.barberos.length; i++)
              widget.barberos[i].id: horarios[i],
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
        if (!(horariosPorBarbero[barbero.id]?.contains(hora) ?? false)) {
          return false;
        }
        return _serviciosSeleccionados.asMap().entries.every((entrada) {
          if (entrada.key == indice || entrada.value == null) return true;
          final otroServicio = entrada.value!;
          final otraHora = _horasSeleccionadasPorIndice[entrada.key];
          return otraHora == null ||
              (_horasPorServicioBarbero[otroServicio.id]?[barbero.id]?.contains(
                    otraHora,
                  ) ??
                  false);
        });
      });
    }).toList()..sort();
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
    if (_servicios.isEmpty ||
        _serviciosSeleccionados.any((servicio) => servicio == null) ||
        _horasSeleccionadasPorIndice.length != _servicios.length ||
        _reservando ||
        !_formKey.currentState!.validate()) {
      return;
    }

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
            Text(
              'Barbero: ${widget.barbero?.nombre ?? 'Cualquiera disponible'}',
            ),
            const SizedBox(height: 4),
            Text(
              'Servicios:\n${_serviciosSeleccionados.asMap().entries.map((entrada) => '- ${entrada.value!.nombre}: ${horaBonita(_horasSeleccionadasPorIndice[entrada.key]!)}').join('\n')}',
            ),
            const SizedBox(height: 4),
            Text('Fecha: ${fechaLarga(_fecha)}'),
            const SizedBox(height: 4),
            Text('Total: \$${_total.toStringAsFixed(0)}'),
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
      body: _mostrarServicios ? _vistaServicios() : _vistaCalendario(),
      bottomNavigationBar: _barraAccion(),
    );
  }

  Widget _vistaCalendario() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EncabezadoUsuario(
          linea1: 'Reserva con',
          linea2: widget.barbero?.nombre ?? 'Cualquier barbero',
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
  );

  Widget _vistaServicios() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EncabezadoUsuario(
          linea1: 'Completa tu cita',
          linea2: 'Servicios y horarios',
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
                Text(
                  '${fechaLarga(_fecha)} · ${widget.barbero?.nombre ?? 'Cualquier barbero'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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
                _resumenTotal(),
                _datosConfirmacion(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
              '\$${_total.toStringAsFixed(0)}',
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
                ? (puedeReservar ? _reservar : null)
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
                        ? 'Confirmar reserva · \$${_total.toStringAsFixed(0)}'
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
                      '${item.nombre} · \$${item.precio.toStringAsFixed(0)}',
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
              '${servicio.duracion} min · \$${servicio.precio.toStringAsFixed(0)}',
              style: const TextStyle(color: Colores.gris, fontSize: 13),
            ),
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
      ),
    );
  }

  Widget _selectorHoras(int indice, Servicio servicio) {
    if (_requiereSesion) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _iniciarSesion,
          icon: const Icon(Icons.login),
          label: const Text('Iniciar sesión para ver horarios'),
        ),
      );
    }
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
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
            BloqueEsqueleto(ancho: 84, alto: 38, radio: 10),
          ],
        ),
      );
    }
    final horas = _horasDisponiblesPara(indice, servicio);
    if (horas.isEmpty) {
      return const Text(
        'No hay horarios compatibles para este servicio.',
        style: TextStyle(color: Colores.gris),
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
          '\$${_total.toStringAsFixed(0)}',
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
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Teléfono / WhatsApp',
          prefixIcon: const Icon(Icons.phone_outlined),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (valor) => (valor ?? '').trim().isEmpty
            ? 'Ingresa un teléfono de contacto.'
            : null,
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
