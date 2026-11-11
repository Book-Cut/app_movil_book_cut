import 'package:flutter/material.dart';

import '../core/sesion.dart';
import 'pantalla_admin_pendiente.dart';
import 'pantalla_barbero.dart';
import 'pantalla_bienvenida.dart';
import 'pantalla_principal.dart';

Widget pantallaInicioPorRol() {
  if (!Sesion.activa) return const PantallaBienvenida();
  return switch (Sesion.rolId) {
    1 => const PantallaAdminPendiente(),
    2 => const PantallaBarbero(),
    _ => const PantallaPrincipal(),
  };
}

void irAInicioPorRol(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => pantallaInicioPorRol()),
    (_) => false,
  );
}
