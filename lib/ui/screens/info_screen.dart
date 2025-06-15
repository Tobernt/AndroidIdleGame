import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('\uD83D\uDCD6 How to Play'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Idle Realms is an incremental game where your kingdom grows over time.\n\n'
          '- Tap anywhere to gain gold.\n'
          '- Spend gold on buildings to produce resources automatically.\n'
          '- Unlock heroes, spells and skills to boost production.\n'
          '- Prestige to earn points for permanent upgrades.\n\n'
          'Grow powerful enough to conquer every faction!',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
