import 'package:flutter/material.dart';

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
  Perfil? _perfil;
  String? _error;
  String? _exito;
  bool _cargando = true;
  bool _guardando = false;
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
          ? const Center(
              child: CircularProgressIndicator(color: Colores.carmin),
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
            child: urlFoto == null || urlFoto.isEmpty
                ? Text(
                    _iniciales.isEmpty ? 'U' : _iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ClipOval(
                    child: Image.network(
                      urlFoto,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          _iniciales.isEmpty ? 'U' : _iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
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

  Widget _mensaje(String texto, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(texto, style: TextStyle(color: color)),
    ),
  );
}
