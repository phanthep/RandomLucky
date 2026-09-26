import 'package:flutter/material.dart';
import 'package:gacha1/mainmenu.dart';
void main() => runApp(const LuckyApp());

class LuckyApp extends StatelessWidget {

  const LuckyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gacha Machine',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const MainMenu(),
    );
  }
}