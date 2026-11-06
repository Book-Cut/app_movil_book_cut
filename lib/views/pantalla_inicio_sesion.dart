import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../services/autenticacion_service.dart';
import 'pantalla_principal.dart';
import 'pantalla_registro.dart';

class PantallaInicioSesion extends StatefulWidget {
  final bool volverAlOrigen;

  const PantallaInicioSesion({super.key, this.volverAlOrigen = false});

  @override
  State<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenhaController = TextEditingController();
  bool _mostrarContrasenha = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenhaController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await iniciarSesion(
        correo: _correoController.text.trim(),
        contrasenha: _contrasenhaController.text,
      );
      if (!mounted) return;
      _continuarDespuesDeAcceso();
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

  Future<void> _crearCuenta() async {
    final registrado = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const PantallaRegistro()));
    if (!mounted || registrado != true) return;
    _continuarDespuesDeAcceso();
  }

  void _continuarDespuesDeAcceso() {
    if (widget.volverAlOrigen) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
      );
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
              const SizedBox(height: 32),
              Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colores.azulOscuro,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset('lib/assets/logo_blanca.png', width: 176),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Inicia sesión',
                style: TextStyle(
                  color: Colores.azulOscuro,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accede a tu cuenta para gestionar tus citas.',
                style: TextStyle(color: Colores.gris, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                      controller: _contrasenhaController,
                      obscureText: !_mostrarContrasenha,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _enviar(),
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
                      validator: (valor) => (valor ?? '').isEmpty
                          ? 'Ingresa tu contraseña.'
                          : null,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colores.carmin,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colores.carmin),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _cargando ? null : _enviar,
                  icon: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(_cargando ? 'Ingresando...' : 'Iniciar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.carmin,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colores.carmin.withValues(
                      alpha: 0.7,
                    ),
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
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _cargando ? null : _crearCuenta,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Crear cuenta'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
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
