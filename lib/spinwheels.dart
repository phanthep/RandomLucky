import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:gacha1/sfxservice.dart';

/// -------------------- SPIN WHEEL SCREEN --------------------
class SpinWheelScreen extends StatefulWidget {
  /// ส่งรายชื่อเข้ามาจากภายนอกได้ (เช่นจาก Supabase)
  /// ถ้าไม่ส่งมา จะใช้รายชื่อตัวอย่างแทน (โหมด standalone)
  final List<String>? entries;
  const SpinWheelScreen({super.key, this.entries});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  late final List<String> _labels;

  final List<Color> palette = const [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFB983FF),
    Color(0xFFFF9F45),
    Color(0xFF45D3E8),
    Color(0xFFF06292),
  ];

  late final AnimationController _spinCtrl;
  late final AnimationController _idleCtrl;
  late final ConfettiController _confettiCtrl;

  Animation<double>? _currentAngle;
  int _lastTickIndex = -1;

  bool _spinning = false;
  bool _revealed = false;
  int _winnerIndex = 0;

  @override
  void initState() {
    super.initState();
    _labels = (widget.entries != null && widget.entries!.isNotEmpty)
        ? widget.entries!
        : const [
            '🏆 รางวัลใหญ่',
            '🎁 ของรางวัลที่ 2',
            '🎟 คูปองส่วนลด',
            '👕 เสื้อที่ระลึก',
            '☕ บัตรกาแฟ',
            '📦 กล่องสุ่ม',
          ];

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));

    _spinCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_winnerIndex > 0) {
          //_labels.removeAt(_winnerIndex);
          //await SupabaseService.markWinner(participantId: winner['id'], eventId: widget.eventId, prize: "วงล้อนำโชค");
        }

        setState(() {
          //_labels.removeAt(_winnerIndex);
          _spinning = false;
          _revealed = true;
        });
        SfxService.stopSpinLoop();
        HapticFeedback.heavyImpact();
        SfxService.win();
        _confettiCtrl.play();
      }
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _idleCtrl.dispose();
    _confettiCtrl.dispose();
    SfxService.stopSpinLoop();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _labels.isEmpty) return;
    if (_labels.length == 1) {
      // ถ้ามีแค่ตัวเลือกเดียว ให้ข้ามการหมุนและแสดงผลทันที
      setState(() {
        _spinning = false;
        _revealed = true;
        _winnerIndex = 0;
      });
      SfxService.win();
      _confettiCtrl.play();
      return;
    }
    final rnd = Random();
    final chosen = rnd.nextInt(_labels.length);
    final segmentAngle = 2 * pi / _labels.length;

    final targetOffset = chosen * segmentAngle + segmentAngle / 2;
    const fullSpins = 8;
    final finalAngle = (2 * pi * fullSpins) - targetOffset;

    SfxService.click();
    HapticFeedback.lightImpact();

    setState(() {
      _spinning = true;
      _revealed = false;
      _winnerIndex = chosen;
      _lastTickIndex = -1;
    });

    SfxService.startSpinLoop();

    _spinCtrl.reset();
    final anim = Tween<double>(
      begin: 0,
      end: finalAngle,
    ).animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutQuart));

    anim.addListener(() {
      setState(() {});
      final idx = (anim.value / segmentAngle).floor();
      if (idx != _lastTickIndex) {
        _lastTickIndex = idx;
        //SfxService.click();
        HapticFeedback.selectionClick();
      }
    });

    _currentAngle = anim;
    _spinCtrl.forward();
  }

  void _reset() {
    setState(() {
      if (_winnerIndex >= 0) {
        _labels.removeAt(_winnerIndex);
        //await SupabaseService.markWinner(participantId: winner['id'], eventId: widget.eventId, prize: "วงล้อนำโชค");
      }
      _revealed = false;
    });
    _spinCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final angle = _currentAngle?.value ?? 0.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B1036),
                  Color(0xFF3A1F63),
                  Color(0xFF0E0620),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiCtrl,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 28,
                    emissionFrequency: 0.03,
                    gravity: 0.25,
                    colors: palette,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFFFE066), Color(0xFFFF9F45)],
                      ).createShader(r),
                      child: const Text(
                        '🎡 วงล้อนำโชค',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: _buildWheelArea(angle),
                    ),
                    const SizedBox(height: 34),
                    _buildControls(),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelArea(double angle) {
    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, _) {
        final glow = 0.35 + sin(_idleCtrl.value * 2 * pi) * 0.1;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(glow),
                    blurRadius: 50,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: angle,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 4,
                  ),
                ),
                child: CustomPaint(
                  painter: _WheelPainter(labels: _labels, colors: palette),
                ),
              ),
            ),
            ...List.generate(16, (i) {
              final a = (i / 16) * 2 * pi;
              return Transform.translate(
                offset: Offset(cos(a) * 138, sin(a) * 138),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amberAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.white, Color(0xFFDDDDDD)],
                ),
                border: Border.all(color: Colors.black26, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.star, color: Color(0xFFC9184A), size: 20),
            ),
            const Positioned(top: -6, child: _PointerArrow()),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    if (_revealed) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF3C4),
                  Color(0xFFFFD166),
                  Color(0xFFFFA45C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '🎉 ยินดีด้วย 🎉',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC9184A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[_winnerIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.replay),
            label: const Text(
              'หมุนอีกครั้ง',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3A1F63),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: _spinning ? null : _spin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4D6D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
      ),
      child: Text(
        _spinning ? 'กำลังหมุน...' : '🎯 หมุนวงล้อ',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// -------------------- ลูกศรชี้ตำแหน่งผลลัพธ์ --------------------
class _PointerArrow extends StatelessWidget {
  const _PointerArrow();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(36, 40), painter: _ArrowPainter());
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE066), Color(0xFFFF9F45)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// -------------------- ตัววาดวงล้อ --------------------
class _WheelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> colors;
  _WheelPainter({required this.labels, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / labels.length;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (int i = 0; i < labels.length; i++) {
      final startAngle = -pi / 2 + i * segmentAngle;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(color, Colors.white, 0.15)!, color],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, segmentAngle, true, paint);

      canvas.drawArc(
        rect,
        startAngle,
        segmentAngle,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity(0.35),
      );

      final textAngle = startAngle + segmentAngle / 2;
      canvas.save();
      canvas.translate(
        center.dx + cos(textAngle) * radius * 0.62,
        center.dy + sin(textAngle) * radius * 0.62,
      );
      canvas.rotate(textAngle + pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      );
      tp.layout(maxWidth: radius * 0.75);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => true;
}
