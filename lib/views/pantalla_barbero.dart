import 'package:flutter/material.dart';

import '../components/dialogos_cuenta.dart';
import '../components/encabezado_usuario.dart';
import '../components/esqueleto.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../core/sesion.dart';
import '../models/cita.dart';
import '../models/valoracion.dart';
import '../services/citas_service.dart';
import '../services/valoraciones_service.dart';
import 'pantalla_perfil.dart';

enum _FiltroCitasBarbero { todas, activas, porCobrar, finalizadas, canceladas }

class PantallaBarbero extends StatefulWidget {
  const PantallaBarbero({super.key});

  @override
  State<PantallaBarbero> createState() => _PantallaBarberoState();
}

class _PantallaBarberoState extends State<PantallaBarbero> {
  int _tab = 0; // 0: Mis citas, 1: Valoraciones
  _FiltroCitasBarbero _filtro = _FiltroCitasBarbero.todas;

  List<Cita>? _citas;
  bool _cargandoCitas = true;
  String? _errorCitas;

  List<ValoracionRecibida>? _valoraciones;
  ResumenValoraciones _resumen = const ResumenValoraciones(total: 0);
  bool _cargandoValoraciones = true;
  String? _errorValoraciones;

  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    Sesion.cambios.addListener(_alCambiarSesion);
    _cargarTodo();
  }

  @override
  void dispose() {
    Sesion.cambios.removeListener(_alCambiarSesion);
    super.dispose();
  }

  void _alCambiarSesion() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarTodo() async {
    await Future.wait([_cargarCitas(), _cargarValoraciones()]);
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _cargandoCitas = true;
      _errorCitas = null;
    });
    try {
      final citas = await listarCitas();
      if (!mounted) return;
      setState(() => _citas = citas);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorCitas = e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorCitas = 'No se pudieron cargar tus citas.');
    } finally {
      if (mounted) setState(() => _cargandoCitas = false);
    }
  }

  Future<void> _cargarValoraciones() async {
    setState(() {
      _cargandoValoraciones = true;
      _errorValoraciones = null;
    });
    try {
      final res = await listarValoracionesRecibidas();
      if (!mounted) return;
      setState(() {
        _valoraciones = res.valoraciones;
        _resumen = res.resumen;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorValoraciones = e.mensaje);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorValoraciones = 'No se pudieron cargar tus valoraciones.',
      );
    } finally {
      if (mounted) setState(() => _cargandoValoraciones = false);
    }
  }

  List<Cita> get _citasOrdenadas {
    final lista = List<Cita>.of(_citas ?? const <Cita>[]);
    int prioridad(Cita c) {
      if (c.estado == 'Confirmado' || c.estado == 'Pendiente') return 0;
      if (c.estado == 'Finalizado' && c.estadoPago == 'Pendiente') return 1;
      if (c.estado == 'Finalizado') return 2;
      return 3;
    }

    lista.sort((a, b) {
      final pa = prioridad(a);
      final pb = prioridad(b);
      if (pa != pb) return pa.compareTo(pb);
      if (pa == 0) return a.inicio.compareTo(b.inicio);
      return b.inicio.compareTo(a.inicio);
    });
    return lista;
  }

  List<Cita> get _citasFiltradas {
    final todas = _citasOrdenadas;
    return switch (_filtro) {
      _FiltroCitasBarbero.todas => todas,
      _FiltroCitasBarbero.activas =>
        todas
            .where((c) => c.estado == 'Confirmado' || c.estado == 'Pendiente')
            .toList(),
      _FiltroCitasBarbero.porCobrar =>
        todas
            .where(
              (c) => c.estado == 'Finalizado' && c.estadoPago == 'Pendiente',
            )
            .toList(),
      _FiltroCitasBarbero.finalizadas =>
        todas.where((c) => c.estado == 'Finalizado').toList(),
      _FiltroCitasBarbero.canceladas =>
        todas.where((c) => c.estado == 'Cancelado').toList(),
    };
  }

  int get _pendientesAccion {
    final todas = _citas ?? const <Cita>[];
    return todas
        .where(
          (c) =>
              c.estado == 'Confirmado' ||
              c.estado == 'Pendiente' ||
              (c.estado == 'Finalizado' && c.estadoPago == 'Pendiente'),
        )
        .length;
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

  Future<void> _finalizarCita(Cita cita) async {
    final confirmar = await showModalBottomSheet<bool>(
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
                _tiradorSheet(),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Color(0xFF166534),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Finalizar esta cita?',
                  style: TextStyle(
                    color: Colores.azulOscuro,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La cita con ${cita.clienteNombre ?? 'el cliente'} se marcará como finalizada y quedará lista para registrar el pago.',
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
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.azulOscuro,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar finalización',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colores.azulOscuro,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);
    try {
      await finalizarCita(cita.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cita finalizada. Ya puedes registrar el pago.',
          ),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      await _cargarCitas();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo finalizar la cita.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _registrarPago(Cita cita) async {
    const metodos = ['Efectivo', 'Nequi', 'Tarjeta', 'Transferencia'];
    var metodoSeleccionado = 'Efectivo';

    final confirmado = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tiradorSheet(),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Colores.carmin,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registrar pago',
                              style: TextStyle(
                                color: Colores.azulOscuro,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              cita.clienteNombre ?? 'Cliente',
                              style: const TextStyle(
                                color: Colores.gris,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        precioBonito(cita.total),
                        style: const TextStyle(
                          color: Colores.azulOscuro,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'MÉTODO DE PAGO',
                    style: TextStyle(
                      color: Colores.gris,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metodos.map((m) {
                      final elegido = metodoSeleccionado == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: elegido,
                        selectedColor: Colores.azulOscuro,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: elegido ? Colors.white : Colores.azulOscuro,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: elegido
                              ? Colores.azulOscuro
                              : Colores.grisBorde,
                        ),
                        onSelected: (_) {
                          setModalState(() => metodoSeleccionado = m);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, metodoSeleccionado),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colores.carmin,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirmar pago',
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
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colores.azulOscuro,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Volver'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmado == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      await registrarPagoCita(cita.id, metodoPago: confirmado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pago registrado en $confirmado y factura generada.'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      await _cargarCitas();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar el pago.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelarCita(Cita cita) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final motivo = await showModalBottomSheet<String>(
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
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tiradorSheet(),
                  const Text(
                    'Cancelar cita',
                    style: TextStyle(
                      color: Colores.azulOscuro,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Se notificará a ${cita.clienteNombre ?? 'tu cliente'} con el motivo que indiques.',
                    style: const TextStyle(color: Colores.gris, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: motivoController,
                    maxLength: 255,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Motivo de la cancelación',
                      hintText: 'Ej: Imprevisto de agenda, incapacidad...',
                      filled: true,
                      fillColor: Colores.fondo,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (valor) => (valor ?? '').trim().isEmpty
                        ? 'Ingresa el motivo para avisar al cliente.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx, motivoController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar cita y avisar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colores.azulOscuro,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Volver'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    motivoController.dispose();
    if (motivo == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      final correoEnviado = await cancelarCitaBarbero(cita.id, motivo: motivo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            correoEnviado
                ? 'Cita cancelada. Se avisó al cliente por correo.'
                : 'Cita cancelada. Cliente avisado en la plataforma, pero el correo no pudo enviarse.',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      await _cargarCitas();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar la cita.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Widget _tiradorSheet() => Center(
    child: Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final nombre = Sesion.primerNombre.isNotEmpty
        ? Sesion.primerNombre
        : 'Barbero';

    return Scaffold(
      backgroundColor: Colores.fondo,
      body: Column(
        children: [
          EncabezadoUsuario(
            linea1: 'Panel de barbero',
            linea2: 'Hola, $nombre!',
            fotoPerfil: Sesion.fotoPerfil,
            onAvatarTap: _abrirMenu,
            accion: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Actualizar',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _cargarTodo,
                ),
                IconButton(
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
              ],
            ),
            hijo: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _botonTab(
                      indice: 0,
                      icono: Icons.calendar_today_rounded,
                      etiqueta: _pendientesAccion > 0
                          ? 'Mis citas ($_pendientesAccion)'
                          : 'Mis citas',
                    ),
                    _botonTab(
                      indice: 1,
                      icono: Icons.star_rounded,
                      etiqueta: _resumen.promedio != null
                          ? 'Valoraciones (${_resumen.promedio!.toStringAsFixed(1)})'
                          : 'Valoraciones',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _tab == 0 ? _vistaCitas() : _vistaValoraciones(),
          ),
        ],
      ),
    );
  }

  Widget _botonTab({
    required int indice,
    required IconData icono,
    required String etiqueta,
  }) {
    final activo = _tab == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = indice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: activo ? Colores.carmin : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 16,
                color: activo ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activo ? Colors.white : Colors.white70,
                    fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaCitas() {
    final filtradas = _citasFiltradas;

    return RefreshIndicator(
      color: Colores.carmin,
      onRefresh: _cargarCitas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chipFiltro(_FiltroCitasBarbero.todas, 'Todas'),
                _chipFiltro(_FiltroCitasBarbero.activas, 'Activas'),
                _chipFiltro(_FiltroCitasBarbero.porCobrar, 'Por cobrar'),
                _chipFiltro(_FiltroCitasBarbero.finalizadas, 'Finalizadas'),
                _chipFiltro(_FiltroCitasBarbero.canceladas, 'Canceladas'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_cargandoCitas && _citas == null)
            const EfectoEsqueleto(
              child: Column(
                children: [
                  EsqueletoCita(),
                  EsqueletoCita(),
                  EsqueletoCita(),
                ],
              ),
            )
          else if (_errorCitas != null)
            _estadoError(_errorCitas!, _cargarCitas)
          else if (filtradas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                (_citas ?? []).isEmpty
                    ? 'No tienes citas asignadas actualmente.'
                    : 'No hay citas en esta categoría.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.gris),
              ),
            )
          else
            ...filtradas.map(_tarjetaCitaBarbero),
        ],
      ),
    );
  }

  Widget _chipFiltro(_FiltroCitasBarbero filtro, String texto) {
    final activo = _filtro == filtro;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        selectedColor: Colores.azulOscuro,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: activo ? Colors.white : Colores.azulOscuro,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: activo ? Colores.azulOscuro : Colores.grisBorde,
        ),
        onSelected: (_) => setState(() => _filtro = filtro),
      ),
    );
  }

  Widget _tarjetaCitaBarbero(Cita cita) {
    final puedeFinalizar =
        cita.estado == 'Confirmado' && !cita.afectadaPendiente;
    final puedeRegistrarPago =
        cita.estado == 'Finalizado' && cita.estadoPago == 'Pendiente';
    final puedeCancelar =
        cita.estado != 'Cancelado' &&
        cita.estado != 'Finalizado' &&
        !cita.afectadaPendiente;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colores.azulOscuro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fechaLarga(cita.inicio),
                      style: const TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${horaBonita(_horaStr(cita.inicio))}'
                      '${cita.fin.isAfter(cita.inicio) ? ' – ${horaBonita(_horaStr(cita.fin))}' : ''}',
                      style: const TextStyle(
                        color: Colores.gris,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _etiquetaEstado(cita.estado),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colores.fondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colores.grisBorde),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colores.azulOscuro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.clienteNombre ?? 'Cliente',
                        style: const TextStyle(
                          color: Colores.azulOscuro,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (cita.clienteTelefono != null)
                        Text(
                          cita.clienteTelefono!,
                          style: const TextStyle(
                            color: Colores.gris,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cita.estadoPago == 'Pagado'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pago ${cita.estadoPago}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cita.estadoPago == 'Pagado'
                          ? const Color(0xFF166534)
                          : Colores.gris,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (cita.servicios.isEmpty)
            const Text(
              'Sin servicios registrados',
              style: TextStyle(color: Colores.gris, fontSize: 13),
            )
          else
            ...cita.servicios.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.content_cut,
                      size: 16,
                      color: Colores.carmin,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.nombre,
                        style: const TextStyle(
                          color: Colores.azulOscuro,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${horaBonita(_horaStr(s.inicio))}'
                      '${s.duracion != null ? ' · ${s.duracion} min' : ''}',
                      style: const TextStyle(color: Colores.gris, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cita.factura != null && cita.factura!.metodoPago.isNotEmpty
                      ? 'Pagado con ${cita.factura!.metodoPago} · ${cita.factura!.numero}'
                      : 'Pago presencial',
                  style: const TextStyle(color: Colores.gris, fontSize: 12),
                ),
              ),
              Text(
                precioBonito(cita.total),
                style: const TextStyle(
                  color: Colores.azulOscuro,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (cita.afectadaPendiente) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Esperando respuesta del cliente',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (puedeFinalizar || puedeRegistrarPago || puedeCancelar) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (puedeCancelar)
                  OutlinedButton.icon(
                    onPressed: _procesando ? null : () => _cancelarCita(cita),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: const StadiumBorder(),
                    ),
                  ),
                if (puedeFinalizar)
                  ElevatedButton.icon(
                    onPressed: _procesando ? null : () => _finalizarCita(cita),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.azulOscuro,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                  ),
                if (puedeRegistrarPago)
                  ElevatedButton.icon(
                    onPressed: _procesando ? null : () => _registrarPago(cita),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Registrar pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.carmin,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _vistaValoraciones() {
    final lista = _valoraciones ?? const <ValoracionRecibida>[];

    return RefreshIndicator(
      color: Colores.carmin,
      onRefresh: _cargarValoraciones,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colores.dorado,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mis valoraciones',
                        style: TextStyle(
                          color: Colores.azulOscuro,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _resumen.promedio != null
                            ? '${_resumen.promedio!.toStringAsFixed(1)} / 5 (${_resumen.total} ${_resumen.total == 1 ? 'valoración' : 'valoraciones'})'
                            : 'Aún no tienes valoraciones',
                        style: const TextStyle(
                          color: Colores.gris,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_cargandoValoraciones && _valoraciones == null)
            const EfectoEsqueleto(
              child: Column(
                children: [EsqueletoCita(), EsqueletoCita()],
              ),
            )
          else if (_errorValoraciones != null)
            _estadoError(_errorValoraciones!, _cargarValoraciones)
          else if (lista.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Todavía no has recibido valoraciones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colores.gris),
              ),
            )
          else
            ...lista.map(_tarjetaValoracion),
        ],
      ),
    );
  }

  Widget _tarjetaValoracion(ValoracionRecibida v) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.fecha,
                      style: const TextStyle(color: Colores.gris, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.cliente,
                      style: const TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.servicios,
                      style: const TextStyle(color: Colores.gris, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colores.azulOscuro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colores.dorado,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${v.puntuacion} / 5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            v.comentario ?? 'Sin comentario escrito',
            style: TextStyle(
              color: v.comentario != null ? Colores.azulOscuro : Colores.gris,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoError(String mensaje, Future<void> Function() reintentar) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colores.gris),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colores.gris),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );

  Widget _etiquetaEstado(String estado) {
    final (fondo, texto) = switch (estado) {
      'Confirmado' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'Pendiente' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'Cancelado' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'Finalizado' => (const Color(0xFFE4E4E7), const Color(0xFF3F3F46)),
      _ => (const Color(0xFFE4E4E7), Colores.gris),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: texto,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _horaStr(DateTime fecha) =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
}
