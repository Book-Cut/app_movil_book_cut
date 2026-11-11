import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/colores.dart';
import '../core/sesion.dart';
import 'navegacion_rol.dart';
import 'pantalla_inicio_sesion.dart';
import 'pantalla_principal.dart';
import 'pantalla_registro.dart';

class PantallaBienvenida extends StatefulWidget {
  final bool sesionExpirada;

  const PantallaBienvenida({super.key, this.sesionExpirada = false});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  static const _mensajes = [
    'Estilo, precisión y cuidado.',
    'Encuentra tu servicio ideal.',
    'Reserva tu próxima visita en Book&Cut.',
  ];

  final _controlador = PageController();
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sesionExpirada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu sesión ya no es válida. Inicia sesión de nuevo para continuar.',
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _reservar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
    );
  }

  void _iniciarSesion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaInicioSesion()),
    );
  }

  Future<void> _registrarse() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaRegistro()),
    );
    if (ok == true && mounted && Sesion.activa) {
      irAInicioPorRol(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colores.azulOscuro,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'lib/assets/logo_blanca.png',
                        width: 230,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'RESERVA TU CITA',
                      style: TextStyle(
                        color: Colores.carmin,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 60,
                      child: PageView.builder(
                        controller: _controlador,
                        itemCount: _mensajes.length,
                        onPageChanged: (i) => setState(() => _pagina = i),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Center(
                            child: Text(
                              _mensajes[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colores.azulOscuro,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _mensajes.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _pagina
                                ? Colores.azulOscuro
                                : const Color(0xFFD4D4D8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
              decoration: const BoxDecoration(
                color: Colores.azulOscuro,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _reservar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colores.carmin,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Reservar ahora'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _iniciarSesion,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colores.dorado,
                            width: 2,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _registrarse,
                      style: TextButton.styleFrom(
                        foregroundColor: Colores.dorado,
                      ),
                      child: const Text(
                        '¿No tienes cuenta? Regístrate aquí',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
