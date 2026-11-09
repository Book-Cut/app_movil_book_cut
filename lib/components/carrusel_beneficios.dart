import 'dart:async';

import 'package:flutter/material.dart';

import '../models/beneficio.dart';
import '../services/beneficios_service.dart';

class CarruselBeneficios extends StatefulWidget {
  const CarruselBeneficios({super.key});

  @override
  State<CarruselBeneficios> createState() => _CarruselBeneficiosState();
}

class _CarruselBeneficiosState extends State<CarruselBeneficios> {
  static const _imagenAlternativa =
      'https://placehold.co/1600x900.png?text=Servicio+1';

  final _controlador = PageController();
  Timer? _temporizador;
  List<Beneficio> _items = [];
  int _actual = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await listarBeneficiosVigentes();
      if (!mounted) return;
      setState(() => _items = datos);
    } catch (_) {
      // Si falla, se queda la imagen de relleno
    }
    if (_items.length > 1) {
      _temporizador = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _siguiente(),
      );
    }
  }

  void _siguiente() {
    if (!_controlador.hasClients || _items.isEmpty) return;
    _controlador.animateToPage(
      (_actual + 1) % _items.length,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _verDetalle(Beneficio b) {
    showDialog(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(b.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${b.tipo}'),
            const SizedBox(height: 4),
            Text('Vigencia: del ${b.fechaInicio} al ${b.fechaFin}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hayItems = _items.isNotEmpty;
    final cantidad = hayItems ? _items.length : 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controlador,
              itemCount: cantidad,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (contexto, i) {
                final b = hayItems ? _items[i] : null;
                return GestureDetector(
                  onTap: b == null ? null : () => _verDetalle(b),
                  child: Image.network(
                    b?.imagenUrl ?? _imagenAlternativa,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Image.network(_imagenAlternativa, fit: BoxFit.cover),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  cantidad,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _actual ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

