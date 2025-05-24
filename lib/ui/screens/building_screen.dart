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
              final finalCost = gameManager.buildingService.getFinalCost(
                b, state, gameManager.modifierManager,
              );

              final maxAffordable = calculateMaxAffordable(
                finalCost,
                state.resourceAmounts,
                b.level,
              );

              final oneCost = calculateTotalCost(finalCost, 1, b.level);
              final fiveCost = calculateTotalCost(finalCost, min(5, maxAffordable), b.level);
              final maxCost = calculateTotalCost(finalCost, maxAffordable, b.level);

              void buyMultiple(int count) {
                for (int i = 0; i < count; i++) {
                  final scaledCost = finalCost.map(
                        (key, value) => MapEntry(key, value * pow(1.15, b.level)),
                  );
                  if (state.canAfford(scaledCost)) {
                    gameManager.buildingService.buy(b, state, gameManager.modifierManager);
                  } else {
                    break;
                  }
                }
                gameManager.notifyListeners();
              }

              final outputStr = b.outputPerSecond().entries
                  .map((e) => '${e.key}: ${formatBigDecimalSmart(BigDecimal.parse(e.value.toString()))}')
                  .join(', ');

              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(
                    '${b.name} (Lv ${b.level})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        child: Text('Next: ${formatCost(oneCost)}',
                            style: const TextStyle(color: Colors.orangeAccent)),
                      ),
                      Text('5x: ${formatCost(fiveCost)}',
                          style: const TextStyle(color: Colors.orangeAccent)),
                      Text('Max ($maxAffordable): ${formatCost(maxCost)}',
                          style: const TextStyle(color: Colors.orangeAccent)),
                      if (outputStr.isNotEmpty)
                        Text('Output: $outputStr/s',
                            style: const TextStyle(color: Colors.lightGreen)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: state.canAfford(oneCost)
                                ? () => buyMultiple(1)
                                : null,
                            child: const Text('Buy 1x'),
                          ),
                          ElevatedButton(
                            onPressed: maxAffordable >= 5
                                ? () => buyMultiple(5)
                                : null,
                            child: const Text('Buy 5x'),
                          ),
                          ElevatedButton(
                            onPressed: maxAffordable > 0
                                ? () => buyMultiple(maxAffordable)
                                : null,
                            child: Text('Buy Max ($maxAffordable)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int calculateMaxAffordable(Map<String, double> baseCost, Map<String, double> available, int currentLevel) {
    final resources = Map<String, double>.from(available);
    int count = 0;

    while (true) {
      final scaledCost = baseCost.map(
            (key, value) => MapEntry(key, value * pow(1.15, currentLevel + count)),
      );

      if (scaledCost.entries.any((e) => resources[e.key]! < e.value)) {
        break;
      }

      for (final entry in scaledCost.entries) {
        resources[entry.key] = resources[entry.key]! - entry.value;
      }

      count++;
    }

    return count;
  }

  Map<String, double> calculateTotalCost(Map<String, double> baseCost, int levelsToBuy, int baseLevel) {
    final Map<String, double> totalCost = {};
    for (int i = 0; i < levelsToBuy; i++) {
      final levelCost = baseCost.map(
            (key, value) => MapEntry(key, value * pow(1.15, baseLevel + i)),
      );
      for (final entry in levelCost.entries) {
        totalCost[entry.key] = (totalCost[entry.key] ?? 0) + entry.value;
      }
    }
    return totalCost;
  }

  String formatCost(Map<String, double> cost) {
    return cost.entries
        .map((e) =>
    '${e.key}: ${formatBigDecimalSmart(BigDecimal.parse(e.value.toString()))}')
        .join(', ');
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
