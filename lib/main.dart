import 'package:flutter/material.dart';
import 'package:gacha1/select_game_screen.dart';
void main() => runApp(const LuckyApp());

class LuckyApp extends StatelessWidget {

  const LuckyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gacha Machine',
      theme: ThemeData(
        fontFamily: 'Roboto', // เปลี่ยนเป็นฟอนต์ที่ต้องการได้
      ),
      home: const SelectGameScreen(),
    );
  }
}