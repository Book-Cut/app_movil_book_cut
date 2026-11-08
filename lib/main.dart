import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api.dart';
import 'core/colores.dart';
import 'core/sesion.dart';
import 'services/perfil_service.dart';
import 'views/pantalla_bienvenida.dart';
import 'views/pantalla_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Sesion.restaurar();
  } catch (_) {
    // Secure storage may be unavailable in preview or test environments.
  }
  runApp(const ProviderScope(child: BookCutApp()));
}

class BookCutApp extends StatefulWidget {
  const BookCutApp({super.key});

  @override
  State<BookCutApp> createState() => _BookCutAppState();
}

class _BookCutAppState extends State<BookCutApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _timerValidacion;
  bool _enPrimerPlano = true;
  bool _validandoSesion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Sesion.alExpirar = _volverAlInicio;
    _timerValidacion = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_enPrimerPlano) unawaited(_validarSesion());
    });
    if (Sesion.activa) unawaited(_validarSesion());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _enPrimerPlano = state == AppLifecycleState.resumed;
    if (_enPrimerPlano) unawaited(_validarSesion());
  }

  Future<void> _validarSesion() async {
    if (!Sesion.activa || _validandoSesion) return;
    _validandoSesion = true;
    try {
      await obtenerPerfil();
    } on ApiException catch (error) {
      if (error.codigo != 401) {
        debugPrint('No se pudo validar la sesión: ${error.mensaje}');
      }
    } catch (error) {
      debugPrint('No se pudo validar la sesión: $error');
    } finally {
      _validandoSesion = false;
    }
  }

  void _volverAlInicio() {
    _navigatorKey.currentState?.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PantallaBienvenida(sesionExpirada: true),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerValidacion?.cancel();
    if (Sesion.alExpirar == _volverAlInicio) {
      Sesion.alExpirar = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Book&Cut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colores.carmin),
        scaffoldBackgroundColor: Colores.fondo,
      ),
      home: Sesion.activa
          ? const PantallaPrincipal()
          : const PantallaBienvenida(),
    );
  }
}
