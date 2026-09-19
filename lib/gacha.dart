import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:gacha1/sfxservice.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

class GachaApp extends StatelessWidget {
  const GachaApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(debugShowCheckedModeBanner: false, home: GachaScreen());
}

enum GachaState { idle, shaking, dropping, cracking, revealed }

class GachaScreen extends StatefulWidget {
  final List<String>? entries;
  const GachaScreen({super.key, this.entries});
  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with TickerProviderStateMixin {
  late final List<String> _participants;

  final List<Color> palette = const [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFB983FF),
    Color(0xFFFF9F45),
  ];

  late final List<Offset> _domePos;
  late final List<Color> _domeColors;
  late final List<double> _domePhase;
  late final List<Offset> _sparkleDirs;

  late final AnimationController _idleCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _dropCtrl;
  late final AnimationController _crackCtrl;
  late final ConfettiController _confettiCtrl;

  GachaState _state = GachaState.idle;
  Color _winnerColor = Colors.pink;
  int _winnerIndex = 0;

  @override
  void initState() {
    super.initState();
    _participants = (widget.entries != null && widget.entries!.isNotEmpty)
        ? widget.entries!
        : const [
            '🏆 ทองคำแท้ 1 บาท',
            '💵 บัตรเงินสด 500.-',
            '🧸 ตุ๊กตาลิมิเต็ด',
            '🎟 คูปองส่วนลด 20%',
            '👕 เสื้อยืดพรีเมียม',
          ];
    final rnd = Random(11);
    _domePos = List.generate(14, (i) {
      final a = rnd.nextDouble() * 2 * pi;
      final r = 0.32 + rnd.nextDouble() * 0.5;
      return Offset(cos(a) * r, sin(a) * r);
    });
    _domeColors = List.generate(
      14,
      (i) => palette[rnd.nextInt(palette.length)],
    );
    _domePhase = List.generate(14, (i) => rnd.nextDouble() * 2 * pi);
    _sparkleDirs = List.generate(10, (i) {
      final a = rnd.nextDouble() * 2 * pi;
      return Offset(cos(a), sin(a));
    });

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _crackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _shakeCtrl.dispose();
    _dropCtrl.dispose();
    _crackCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _playGacha() async {
    if (_state != GachaState.idle) return;
    final rnd = Random();
    final chosen = rnd.nextInt(_participants.length);
    _winnerColor = palette[rnd.nextInt(palette.length)];

    SfxService.click();
    HapticFeedback.lightImpact();

    setState(() {
      _winnerIndex = chosen;
      _state = GachaState.shaking;});
    SfxService.shake();
    await _shakeCtrl.forward(from: 0);

    setState(() => _state = GachaState.dropping);
    SfxService.drop();
    await _dropCtrl.forward(from: 0);

    setState(() => _state = GachaState.cracking);
    await _crackCtrl.forward(from: 0);

    setState(() => _state = GachaState.revealed);
    HapticFeedback.heavyImpact();
    SfxService.reveal();
    _confettiCtrl.play();
  }

  void _reset() {
    _shakeCtrl.reset();
    _dropCtrl.reset();
    _crackCtrl.reset();
    setState(() {
      if (_winnerIndex >= 0) {
        _participants.removeAt(_winnerIndex);
        //await SupabaseService.markWinner(participantId: winner['id'], eventId: widget.eventId, prize: "วงล้อนำโชค");
      }
      _state = GachaState.idle;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
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
                        '🎰 GACHA MACHINE',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(height: 380, width: 300, child: _buildMachine()),
                    const SizedBox(height: 26),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _BokehPainter(_idleCtrl.value),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B1036), Color(0xFF3A1F63), Color(0xFF0E0620)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMachine() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleCtrl,
        _shakeCtrl,
        _dropCtrl,
        _crackCtrl,
      ]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildGroundShadow(),
            Align(
              alignment: const Alignment(0, -0.35),
              child: _buildDome(),
            ), // ⬅️ ดันโดมขึ้นบน
            Align(
              alignment: const Alignment(0, 0.75),
              child: _buildBase(),
            ), // ⬅️ ดันฐานลงล่าง
            if (_state == GachaState.dropping) _buildFallingCapsule(),
            if (_state == GachaState.cracking || _state == GachaState.revealed)
              Transform.translate(
                offset: const Offset(0, 95),
                child: _buildCrackOpen(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGroundShadow() {
    double scale = 1.0, opacity = 0.35;
    if (_state == GachaState.dropping) {
      final t = _dropCtrl.value;
      scale = _lerp(0.6, 1.3, t);
      opacity = _lerp(0.15, 0.5, t);
    } else if (_state == GachaState.cracking || _state == GachaState.revealed) {
      scale = 1.3;
      opacity = 0.5;
    }
    return Positioned(
      bottom: 6,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 170,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDome() {
    double opacity = 1;
    if (_state != GachaState.idle && _state != GachaState.shaking) {
      opacity = (1 - _dropCtrl.value).clamp(0.0, 1.0);
    }
    final decay = 1 - _shakeCtrl.value;
    final dx = _state == GachaState.shaking
        ? sin(_shakeCtrl.value * pi * 16) * 9 * decay
        : 0.0;
    final rot = _state == GachaState.shaking
        ? sin(_shakeCtrl.value * pi * 16) * 0.06 * decay
        : 0.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: rot,
          child: Container(
            width: 230,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(115),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.45),
                  blurRadius: 35,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(115),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.6),
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.lightBlueAccent.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                  ...List.generate(_domePos.length, (i) {
                    final bob =
                        sin(_idleCtrl.value * 2 * pi + _domePhase[i]) * 3;
                    final pos = _domePos[i];
                    return Align(
                      alignment: Alignment(pos.dx, pos.dy),
                      child: Transform.translate(
                        offset: Offset(0, bob),
                        child: _Capsule3D(size: 32, color: _domeColors[i]),
                      ),
                    );
                  }),
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(20, -40),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          width: 55,
                          height: 210,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBase() {
    final spinning = _state == GachaState.shaking;
    final ledColor = switch (_state) {
      GachaState.idle => Colors.greenAccent,
      GachaState.shaking => Colors.yellowAccent,
      GachaState.dropping => Colors.orangeAccent,
      GachaState.cracking || GachaState.revealed => Colors.redAccent,
    };
    return Container(
      width: 250,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B87), Color(0xFFC9184A), Color(0xFF8C0F35)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.white, Color(0xFFDDDDDD)],
                ),
                border: Border.all(color: Colors.black26, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFFC9184A),
                size: 20,
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Transform.rotate(
              angle: spinning ? _shakeCtrl.value * 6 * pi : 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border.all(color: Colors.black26, width: 2),
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.black45),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ledColor,
                boxShadow: [
                  BoxShadow(
                    color: ledColor.withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallingCapsule() {
    final raw = Curves.easeIn.transform(_dropCtrl.value);
    final dy = _lerp(50, 100, raw); // ⬅️ เปลี่ยนจาก _lerp(-30, 95, raw)
    double squash = 0;
    if (raw > 0.85) squash = sin((raw - 0.85) / 0.15 * pi) * 0.28;
    return Opacity(
      opacity: raw.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scaleX: 1 + squash,
          scaleY: 1 - squash,
          child: _Capsule3D(size: 72, color: _winnerColor),
        ),
      ),
    );
  }

  Widget _buildCrackOpen() {
    final t = _crackCtrl.value;
    final shellOpacity = (1 - t).clamp(0.0, 1.0);
    final cardOpacity = t.clamp(0.0, 1.0);
    final cardScale = _lerp(0.4, 1.0, Curves.easeOutBack.transform(t));

    return Stack(
      alignment: Alignment.center,
      children: [
        ..._sparkleDirs.map((dir) {
          final dist = _lerp(0, 60, t);
          final op = (1 - t).clamp(0.0, 1.0) * shellOpacity;
          return Opacity(
            opacity: op,
            child: Transform.translate(
              offset: Offset(dir.dx * dist, dir.dy * dist),
              child: const Icon(
                Icons.star,
                color: Colors.amberAccent,
                size: 14,
              ),
            ),
          );
        }),
        Opacity(
          opacity: cardOpacity,
          child: Transform.scale(
            scale: cardScale,
            child: Container(
              width: 210,
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF3C4),
                    Color(0xFFFFD166),
                    Color(0xFFFFA45C),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withValues(alpha: 0.6),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9184A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🎉 ยินดีด้วย 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _participants[_winnerIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Opacity(
          opacity: shellOpacity,
          child: Transform.translate(
            offset: Offset(0, _lerp(0, -70, t)),
            child: Transform.rotate(
              angle: -t * 0.7,
              child: _CapsuleHalf(color: _winnerColor, isTop: true, size: 72),
            ),
          ),
        ),
        Opacity(
          opacity: shellOpacity,
          child: Transform.translate(
            offset: Offset(0, _lerp(0, 70, t)),
            child: Transform.rotate(
              angle: t * 0.7,
              child: _CapsuleHalf(color: _winnerColor, isTop: false, size: 72),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final isBusy =
        _state == GachaState.shaking ||
        _state == GachaState.dropping ||
        _state == GachaState.cracking;
    if (_state == GachaState.revealed) {
      return ElevatedButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.replay),
        label: const Text(
          'เล่นอีกครั้ง',
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
      );
    }
    return ElevatedButton(
      onPressed: isBusy ? null : _playGacha,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4D6D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
      ),
      child: Text(
        isBusy ? 'กำลังสุ่ม...' : '🎲 หมุนกาชาปอง',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ---------- Painters & sub-widgets ----------

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

class _Capsule3D extends StatelessWidget {
  final double size;
  final Color color;
  const _Capsule3D({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _Capsule3DPainter(color)),
  );
}

class _Capsule3DPainter extends CustomPainter {
  final Color color;
  _Capsule3DPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE2E2E2)],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawLine(
      Offset(1.5, size.height / 2),
      Offset(size.width - 1.5, size.height / 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..strokeWidth = 1.3,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.10,
        size.width * 0.30,
        size.height * 0.18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.64,
        size.height * 0.55,
        size.width * 0.12,
        size.height * 0.09,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _Capsule3DPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CapsuleHalf extends StatelessWidget {
  final double size;
  final Color color;
  final bool isTop;
  const _CapsuleHalf({
    required this.size,
    required this.color,
    required this.isTop,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size / 2,
    child: CustomPaint(painter: _CapsuleHalfPainter(color, isTop)),
  );
}

class _CapsuleHalfPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  _CapsuleHalfPainter(this.color, this.isTop);
  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(
      0,
      isTop ? 0 : -size.height,
      size.width,
      size.height * 2,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawOval(
      fullRect,
      Paint()
        ..shader = isTop
            ? RadialGradient(
                colors: [Color.lerp(color, Colors.white, 0.4)!, color],
              ).createShader(fullRect)
            : const LinearGradient(colors: [Colors.white, Color(0xFFE0E0E0)])
                  .createShader(fullRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapsuleHalfPainter oldDelegate) => true;
}
