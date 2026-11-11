import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../components/dialogos_cuenta.dart';
import '../components/esqueleto.dart';
import '../components/selector_hora_sheet.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/fechas.dart';
import '../core/sesion.dart';
import '../models/perfil.dart';
import '../models/servicio.dart';
import '../services/perfil_service.dart';
import '../services/servicios_service.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  static const _abreviaturasDias = {
    'Lunes': 'Lun',
    'Martes': 'Mar',
    'Miércoles': 'Mié',
    'Jueves': 'Jue',
    'Viernes': 'Vie',
    'Sábado': 'Sáb',
    'Domingo': 'Dom',
  };

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenhaController = TextEditingController();
  final _confirmarContrasenhaController = TextEditingController();
  final _selectorImagen = ImagePicker();
  Perfil? _perfil;
  List<Servicio> _serviciosCatalogo = [];
  List<int> _servicioIdsSeleccionados = [];
  Map<String, HorarioPerfil> _horariosBarberia = horariosBarberiaPorDefecto;
  List<HorarioPerfil> _horarios = [];
  bool _horariosAjustados = false;
  Uint8List? _fotoSeleccionada;
  String? _nombreFotoSeleccionada;
  String? _tipoMimeFoto;
  String? _error;
  String? _exito;
  bool _cargando = true;
  bool _guardando = false;
  bool _guardandoFoto = false;
  bool _mostrarContrasenha = false;

  bool get _esBarbero => Sesion.rolId == 2;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenhaController.dispose();
    _confirmarContrasenhaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
      _horariosAjustados = false;
    });
    try {
      final futuroPerfil = obtenerPerfil();
      final futuroServicios = _esBarbero
          ? listarServicios()
          : Future.value(const <Servicio>[]);
      final futuroBarberia = _esBarbero
          ? listarHorariosBarberia().catchError(
              (_) => const <String, HorarioPerfil>{},
            )
          : Future.value(const <String, HorarioPerfil>{});
      final perfil = await futuroPerfil;
      final servicios = await futuroServicios;
      final barberiaServidor = await futuroBarberia;
      if (!mounted) return;
      _perfil = perfil;
      _serviciosCatalogo = servicios;
      _nombreController.text = perfil.nombre;
      _correoController.text = perfil.correo;
      _telefonoController.text = perfil.telefono;
      _servicioIdsSeleccionados = List<int>.of(perfil.servicioIds);
      _horariosBarberia = barberiaServidor.isNotEmpty
          ? barberiaServidor
          : horariosBarberiaPorDefecto;

      final reconciliacion = reconciliarHorariosConBarberia(
        perfil.horarios,
        _horariosBarberia,
      );
      _horarios = reconciliacion.horarios;

      if (_esBarbero && barberiaServidor.isNotEmpty && reconciliacion.ajustado) {
        try {
          final actualizado = await actualizarPerfil(
            nombre: perfil.nombre,
            correo: perfil.correo,
            telefono: perfil.telefono,
            servicioIds: perfil.servicioIds,
            horarios: reconciliacion.horarios,
          );
          if (!mounted) return;
          _perfil = actualizado;
          _horarios = reconciliarHorariosConBarberia(
            actualizado.horarios,
            _horariosBarberia,
          ).horarios;
          _exito =
              'Tus horarios se actualizaron automáticamente al horario vigente de la barbería.';
        } catch (_) {
          _horariosAjustados = true;
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar el perfil.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final horariosAcomodados = _esBarbero
        ? reconciliarHorariosConBarberia(_horarios, _horariosBarberia).horarios
        : _horarios;
    if (_esBarbero &&
        horariosAcomodados.any(
          (horario) => horario.horainicio.compareTo(horario.horafin) >= 0,
        )) {
      setState(() {
        _error =
            'La hora de fin debe ser posterior a la hora de inicio en cada día.';
        _exito = null;
      });
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
      _exito = null;
    });
    try {
      final perfil = await actualizarPerfil(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        contrasenha: _contrasenhaController.text,
        servicioIds: _esBarbero ? _servicioIdsSeleccionados : null,
        horarios: _esBarbero ? horariosAcomodados : null,
      );
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _servicioIdsSeleccionados = List<int>.of(perfil.servicioIds);
        _horarios = reconciliarHorariosConBarberia(
          perfil.horarios,
          _horariosBarberia,
        ).horarios;
        _horariosAjustados = false;
        _contrasenhaController.clear();
        _confirmarContrasenhaController.clear();
        _exito = 'Los cambios se guardaron correctamente.';
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron guardar los cambios.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final imagen = await _selectorImagen.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );
      if (imagen == null || !mounted) return;

      final extension = imagen.name.split('.').last.toLowerCase();
      final tipoMime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (tipoMime == null) {
        setState(() {
          _error = 'La foto debe estar en formato JPG, PNG o WebP.';
          _exito = null;
        });
        return;
      }

      if (await imagen.length() > 5 * 1024 * 1024) {
        setState(() {
          _error = 'La foto no puede superar los 5 MB.';
          _exito = null;
        });
        return;
      }

      final bytes = await imagen.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoSeleccionada = bytes;
        _nombreFotoSeleccionada = imagen.name;
        _tipoMimeFoto = tipoMime;
        _error = null;
        _exito = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo seleccionar la foto.';
          _exito = null;
        });
      }
    }
  }

  Future<void> _subirFoto() async {
    final bytes = _fotoSeleccionada;
    final nombre = _nombreFotoSeleccionada;
    final tipoMime = _tipoMimeFoto;
    if (bytes == null || nombre == null || tipoMime == null) return;

    setState(() {
      _guardandoFoto = true;
      _error = null;
      _exito = null;
    });
    try {
      final perfil = await actualizarFotoPerfil(
        bytes: bytes,
        nombreArchivo: nombre,
        tipoMime: tipoMime,
      );
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _fotoSeleccionada = null;
        _nombreFotoSeleccionada = null;
        _tipoMimeFoto = null;
        _exito = 'Tu foto de perfil se actualizó correctamente.';
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la foto de perfil.');
      }
    } finally {
      if (mounted) setState(() => _guardandoFoto = false);
    }
  }

  void _cancelarFoto() {
    setState(() {
      _fotoSeleccionada = null;
      _nombreFotoSeleccionada = null;
      _tipoMimeFoto = null;
      _error = null;
    });
  }

  HorarioPerfil _limiteBarberiaPara(String dia) =>
      _horariosBarberia[dia] ??
      horariosBarberiaPorDefecto[dia] ??
      HorarioPerfil(diasemana: dia, horainicio: '09:00', horafin: '19:00');

  void _toggleDia(String dia) {
    final limite = _horariosBarberia[dia];
    if (limite == null) return;
    setState(() {
      final existente = _horarios.indexWhere((h) => h.diasemana == dia);
      if (existente >= 0) {
        _horarios.removeAt(existente);
        return;
      }
      _horarios = reconciliarHorariosConBarberia([
        ..._horarios,
        HorarioPerfil(
          diasemana: dia,
          horainicio: limite.horainicio,
          horafin: limite.horafin,
        ),
      ], _horariosBarberia).horarios;
    });
  }

  void _aplicarHorarioATodos() {
    if (_horarios.length < 2) return;
    final referencia = _horarios.first;
    setState(() {
      _horarios = _horarios.map((h) {
        final limite = _horariosBarberia[h.diasemana];
        final adaptado = h.copyWith(
          horainicio: referencia.horainicio,
          horafin: referencia.horafin,
        );
        return limite == null
            ? adaptado
            : ajustarHorarioAFranja(adaptado, limite);
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Horario de ${referencia.diasemana} adaptado al horario de atención de cada día.',
        ),
      ),
    );
  }

  Future<void> _elegirHora(int indice, {required bool esInicio}) async {
    final horario = _horarios[indice];
    final limite = _limiteBarberiaPara(horario.diasemana);
    final elegida = await mostrarSelectorHora(
      context: context,
      titulo:
          '${horario.diasemana} · ${esInicio ? 'Hora de inicio' : 'Hora de fin'}',
      horaActual: esInicio ? horario.horainicio : horario.horafin,
      horaApertura: limite.horainicio,
      horaCierre: limite.horafin,
      horaMinimaExclusiva: esInicio ? null : horario.horainicio,
      horaMaximaExclusiva: esInicio ? limite.horafin : null,
    );
    if (elegida == null || !mounted) return;
    setState(() {
      if (esInicio) {
        _horarios[indice] = horario.copyWith(
          horainicio: elegida,
          horafin: ajustarHoraFinTrasInicio(
            elegida,
            horario.horafin,
            horaCierre: limite.horafin,
          ),
        );
      } else {
        _horarios[indice] = horario.copyWith(horafin: elegida);
      }
    });
  }

  String get _iniciales {
    final partes = (_perfil?.nombre ?? '').trim().split(RegExp(r'\s+'));
    return partes
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase())
        .join();
  }

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    Widget? sufijo,
  }) => InputDecoration(
    labelText: etiqueta,
    prefixIcon: Icon(icono, color: Colores.gris),
    suffixIcon: sufijo,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD4D4D8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colores.azulOscuro, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colores.azulOscuro,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => confirmarYCerrarSesion(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _cargando
          ? const SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: EfectoEsqueleto(
                child: Column(
                  children: [
                    BloqueEsqueleto(ancho: 92, alto: 92, radio: 46),
                    SizedBox(height: 12),
                    BloqueEsqueleto(ancho: 140, alto: 14),
                    SizedBox(height: 28),
                    BloqueEsqueleto(ancho: double.infinity, alto: 58, radio: 12),
                    SizedBox(height: 14),
                    BloqueEsqueleto(ancho: double.infinity, alto: 58, radio: 12),
                    SizedBox(height: 14),
                    BloqueEsqueleto(ancho: double.infinity, alto: 58, radio: 12),
                    SizedBox(height: 28),
                    BloqueEsqueleto(ancho: double.infinity, alto: 52, radio: 14),
                  ],
                ),
              ),
            )
          : _perfil == null
          ? _estadoError()
          : _formularioPerfil(),
    );
  }

  Widget _estadoError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colores.carmin, size: 36),
          const SizedBox(height: 12),
          Text(_error ?? 'No se pudo cargar el perfil.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );

  Widget _formularioPerfil() {
    final urlFoto = _perfil!.fotoPerfil;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colores.azulOscuro,
            child: ClipOval(
              child: SizedBox(
                width: 92,
                height: 92,
                child: _fotoSeleccionada != null
                    ? Image.memory(_fotoSeleccionada!, fit: BoxFit.cover)
                    : urlFoto == null || urlFoto.isEmpty
                    ? _avatarSinFoto()
                    : Image.network(
                        urlFoto,
                        key: ValueKey(urlFoto),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarSinFoto(),
                      ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _guardandoFoto || _guardando ? null : _seleccionarFoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Cambiar foto'),
          ),
          const Text(
            'JPG, PNG o WebP · Máximo 5 MB',
            style: TextStyle(color: Colores.gris, fontSize: 12),
          ),
          if (_fotoSeleccionada != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _guardandoFoto ? null : _subirFoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _guardandoFoto ? 'Subiendo...' : 'Guardar foto',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _guardandoFoto ? null : _cancelarFoto,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _perfil!.nombre,
            style: const TextStyle(
              color: Colores.azulOscuro,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Sesion.rol.toUpperCase(),
            style: const TextStyle(
              color: Colores.gris,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) _mensaje(_error!, Colores.carmin),
          if (_exito != null) _mensaje(_exito!, const Color(0xFF15803D)),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 255,
                  decoration: _decoracion(
                    etiqueta: 'Nombre completo',
                    icono: Icons.person_outline,
                  ),
                  validator: (valor) => (valor ?? '').trim().isEmpty
                      ? 'Ingresa tu nombre.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracion(
                    etiqueta: 'Correo electrónico',
                    icono: Icons.mail_outline,
                  ),
                  validator: (valor) {
                    final correo = (valor ?? '').trim();
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(correo)) {
                      return 'Ingresa un correo válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _decoracion(
                    etiqueta: 'Número celular',
                    icono: Icons.phone_outlined,
                  ),
                  validator: (valor) {
                    final telefono = (valor ?? '').trim();
                    if (telefono.isEmpty) return 'Ingresa tu teléfono.';
                    if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
                      return 'El teléfono debe tener 10 dígitos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contrasenhaController,
                  obscureText: !_mostrarContrasenha,
                  decoration: _decoracion(
                    etiqueta: 'Nueva contraseña (opcional)',
                    icono: Icons.lock_outline,
                    sufijo: IconButton(
                      tooltip: _mostrarContrasenha
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      onPressed: () => setState(
                        () => _mostrarContrasenha = !_mostrarContrasenha,
                      ),
                      icon: Icon(
                        _mostrarContrasenha
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (valor) {
                    if (valor != null && valor.isNotEmpty && valor.length < 6) {
                      return 'Usa al menos 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmarContrasenhaController,
                  obscureText: !_mostrarContrasenha,
                  decoration: _decoracion(
                    etiqueta: 'Confirmar contraseña',
                    icono: Icons.lock_outline,
                  ),
                  validator: (valor) {
                    if (_contrasenhaController.text.isNotEmpty &&
                        valor != _contrasenhaController.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    if ((valor ?? '').isNotEmpty &&
                        _contrasenhaController.text.isEmpty) {
                      return 'Ingresa primero la nueva contraseña.';
                    }
                    return null;
                  },
                ),
                if (_esBarbero) _seccionBarbero(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar cambios',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.carmin,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionBarbero() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colores.grisBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del barbero',
            style: TextStyle(
              color: Colores.azulOscuro,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Servicios de especialidad',
            style: TextStyle(
              color: Colores.azulOscuro,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (_serviciosCatalogo.isEmpty)
            const Text(
              'No hay servicios en el catálogo.',
              style: TextStyle(color: Colores.gris, fontSize: 12),
            )
          else
            ..._serviciosCatalogo.map((servicio) {
              final marcado = _servicioIdsSeleccionados.contains(servicio.id);
              return CheckboxListTile(
                value: marcado,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: Colores.carmin,
                title: Text(
                  servicio.nombre,
                  style: const TextStyle(
                    color: Colores.azulOscuro,
                    fontSize: 14,
                  ),
                ),
                onChanged: _guardando
                    ? null
                    : (val) {
                        setState(() {
                          if (val == true) {
                            if (!_servicioIdsSeleccionados.contains(
                              servicio.id,
                            )) {
                              _servicioIdsSeleccionados.add(servicio.id);
                            }
                          } else {
                            _servicioIdsSeleccionados.remove(servicio.id);
                          }
                        });
                      },
              );
            }),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horarios de atención',
                      style: TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Acotado al horario de la barbería. Toca una hora para ajustarla.',
                      style: TextStyle(color: Colores.gris, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (_horarios.length > 1)
                TextButton(
                  onPressed: _guardando ? null : _aplicarHorarioATodos,
                  style: TextButton.styleFrom(
                    foregroundColor: Colores.carmin,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Igualar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (_horariosAjustados) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Tus franjas se ajustaron al horario vigente de la barbería. Guarda cambios para aplicarlos.',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 11.5),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: List.generate(diasSemanaOrden.length, (i) {
              final dia = diasSemanaOrden[i];
              final abierto = _horariosBarberia.containsKey(dia);
              final activo =
                  abierto && _horarios.any((h) => h.diasemana == dia);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == diasSemanaOrden.length - 1 ? 0 : 4,
                  ),
                  child: Tooltip(
                    message: abierto
                        ? '$dia (${horaBonita(_horariosBarberia[dia]!.horainicio)} - ${horaBonita(_horariosBarberia[dia]!.horafin)})'
                        : '$dia: barbería cerrada',
                    child: InkWell(
                      onTap: _guardando || !abierto ? null : () => _toggleDia(dia),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !abierto
                              ? const Color(0xFFF1F5F9)
                              : activo
                              ? Colores.azulOscuro
                              : Colores.fondo,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !abierto
                                ? const Color(0xFFE2E8F0)
                                : activo
                                ? Colores.azulOscuro
                                : Colores.grisBorde,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              _abreviaturasDias[dia] ?? dia.substring(0, 3),
                              style: TextStyle(
                                color: !abierto
                                    ? const Color(0xFF94A3B8)
                                    : activo
                                    ? Colors.white
                                    : Colores.gris,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          if (_horarios.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colores.fondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colores.grisBorde),
              ),
              child: const Text(
                'No tienes horarios configurados. Activa al menos un día arriba.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colores.gris, fontSize: 12.5),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colores.fondo,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colores.grisBorde),
              ),
              child: Column(
                children: _horarios.asMap().entries.map((entry) {
                  final indice = entry.key;
                  final h = entry.value;
                  final invalido = h.horainicio.compareTo(h.horafin) >= 0;
                  return Column(
                    children: [
                      if (indice > 0)
                        const Divider(height: 1, color: Colores.grisBorde),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: invalido
                                          ? Colores.carmin
                                          : const Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      h.diasemana,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: invalido
                                            ? Colores.carmin
                                            : Colores.azulOscuro,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            _botonHoraCompacta(
                              hora: horaBonita(h.horainicio),
                              invalido: invalido,
                              onTap: _guardando
                                  ? null
                                  : () => _elegirHora(indice, esInicio: true),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Colores.gris,
                              ),
                            ),
                            _botonHoraCompacta(
                              hora: horaBonita(h.horafin),
                              invalido: invalido,
                              onTap: _guardando
                                  ? null
                                  : () => _elegirHora(indice, esInicio: false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _botonHoraCompacta({
    required String hora,
    required bool invalido,
    required VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: invalido ? Colores.carmin : Colores.grisBorde,
        ),
      ),
      child: Text(
        hora,
        style: TextStyle(
          color: invalido ? Colores.carmin : Colores.azulOscuro,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _avatarSinFoto() => Center(
    child: Text(
      _iniciales.isEmpty ? 'U' : _iniciales,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _mensaje(String texto, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(texto, style: TextStyle(color: color)),
    ),
  );
}
