import 'package:flutter/material.dart';

import '../core/colores.dart';

class HeaderNav extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onServicios;
  final VoidCallback onLocales;

  const HeaderNav({
    super.key,
    required this.onServicios,
    required this.onLocales,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colores.azulOscuro,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Image.asset('lib/assets/logo_blanca.png', height: 32),
      actions: [
        PopupMenuButton<String>(
          onSelected: (valor) {
            if (valor == 'servicios') onServicios();
            if (valor == 'locales') onLocales();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'servicios', child: Text('Servicios')),
            PopupMenuItem(value: 'locales', child: Text('Locales')),
          ],
        ),
      ],
    );
  }
}
