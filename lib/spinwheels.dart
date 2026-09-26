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
        ? List<String>.from(widget.entries!)
        : [
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
        setState(() {
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
        HapticFeedback.selectionClick();
      }
    });

    _currentAngle = anim;
    _spinCtrl.forward();
  }

  void _reset() {
    setState(() {
      if (_winnerIndex >= 0 && _winnerIndex < _labels.length) {
        _labels.removeAt(_winnerIndex);
      }
      _revealed = false;
    });
    _spinCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final angle = _currentAngle?.value ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0620),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // พื้นหลัง Gradient เต็มหน้าจอ 100% ไร้เส้นกรอบตัด
            Positioned.fill(
              child: Container(
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
            ),
            // เอฟเฟกต์โบเก้ระยิบระยับเคลื่อนไหวเต็มจอ
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _idleCtrl,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _SpinWheelBokehPainter(_idleCtrl.value),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;
                  final screenH = constraints.maxHeight;

                  // คำนวณขนาดวงล้อให้ใหญ่ขึ้นและ responsive ตามหน้าจอ
                  final maxWheel = min(screenW * 0.92, screenH * 0.60);
                  final wheelSize = maxWheel.clamp(300.0, 700.0);

                  return Stack(
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
                      Center(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (r) => const LinearGradient(
                                    colors: [Color(0xFFFFE066), Color(0xFFFF9F45)],
                                  ).createShader(r),
                                  child: Text(
                                    '🎡 วงล้อนำโชค',
                                    style: TextStyle(
                                      fontSize: (screenW * 0.05).clamp(24.0, 36.0),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: wheelSize,
                                  height: wheelSize,
                                  child: _buildWheelArea(angle, wheelSize),
                                ),
                                const SizedBox(height: 24),
                                _buildControls(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelArea(double angle, double wheelSize) {
    final innerWheelSize = wheelSize * 0.88;
    final lightRadius = wheelSize * 0.455;
    final lightCount = (wheelSize > 440) ? 20 : 16;
    final pinSize = (wheelSize * 0.15).clamp(46.0, 72.0);
    final arrowWidth = (wheelSize * 0.11).clamp(34.0, 52.0);
    final arrowHeight = (wheelSize * 0.12).clamp(38.0, 58.0);

    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, _) {
        final glow = 0.35 + sin(_idleCtrl.value * 2 * pi) * 0.1;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // แสงเรืองวงกลมนุ่มนวล ไร้ขอบตัดสี่เหลี่ยม
            Container(
              width: wheelSize * 1.15,
              height: wheelSize * 1.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withValues(alpha: glow * 0.45),
                    Colors.purpleAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            Transform.rotate(
              angle: angle,
              child: Container(
                width: innerWheelSize,
                height: innerWheelSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: (wheelSize * 0.012).clamp(3.5, 6.0),
                  ),
                ),
                child: ClipOval(
                  child: CustomPaint(
                    painter: _WheelPainter(labels: _labels, colors: palette),
                  ),
                ),
              ),
            ),
            ...List.generate(lightCount, (i) {
              final a = (i / lightCount) * 2 * pi;
              final dotSize = (wheelSize * 0.025).clamp(8.0, 14.0);
              return Transform.translate(
                offset: Offset(cos(a) * lightRadius, sin(a) * lightRadius),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amberAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              width: pinSize,
              height: pinSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.white, Color(0xFFDDDDDD)],
                ),
                border: Border.all(color: Colors.black26, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.star,
                color: const Color(0xFFC9184A),
                size: (pinSize * 0.45).clamp(20.0, 32.0),
              ),
            ),
            Positioned(
              top: -(arrowHeight * 0.12),
              child: _PointerArrow(size: Size(arrowWidth, arrowHeight)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    if (_labels.isEmpty && !_revealed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'หมดรายการสุ่มแล้ว',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

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
                  color: Colors.orangeAccent.withValues(alpha: 0.6),
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
                  (_winnerIndex >= 0 && _winnerIndex < _labels.length)
                      ? _labels[_winnerIndex]
                      : '',
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
  final Size size;
  const _PointerArrow({this.size = const Size(36, 40)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: size, painter: _ArrowPainter());
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
    if (labels.isEmpty) return;
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
          ..color = Colors.white.withValues(alpha: 0.35),
      );

      // จัดเรียงข้อความตามแนวช่องสีแต่ละช่อง (Radial / Spoke Alignment)
      final midAngle = startAngle + segmentAngle / 2;
      canvas.save();
      // ย้ายพิกัดไปที่ศูนย์กลางวงล้อ
      canvas.translate(center.dx, center.dy);
      // หมุนตามแนวองศาของช่องสีนั้น
      canvas.rotate(midAngle);

      // คำนวณขนาดฟอนต์ให้สมส่วนกับความกว้างของช่องสีและรัศมีวงล้อ
      final midR = radius * 0.58;
      final chord = 2 * midR * sin(segmentAngle / 2);
      final fontSize = (chord * 0.35).clamp(8.5, (radius * 0.08).clamp(11.0, 16.0));

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );

      final availableLength = radius * 0.56;
      tp.layout(maxWidth: availableLength);

      // วางข้อความทอดตัวไปตามแนวรัศมี (แกน X ชี้ออกจากศูนย์กลางไปขอบนอก)
      final startX = radius * 0.28 + (availableLength - tp.width) / 2;
      tp.paint(canvas, Offset(startX, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.colors != colors;
}

/// -------------------- เอฟเฟกต์อนุภาคพื้นหลัง --------------------
class _SpinWheelBokehPainter extends CustomPainter {
  final double t;
  _SpinWheelBokehPainter(this.t);
  final List<Offset> _seeds = List.generate(22, (i) {
    final r = Random(i * 97 + 13);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final dy = (s.dy + t * 0.04 * (i.isEven ? 1 : -1)) % 1.0;
      final radius = 2.0 + (i % 4) * 2.0;
      canvas.drawCircle(
        Offset(s.dx * size.width, dy * size.height),
        radius,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.04 + 0.03 * (i % 3),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpinWheelBokehPainter oldDelegate) => true;
}
