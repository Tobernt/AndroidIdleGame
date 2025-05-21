import 'dart:math';
import 'package:flutter/material.dart';
import 'package:big_decimal/big_decimal.dart';
import '../../core/game_manager.dart';

class BuildingScreen extends StatelessWidget {
  final GameManager gameManager;

  const BuildingScreen({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameManager.factionManager,
      builder: (context, _) {
        final state = gameManager.state;
        final selectedFactions = gameManager.factionManager.getSelectedFactionIds();
        final buildings = gameManager.buildingService.getBuildingsForFactions(selectedFactions);

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
                  .map((e) => '${e.key}: ${formatBigDecimalSmart(BigDecimal.parse(e.value.toString()))}')
                  .join(', ');

              final outputStr = b.outputPerSecond().entries
                  .map((e) => '${e.key}: ${formatBigDecimalSmart(BigDecimal.parse(e.value.toString()))}')
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            b.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Cost: $costStr',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                      if (outputStr.isNotEmpty)
                        Text(
                          'Output: $outputStr/s',
                          style: const TextStyle(color: Colors.lightGreen),
                        ),
                    ],
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

  String formatBigDecimalSmart(BigDecimal value) {
    if (value.intVal == BigInt.zero) return '0';

    final doubleVal = value.toDouble().abs();
    if (doubleVal < 1000) {
      return value.withScale(2, roundingMode: RoundingMode.HALF_UP).toPlainString();
    }

    final log10 = log(doubleVal);
    final exponent = (log10 / log(10)).floor();
    final scale = (exponent ~/ 3) * 3;

    final scaled = value.divide(
      BigDecimal.parse(pow(10, scale).toStringAsFixed(0)),
      scale: 3,
      roundingMode: RoundingMode.HALF_UP,
    );

    return '${scaled.toPlainString()}e$scale';
  }
}
