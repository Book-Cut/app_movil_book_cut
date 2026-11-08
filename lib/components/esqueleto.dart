import 'package:flutter/material.dart';

import '../core/colores.dart';

class EfectoEsqueleto extends StatefulWidget {
  final Widget child;

  const EfectoEsqueleto({super.key, required this.child});

  @override
  State<EfectoEsqueleto> createState() => _EfectoEsqueletoState();
}

class _EfectoEsqueletoState extends State<EfectoEsqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando contenido',
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _animacion,
          child: widget.child,
          builder: (context, child) {
            final desplazamiento = -2 + (_animacion.value * 4);
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(desplazamiento, 0),
                end: Alignment(desplazamiento + 1.5, 0),
                colors: const [
                  Color(0xFFE4E4E7),
                  Color(0xFFF4F4F5),
                  Color(0xFFE4E4E7),
                ],
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class BloqueEsqueleto extends StatelessWidget {
  final double? ancho;
  final double alto;
  final double radio;
  final Color color;

  const BloqueEsqueleto({
    super.key,
    this.ancho,
    required this.alto,
    this.radio = 8,
    this.color = const Color(0xFFE4E4E7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
  }
}

class EsqueletoBarbero extends StatelessWidget {
  const EsqueletoBarbero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const BloqueEsqueleto(ancho: 56, alto: 56, radio: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BloqueEsqueleto(
                  ancho: MediaQuery.sizeOf(context).width * 0.38,
                  alto: 14,
                ),
                const SizedBox(height: 10),
                const BloqueEsqueleto(ancho: 190, alto: 11),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colores.gris),
        ],
      ),
    );
  }
}

class EsqueletoCita extends StatelessWidget {
  const EsqueletoCita({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BloqueEsqueleto(ancho: 52, alto: 52, radio: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BloqueEsqueleto(ancho: 150, alto: 15),
                    const SizedBox(height: 8),
                    BloqueEsqueleto(
                      ancho: MediaQuery.sizeOf(context).width * 0.42,
                      alto: 12,
                    ),
                  ],
                ),
              ),
              const BloqueEsqueleto(ancho: 72, alto: 24, radio: 12),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          const BloqueEsqueleto(ancho: 220, alto: 12),
          const SizedBox(height: 9),
          const BloqueEsqueleto(ancho: 160, alto: 12),
        ],
      ),
    );
  }
}
