import 'package:flutter/material.dart';
import '../../core/game_manager.dart';

class ConquestScreen extends StatelessWidget {
  final GameManager gameManager;

  const ConquestScreen({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final conquest = gameManager.conquestManager;

    final canConquer = conquest.conquestUnlocked;
    final requiredMight = conquest.requiredMightForNext();
    final currentMight = conquest.currentMight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Conquest'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Might: ${currentMight.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
            Text(
              'Required for next conquest: ${requiredMight.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            if (!canConquer)
              const Text(
                '🔒 Conquest unlocks at prestige level 10.',
                style: TextStyle(color: Colors.redAccent),
              ),

            if (conquest.isGameCompleted)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '✅ All factions conquered. You have reached the endgame.',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              'Conquerable Factions:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: conquest.factionManager.allFactions.map((faction) {
                  final isConquered = conquest.conqueredFactions.contains(faction.id);
                  final isEligible = conquest.conquerableFactions.contains(faction.id);

                  return Card(
                    color: isConquered
                        ? Colors.green[800]
                        : isEligible
                        ? Colors.grey[850]
                        : Colors.grey[900],
                    child: ListTile(
                      title: Text(
                        faction.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        faction.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: isConquered
                          ? const Icon(Icons.check, color: Colors.lightGreenAccent)
                          : isEligible && canConquer
                          ? ElevatedButton(
                        onPressed: currentMight >= requiredMight
                            ? () {
                          final success = conquest.tryConquer(faction.id);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${faction.name} conquered!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            (context as Element).markNeedsBuild(); // refresh UI
                          }
                        }
                            : null,
                        child: const Text('Conquer'),
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
