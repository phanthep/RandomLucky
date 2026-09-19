import 'package:flutter/material.dart';
class BuildBackground extends StatelessWidget {
  final AnimationController idleCtrl;
  const BuildBackground({super.key, required this.idleCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idleCtrl,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _BokehPainter(idleCtrl.value),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1B1036), Color(0xFF3A1F63), Color(0xFF0E0620)],
            ),
          ),
        ),
      ),
    );
  }

  class _BokehPainter extends CustomPainter {
  final double t;
  _BokehPainter(this.t);
  final List<Offset> _seeds = List.generate(18, (i) {
    final r = Random(i * 91);
    return Offset(r.nextDouble(), r.nextDouble());
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final dy = (s.dy + t * 0.05 * (i.isEven ? 1 : -1)) % 1.0;
      final radius = 2.0 + (i % 4) * 1.6;
      canvas.drawCircle(
        Offset(s.dx * size.width, dy * size.height),
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.05 + 0.03 * (i % 3)),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _BokehPainter oldDelegate) => true;
}