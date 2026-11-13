import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../core/sesion.dart';
import '../services/autenticacion_service.dart';
import 'navegacion_rol.dart';
import 'pantalla_perfil.dart';
import 'pantalla_registro.dart';

class PantallaInicioSesion extends StatefulWidget {
  final bool volverAlOrigen;
  final String? mensajeInfo;

  const PantallaInicioSesion({
    super.key,
    this.volverAlOrigen = false,
    this.mensajeInfo,
  });

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
      await _continuarDespuesDeAcceso();
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

  Future<void> _iniciarSesionSocial(String proveedor) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final signupToken = await iniciarSesionSocial(proveedor: proveedor);
      if (!mounted) return;
      if (signupToken != null) {
        final registroCompleto = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PantallaRegistro(googleSignupToken: signupToken),
          ),
        );
        if (!mounted || registroCompleto != true) return;
      }
      await _continuarDespuesDeAcceso();
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
    await _continuarDespuesDeAcceso();
  }

  Future<void> _continuarDespuesDeAcceso() async {
    if ((Sesion.telefono ?? '').trim().isEmpty) {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const PantallaPerfil()));
      if (!mounted) return;
    }

    if (widget.volverAlOrigen) {
      Navigator.of(context).pop(true);
    } else {
      irAInicioPorRol(context);
    }
  }

  Future<void> _recuperarContrasenha() async {
    final correoRecuperacion = TextEditingController(
      text: _correoController.text.trim(),
    );
    final formRecuperacion = GlobalKey<FormState>();
    var enviando = false;
    String? mensaje;
    var exito = false;

    await showModalBottomSheet<void>(
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
                14,
                22,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Form(
                key: formRecuperacion,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Recuperar contraseña',
                      style: TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                      style: TextStyle(color: Colores.gris, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: correoRecuperacion,
                      keyboardType: TextInputType.emailAddress,
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
                    if (mensaje != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        mensaje!,
                        style: TextStyle(
                          color: exito
                              ? const Color(0xFF15803D)
                              : Colores.carmin,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: enviando
                            ? null
                            : () async {
                                if (!formRecuperacion.currentState!
                                    .validate()) {
                                  return;
                                }
                                setModalState(() {
                                  enviando = true;
                                  mensaje = null;
                                  exito = false;
                                });
                                try {
                                  final res =
                                      await solicitarRecuperacionContrasenha(
                                        correo: correoRecuperacion.text,
                                      );
                                  setModalState(() {
                                    exito = true;
                                    mensaje = res;
                                  });
                                } on ApiException catch (e) {
                                  setModalState(() {
                                    exito = false;
                                    mensaje = e.mensaje;
                                  });
                                } catch (_) {
                                  setModalState(() {
                                    exito = false;
                                    mensaje = 'No se pudo enviar el enlace. Intenta de nuevo.';
                                  });
                                } finally {
                                  setModalState(() => enviando = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.azulOscuro,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          enviando
                              ? 'Enviando...'
                              : 'Enviar enlace de recuperación',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    correoRecuperacion.dispose();
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
                const SizedBox(height: 24),
                Center(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colores.azulOscuro,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'lib/assets/logo_blanca.png',
                      width: 176,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
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
                if (widget.mensajeInfo != null &&
                    widget.mensajeInfo!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1D4ED8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.mensajeInfo!,
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cargando ? null : _recuperarContrasenha,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colores.gris, fontSize: 13),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
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
                const SizedBox(height: 18),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
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
                        : () => _iniciarSesionSocial('google'),
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: const Text('Continuar con Google'),
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
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colores.grisBorde),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(color: Colores.gris, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _cargando ? null : _crearCuenta,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Crear cuenta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colores.azulOscuro,
                            side: const BorderSide(color: Colores.azulOscuro),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
