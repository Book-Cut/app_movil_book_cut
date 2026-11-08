import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/colores.dart';
import '../components/indicador_pasos_registro.dart';
import '../services/autenticacion_service.dart';

class PantallaVerificarCorreo extends StatefulWidget {
  final String correo;
  final Future<void> Function() reenviarCodigo;

  const PantallaVerificarCorreo({
    super.key,
    required this.correo,
    required this.reenviarCodigo,
  });

  @override
  State<PantallaVerificarCorreo> createState() =>
      _PantallaVerificarCorreoState();
}

class _PantallaVerificarCorreoState extends State<PantallaVerificarCorreo> {
  final _codigoController = TextEditingController();
  bool _verificando = false;
  bool _reenviando = false;
  String? _error;
  String? _mensaje;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      setState(() => _error = 'Ingresa los 6 dígitos del código.');
      return;
    }

    setState(() {
      _verificando = true;
      _error = null;
      _mensaje = null;
    });
    try {
      await verificarCodigoRegistro(correo: widget.correo, codigo: codigo);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo verificar el código. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _reenviando = true;
      _error = null;
      _mensaje = null;
    });
    try {
      await widget.reenviarCodigo();
      if (!mounted) return;
      _codigoController.clear();
      setState(
        () => _mensaje =
            'Enviamos otro código. Revisa también la carpeta de spam.',
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo reenviar el código. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _verificando || _reenviando;

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        backgroundColor: Colores.fondo,
        foregroundColor: Colores.azulOscuro,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver al registro',
          onPressed: ocupado ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Verificación',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const IndicadorPasosRegistro(pasoActual: 2),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 44,
                          color: Colores.carmin,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Confirma tu correo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Te enviamos un código de 6 dígitos a',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colores.gris.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.correo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colores.azulOscuro,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 18,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Código de verificación',
                            style: TextStyle(
                              color: Colores.azulOscuro,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codigoController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            maxLength: 6,
                            onChanged: (_) {
                              if (_error != null) {
                                setState(() => _error = null);
                              }
                            },
                            onSubmitted: (_) {
                              if (!ocupado) _verificar();
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colores.azulOscuro,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: '------',
                              hintStyle: TextStyle(
                                color: Colors.blueGrey.shade200,
                                letterSpacing: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E4E7),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E4E7),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colores.carmin,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: Colores.gris,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'El código vence en 10 minutos',
                                style: TextStyle(
                                  color: Colores.gris.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_mensaje != null) ...[
                            const SizedBox(height: 14),
                            _AvisoVerificacion(
                              texto: _mensaje!,
                              esError: false,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            _AvisoVerificacion(texto: _error!, esError: true),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: ocupado ? null : _verificar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.azulOscuro,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colores.azulOscuro
                              .withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _verificando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Verificar correo'),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No recibiste el código?',
                          style: TextStyle(
                            color: Colores.gris.withValues(alpha: 0.95),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: ocupado ? null : _reenviar,
                          style: TextButton.styleFrom(
                            foregroundColor: Colores.carmin,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          child: _reenviando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Reenviar'),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    Text(
                      'Asegúrate de revisar también tu carpeta de correo no deseado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colores.gris.withValues(alpha: 0.75),
                        fontSize: 12,
                        height: 1.4,
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
  }
}

class _AvisoVerificacion extends StatelessWidget {
  final String texto;
  final bool esError;

  const _AvisoVerificacion({required this.texto, required this.esError});

  @override
  Widget build(BuildContext context) {
    final color = esError ? Colores.carmin : const Color(0xFF15803D);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
