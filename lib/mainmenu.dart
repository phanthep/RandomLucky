import 'package:flutter/material.dart';
import 'package:gacha1/gacha.dart';
import 'package:gacha1/spinwheels.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GachaApp()),
              );
          },
          child: const Text('Go to Gacha'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SpinWheelScreen()),
            );
          },
          child: const Text('Go to Wheel of Fortune'),
        )
        ]
      ),
    ),
    );
  }
}