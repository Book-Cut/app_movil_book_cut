import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../services/autenticacion_service.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenhaController = TextEditingController();
  final _confirmacionController = TextEditingController();
  bool _mostrarContrasenha = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenhaController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await registrarUsuario(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        contrasenha: _contrasenhaController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: Colores.gris),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4D4D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4D4D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colores.azulOscuro, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: Colores.azulOscuro,
              ),
              const SizedBox(height: 20),
              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  color: Colores.azulOscuro,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regístrate para reservar y administrar tus citas.',
                style: TextStyle(color: Colores.gris, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 255,
                      decoration: _decoracion(
                        etiqueta: 'Nombre completo',
                        icono: Icons.person_outline,
                      ),
                      validator: (valor) {
                        final nombre = (valor ?? '').trim();
                        if (nombre.isEmpty) return 'Ingresa tu nombre.';
                        if (nombre.length > 255) {
                          return 'El nombre no puede superar 255 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoracion(
                        etiqueta: 'Correo electrónico',
                        icono: Icons.mail_outline,
                      ),
                      validator: (valor) {
                        final correo = (valor ?? '').trim();
                        if (correo.isEmpty) return 'Ingresa tu correo.';
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
                      textInputAction: TextInputAction.next,
                      maxLength: 45,
                      decoration: _decoracion(
                        etiqueta: 'Teléfono',
                        icono: Icons.phone_outlined,
                      ),
                      validator: (valor) {
                        final telefono = (valor ?? '').trim();
                        if (telefono.isEmpty) return 'Ingresa tu teléfono.';
                        if (telefono.length > 45) {
                          return 'El teléfono no puede superar 45 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contrasenhaController,
                      obscureText: !_mostrarContrasenha,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _decoracion(
                        etiqueta: 'Contraseña',
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
                        if ((valor ?? '').length < 6) {
                          return 'Usa al menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmacionController,
                      obscureText: !_mostrarContrasenha,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _registrar(),
                      decoration: _decoracion(
                        etiqueta: 'Confirmar contraseña',
                        icono: Icons.lock_outline,
                      ),
                      validator: (valor) => valor != _contrasenhaController.text
                          ? 'Las contraseñas no coinciden.'
                          : null,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colores.carmin)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _cargando ? null : _registrar,
                  icon: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(_cargando ? 'Creando cuenta...' : 'Crear cuenta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
