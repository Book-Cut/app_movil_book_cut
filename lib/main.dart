import 'package:flutter/material.dart';

import 'core/colores.dart';
import 'views/pantalla_inicio.dart';

void main() => runApp(const BookCutApp());

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
      home: const PantallaInicio(),
    );
  }
}
