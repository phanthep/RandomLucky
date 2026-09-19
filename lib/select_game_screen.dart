import 'package:flutter/material.dart';
import 'package:gacha1/gacha.dart';
import 'package:gacha1/spinwheels.dart';

class SelectGameScreen extends StatelessWidget {
  const SelectGameScreen({super.key});
  final participantsList = const [
    {'full_name': 'John Doe'},
    {'full_name': 'Jane Smith'},
    {'full_name': 'Alice Johnson'},
    {'full_name': 'Bob Brown'},
    /*{'full_name': 'Charlie Davis'},
    {'full_name': 'Emily Wilson'},
    {'full_name': 'Frank Miller'},
    {'full_name': 'Grace Lee'},
    {'full_name': 'Henry Clark'},
    {'full_name': 'Isabella Lewis'},
    {'full_name': 'Jack Walker'},
    {'full_name': 'Katherine Hall'},
    {'full_name': 'Liam Allen'},
    {'full_name': 'Mia Young'},
    {'full_name': 'Noah King'},
    {'full_name': 'Olivia Scott'},
    {'full_name': 'Paul Adams'},
    {'full_name': 'Quinn Baker'},
    {'full_name': 'Ryan Nelson'},
    {'full_name': 'Sophia Carter'},*/
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF1B1036), Color(0xFF3A1F63), Color(0xFF0E0620)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFFE066), Color(0xFFFF9F45)],
                  ).createShader(r),
                  child: const Text('เลือกรูปแบบการสุ่ม',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text('เลือกเกมที่ต้องการใช้จับรางวัล',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _GameCard(
                      emoji: '🎰',
                      title: 'ตู้กาชาปอง',
                      subtitle: 'สุ่มทีละคน\nลุ้นแบบเปิดแคปซูล',
                      colors: const [Color(0xFFFF4D6D), Color(0xFFC9184A)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GachaScreen(entries: participantsList.map((p) => p['full_name'] as String).toList())),
                      ),
                    ),
                    _GameCard(
                      emoji: '🎡',
                      title: 'วงล้อนำโชค',
                      subtitle: 'หมุนวงล้อ\nดูผลแบบเรียลไทม์',
                      colors: const [Color(0xFF4D96FF), Color(0xFF2E5FCC)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SpinWheelScreen(entries: participantsList.map((p) => p['full_name'] as String).toList(),)),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            top: 12, left: 12,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.colors, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 150, height: 190,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(color: colors.last.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}