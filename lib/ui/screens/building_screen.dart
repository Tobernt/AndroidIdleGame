import 'package:flutter/material.dart';
import '../../core/game_manager.dart';

class BuildingScreen extends StatelessWidget {
  final GameManager gameManager;

  const BuildingScreen({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    // 🔁 Rebuild when faction selection changes
    return AnimatedBuilder(
      animation: gameManager.factionManager,
      builder: (context, _) {
        final state = gameManager.state;
        final selectedFactions = gameManager.factionManager.getSelectedFactionIds();
        final buildings =
        gameManager.buildingService.getBuildingsForFactions(selectedFactions);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('🏗 Buildings'),
            backgroundColor: Colors.black,
          ),
          body: buildings.isEmpty
              ? const Center(
            child: Text(
              'No buildings available.\nSelect a faction to see buildings.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: buildings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final b = buildings[i];

              final costStr = b.currentCost(state).entries
                  .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}')
                  .join(', ');

              final outputStr = b.outputPerSecond().entries
                  .map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}')
                  .join(', ');

              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(
                    '${b.name} (Lv ${b.level})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Cost: $costStr\nOutput: $outputStr/s',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      gameManager.buyBuilding(b);
                    },
                    child: const Text('Buy'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
