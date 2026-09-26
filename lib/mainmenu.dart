import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gacha1/gacha.dart';
import 'package:gacha1/spinwheels.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  List<String> _loadedEntries = [];
  String? _fileName;
  bool _isLoading = false;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  /// ฟังก์ชันเปิด File Picker โหลดไฟล์ .csv และ .txt
  Future<void> _pickAndReadFile() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.single;
      String content = '';

      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (!kIsWeb && file.path != null) {
        final f = File(file.path!);
        try {
          content = await f.readAsString(encoding: utf8);
        } catch (_) {
          final bytes = await f.readAsBytes();
          content = utf8.decode(bytes, allowMalformed: true);
        }
      }

      final parsed = _parseContent(content);

      if (parsed.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ไม่พบข้อมูลรายชื่อในไฟล์ ${file.name}'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _loadedEntries = parsed;
        _fileName = file.name;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ โหลดรายชื่อสำเร็จ ${_loadedEntries.length} รายชื่อ จาก ${file.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอ่านไฟล์: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// วิเคราะห์และแยกข้อมูลจากไฟล์ .csv หรือ .txt
  List<String> _parseContent(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final List<String> result = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.contains(',')) {
        final parts = line.split(',');
        for (var part in parts) {
          final clean = part.replaceAll('"', '').trim();
          if (clean.isNotEmpty && !_isHeader(clean)) {
            result.add(clean);
          }
        }
      } else {
        final clean = line.replaceAll('"', '').trim();
        if (clean.isNotEmpty && !_isHeader(clean)) {
          result.add(clean);
        }
      }
    }
    return result;
  }

  /// ตรวจสอบว่าเป็นหัวตารางหรือไม่
  bool _isHeader(String text) {
    final lower = text.toLowerCase();
    const headers = [
      'name',
      'names',
      'full_name',
      'fullname',
      'firstname',
      'lastname',
      'ชื่อ',
      'รายชื่อ',
      'ชื่อ-นามสกุล',
      'ลำดับ',
      'no',
      'id',
      'รางวัล',
      'item',
      'items',
    ];
    return headers.contains(lower);
  }

  /// แสดง Dialog แสดงรายชื่อที่โหลดมาทั้งหมด
  void _showEntriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF261647),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.list_alt, color: Color(0xFFFFD166)),
            const SizedBox(width: 8),
            Text(
              'รายชื่อที่โหลด (${_loadedEntries.length})',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 350,
          child: ListView.separated(
            itemCount: _loadedEntries.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            itemBuilder: (ctx, index) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFFF4D6D),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                title: Text(
                  _loadedEntries[index],
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ปิด',
              style: TextStyle(color: Color(0xFFFFD166)),
            ),
          ),
        ],
      ),
    );
  }

  /// ล้างรายการที่โหลด
  void _clearEntries() {
    setState(() {
      _loadedEntries.clear();
      _fileName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('รีเซ็ตรายชื่อเป็นค่าเริ่มต้นแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0620),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. พื้นหลัง Gradient มืดหรูหราเต็มจอ
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

            // 2. เอฟเฟกต์อนุภาคโบเก้ระยิบระยับเคลื่อนไหว
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _MainMenuBokehPainter(_bgCtrl.value),
                ),
              ),
            ),

            // 3. เนื้อหาหน้า Main Menu
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // หัวข้อพรีเมียมพร้อมประกายดาว
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD166)
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Color(0xFFFFD166),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'RANDOM LUCKY SYSTEM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD166),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFFFFE066), Color(0xFFFF9F45)],
                          ).createShader(r),
                          child: const Text(
                            '🎲LUCKY🎡CABINET🎰',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ระบบสุ่มรางวัล & วงล้อเสี่ยงโชคพรีเมียม',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.72),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ส่วนโหลดไฟล์ .csv / .txt
                        _buildFileCard(),

                        const SizedBox(height: 28),

                        // ปุ่มเข้าเกมตู้กาชาปอง
                        _buildGameButton(
                          icon: Icons.casino,
                          title: '🎰 เล่นตู้กาชาปอง',
                          subtitle: 'ตู้ (Gacha) สุ่มทีละคน ลุ้นเปิดแคปซูล',
                          gradientColors: const [
                            Color(0xFFFF4D6D),
                            Color(0xFFC9184A),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GachaApp(
                                  entries: _loadedEntries.isNotEmpty
                                      ? _loadedEntries
                                      : [
                                          '🏆 ทองคำแท้ 1 บาท',
                                          '💵 บัตรเงินสด 500.-',
                                          '🧸 ตุ๊กตาลิมิเต็ด',
                                          '🎟 คูปองส่วนลด 20%',
                                          '👕 เสื้อยืดพรีเมียม',
                                        ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ปุ่มเข้าเกมวงล้อนำโชค
                        _buildGameButton(
                          icon: Icons.track_changes,
                          title: '🎡 วงล้อนำโชค',
                          subtitle: 'วงล้อเสี่ยงโชค (Wheel of Fortune)',
                          gradientColors: const [
                            Color(0xFF4D96FF),
                            Color(0xFF2E5FCC),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpinWheelScreen(
                                  entries: _loadedEntries.isNotEmpty
                                      ? _loadedEntries
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),

                        // ส่วนเครดิตผู้พัฒนาด้านล่างสุด (Footer)
                        _buildFooter(),
                      ],
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

  /// การ์ดข้อมูลและปุ่มโหลดไฟล์
  Widget _buildFileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD166), Color(0xFFFF9F45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F45).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.file_upload_outlined,
                  color: Color(0xFF1B1036),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลรายชื่อสำหรับจับรางวัล',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _loadedEntries.isEmpty
                          ? 'ยังไม่ได้โหลดไฟล์ (ใช้ตัวอย่างเริ่มต้น)'
                          : 'ไฟล์: ${_fileName ?? "ไม่ระบุ"} (${_loadedEntries.length} รายชื่อ)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _loadedEntries.isEmpty
                            ? Colors.white54
                            : const Color(0xFF6BCB77),
                        fontWeight: _loadedEntries.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndReadFile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_open_rounded, size: 20),
                  label: Text(
                    _isLoading
                        ? 'กำลังอ่านไฟล์...'
                        : '📁 โหลดไฟล์ (.csv, .txt)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                ),
              ),
              if (_loadedEntries.isNotEmpty) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'ดูรายชื่อทั้งหมด',
                  onPressed: _showEntriesDialog,
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'ล้างข้อมูล',
                  onPressed: _clearEntries,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// ปุ่มเมนูเข้าเล่นเกม
  Widget _buildGameButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// พื้นที่แสดงชื่อผู้พัฒนาด้านล่างสุด (Developer Footer)
  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 36, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.code_rounded,
                  size: 14,
                  color: Color(0xFFFFD166),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'พัฒนาโดย',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFFFFE066), Color(0xFFFFB347)],
                ).createShader(r),
                child: const Text(
                  'นายพันธ์เทพ จิตต์การุณย์',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withValues(alpha: 0.35),
                  const Color(0xFF673AB7).withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB983FF).withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: const Text(
              'Freelance Full Stack Developer',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE1BEE7),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// เอฟเฟกต์อนุภาคโบเก้เคลื่อนไหวสำหรับหน้า Main Menu
class _MainMenuBokehPainter extends CustomPainter {
  final double t;
  _MainMenuBokehPainter(this.t);
  final List<Offset> _seeds = List.generate(24, (i) {
    final r = Random(i * 73 + 19);
    return Offset(r.nextDouble(), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final dy = (s.dy + t * 0.03 * (i.isEven ? 1 : -1)) % 1.0;
      final radius = 2.0 + (i % 4) * 1.8;
      canvas.drawCircle(
        Offset(s.dx * size.width, dy * size.height),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.035 + 0.025 * (i % 3)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MainMenuBokehPainter oldDelegate) => true;
}
