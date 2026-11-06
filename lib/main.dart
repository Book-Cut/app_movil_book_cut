import 'package:flutter/material.dart';

import 'core/colores.dart';
import 'core/sesion.dart';
import 'views/pantalla_bienvenida.dart';
import 'views/pantalla_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Sesion.restaurar();
  } catch (_) {
    // Secure storage may be unavailable in preview or test environments.
  }
  runApp(const BookCutApp());
}

class BookCutApp extends StatelessWidget {
  const BookCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
