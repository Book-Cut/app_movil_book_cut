import 'package:flutter/material.dart';

import '../components/header_nav.dart';
import '../components/hero_inicio.dart';
import '../components/pie_pagina.dart';
import '../components/seccion_locales.dart';
import '../components/seccion_servicios.dart';
import '../core/colores.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _claveServicios = GlobalKey();
  final _claveLocales = GlobalKey();

  void _irA(GlobalKey clave) {
    final contexto = clave.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: HeaderNav(
        onServicios: () => _irA(_claveServicios),
        onLocales: () => _irA(_claveLocales),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroInicio(
              onReservar: () {
                // Más adelante: ir a agendar
              },
              onBajar: () => _irA(_claveServicios),
            ),
            SeccionServicios(key: _claveServicios),
            SeccionLocales(key: _claveLocales),
            const PiePagina(),
          ],
        ),
      ),
    );
  }
}
