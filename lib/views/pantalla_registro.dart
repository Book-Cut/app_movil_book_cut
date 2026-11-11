import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _dominiosPermitidos = [
    'gmail.com',
    'hotmail.com',
    'outlook.com',
    'sena.edu.co',
  ];

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

  String _traducirErrorRegistro(String mensaje) {
    if (RegExp(r'correo has already been taken', caseSensitive: false)
        .hasMatch(mensaje)) {
      return 'Este correo ya tiene una cuenta. Inicia sesión o usa otro correo.';
    }
    return mensaje;
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
      if (mounted) {
        setState(() => _error = _traducirErrorRegistro(error.mensaje));
      }
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
    if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
      setState(() {
        _error = 'Ingresa un teléfono de 10 dígitos para continuar.';
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
      if (mounted) {
        setState(() => _error = _traducirErrorRegistro(error.mensaje));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo conectar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _verTerminos() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colores.azulOscuro,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Términos y condiciones',
                      style: TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colores.fondo,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colores.grisBorde),
                ),
                child: const Text(
                  'Al crear una cuenta aceptas usar Book&Cut para gestionar tus citas de barbería y mantener tus datos de contacto actualizados.',
                  style: TextStyle(
                    color: Colores.gris,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.azulOscuro,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                          final correo = (valor ?? '').trim().toLowerCase();
                          if (correo.isEmpty) return 'Ingresa tu correo.';
                          final match = RegExp(
                            r'^[^\s@]+@([^\s@]+\.[^\s@]+)$',
                          ).firstMatch(correo);
                          if (match == null) {
                            return 'Ingresa un correo válido.';
                          }
                          final dominio = match.group(1);
                          if (!_dominiosPermitidos.contains(dominio)) {
                            return 'Usa correo @gmail.com, @hotmail.com, @outlook.com o @sena.edu.co.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: _decoracion(
                          etiqueta: 'Teléfono',
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
                        validator: (valor) =>
                            valor != _contrasenhaController.text
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
                    TextButton(
                      onPressed: _verTerminos,
                      child: const Text('Ver'),
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
                    label: Text(
                      _cargando ? 'Creando cuenta...' : 'Crear cuenta',
                    ),
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
      ),
    );
  }
}
