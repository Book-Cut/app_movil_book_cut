import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../components/indicador_pasos_registro.dart';
import '../services/autenticacion_service.dart';
import 'pantalla_verificar_correo.dart';

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
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _errorTerminos;
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
    final formularioValido = _formKey.currentState!.validate();
    if (!_aceptaTerminos) {
      setState(
        () => _errorTerminos = 'Debes aceptar los términos y condiciones.',
      );
    }
    if (!formularioValido || !_aceptaTerminos) return;

    setState(() {
      _cargando = true;
      _errorTerminos = null;
      _error = null;
    });

    try {
      await enviarCodigoRegistro(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        contrasenha: _contrasenhaController.text,
        terminosAceptados: _aceptaTerminos,
      );
      if (!mounted) return;
      final verificado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PantallaVerificarCorreo(
            correo: _correoController.text.trim(),
            reenviarCodigo: () => enviarCodigoRegistro(
              nombre: _nombreController.text.trim(),
              correo: _correoController.text.trim(),
              telefono: _telefonoController.text.trim(),
              contrasenha: _contrasenhaController.text,
              terminosAceptados: _aceptaTerminos,
            ),
          ),
        ),
      );
      if (verificado == true && mounted) {
        Navigator.of(context).pop(true);
      }
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

  Future<void> _registrarConSocial(String proveedor) async {
    final telefono = _telefonoController.text.trim();
    if (telefono.isEmpty || telefono.length > 45) {
      setState(() {
        _error = 'Ingresa un teléfono válido para continuar.';
        _errorTerminos = null;
      });
      return;
    }
    if (!_aceptaTerminos) {
      setState(() {
        _error = null;
        _errorTerminos = 'Debes aceptar los términos y condiciones.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _errorTerminos = null;
    });

    try {
      await registrarConSocial(proveedor: proveedor, telefono: telefono);
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
              const SizedBox(height: 12),
              const IndicadorPasosRegistro(pasoActual: 1),
              const SizedBox(height: 24),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    activeColor: Colores.carmin,
                    onChanged: _cargando
                        ? null
                        : (acepta) => setState(() {
                            _aceptaTerminos = acepta ?? false;
                            if (_aceptaTerminos) _errorTerminos = null;
                          }),
                  ),
                  const Expanded(
                    child: Text('Acepto los términos y condiciones.'),
                  ),
                ],
              ),
              if (_errorTerminos != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    _errorTerminos!,
                    style: const TextStyle(color: Colores.carmin),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cargando
                      ? null
                      : () => _registrarConSocial('google'),
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  label: const Text('Registrarse con Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD4D4D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _cargando
                      ? null
                      : () => _registrarConSocial('facebook'),
                  icon: const Text(
                    'f',
                    style: TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  label: const Text('Registrarse con Facebook'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colores.azulOscuro,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD4D4D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
