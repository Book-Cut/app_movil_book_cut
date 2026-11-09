import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/esqueleto.dart';
import '../core/api.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import '../models/perfil.dart';
import '../services/autenticacion_service.dart';
import '../services/perfil_service.dart';
import 'pantalla_bienvenida.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenhaController = TextEditingController();
  final _confirmarContrasenhaController = TextEditingController();
  final _selectorImagen = ImagePicker();
  Perfil? _perfil;
  Uint8List? _fotoSeleccionada;
  String? _nombreFotoSeleccionada;
  String? _tipoMimeFoto;
  String? _error;
  String? _exito;
  bool _cargando = true;
  bool _guardando = false;
  bool _guardandoFoto = false;
  bool _mostrarContrasenha = false;

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
    });
    try {
      final perfil = await obtenerPerfil();
      if (!mounted) return;
      _perfil = perfil;
      _nombreController.text = perfil.nombre;
      _correoController.text = perfil.correo;
      _telefonoController.text = perfil.telefono;
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
      );
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
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
            onPressed: _cerrarSesion,
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
                  keyboardType: TextInputType.phone,
                  maxLength: 45,
                  decoration: _decoracion(
                    etiqueta: 'Número celular',
                    icono: Icons.phone_outlined,
                  ),
                  validator: (valor) => (valor ?? '').trim().isEmpty
                      ? 'Ingresa tu teléfono.'
                      : null,
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
