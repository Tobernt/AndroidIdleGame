
import 'package:flutter/material.dart';
import 'package:big_decimal/big_decimal.dart';
import 'dart:math';
import '../../core/game_manager.dart';
import 'game_screen.dart';
import 'faction_screen.dart';
import 'prestige_upgrade_screen.dart';
import '../../main.dart'; // Ensure formatNumber() is defined here

class PrestigeScreen extends StatelessWidget {
  final GameManager gameManager;

  const PrestigeScreen({super.key, required this.gameManager});

  String formatBigDecimal(BigDecimal value) {
    if (value.intVal == BigInt.zero) return '0';

    final doubleVal = value.toDouble().abs();
    final exponent = log(doubleVal) ~/ log(10);
    if (exponent >= 3) {
      final base = doubleVal / pow(10, exponent);
      return '${base.toStringAsFixed(2)}e$exponent';
    } else {
      return value.toPlainString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prestige = gameManager.prestigeService;
    final state = gameManager.state;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🌟 Prestige'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('🏆 Total Prestiges: ${state.totalPrestiges}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 20)),
              Text('🎯 Current Run Taps: ${state.currentRunTaps}',
                  style: const TextStyle(color: Colors.lightBlueAccent)),
              Text('🖱️ Lifetime Taps: ${state.lifetimeTaps}',
                  style: const TextStyle(color: Colors.lightBlueAccent)),
              const SizedBox(height: 12),

              Text(
<<<<<<< Updated upstream
                '🪙 Current Lifetime Gold: ${formatBigDecimal(BigDecimal.parse(prestige.lifetimeGold.toStringAsFixed(0)))}',
=======
                '🪙 Lifetime Gold: ${formatNumber(prestige.lifetimeGold)}',
>>>>>>> Stashed changes
                style: const TextStyle(color: Colors.amber, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text('📈 Multiplier after Prestige:',
                  style: const TextStyle(color: Colors.white70)),
              Text('x${prestige.prestigeMultiplier.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 22)),

              const SizedBox(height: 24),
              Text('🎖 Prestige Points: ${prestige.availablePrestigePoints}',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 18)),
              const SizedBox(height: 8),
              Text('🧠 Skill Points: ${prestige.availableSkillPoints} / 15',
                  style: const TextStyle(color: Colors.white70)),
              Text('🪄 Spell Slots: ${prestige.maxEquippedSpells} / 5',
                  style: const TextStyle(color: Colors.white70)),
              Text('🛡️ Faction Slots: ${prestige.maxFactions} / 3',
                  style: const TextStyle(color: Colors.white70)),

              const SizedBox(height: 28),
              const Divider(color: Colors.white30),
              const SizedBox(height: 12),

              Text('📊 Lifetime Resources:',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 16)),
              const SizedBox(height: 8),
              ...state.lifetimeResources.entries.map((e) {
<<<<<<< Updated upstream
                final value = BigDecimal.parse(e.value.toStringAsFixed(0));
                final label = '${e.key[0].toUpperCase()}${e.key.substring(1)}';
                return Text(
                  '$label: ${formatBigDecimal(value)}',
=======
                final label = '${e.key[0].toUpperCase()}${e.key.substring(1)}';
                return Text(
                  '$label: ${formatNumber(e.value)}',
>>>>>>> Stashed changes
                  style: const TextStyle(color: Colors.white),
                );
              }),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrestigeUpgradeScreen(gameManager: gameManager),
                    ),
                  );
                },
                icon: const Icon(Icons.upgrade),
                label: const Text('Spend Prestige Points'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Prestige'),
                      content: const Text(
                        'This will reset most progress in exchange for permanent upgrades.\n\nProceed?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Prestige'),
                        ),
                      ],
                    ),
                  );

                  if (!context.mounted || confirmed != true) return;

                  prestige.prestige(state);
                  gameManager.resetForPrestige();

                  gameManager.achievementService.evaluate(
                    state: state,
                    lifetimeGold: prestige.preservedLifetimeGold,
                    buildingsOwned: gameManager.buildingService.allOwnedCount,
                    tapCount: gameManager.tapCount,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrestigeUpgradeScreen(
                        gameManager: gameManager,
                        onDone: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FactionScreen(
                                manager: gameManager.factionManager,
                                onConfirm: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GameScreen(gameManager: gameManager),
                                    ),
                                  );
                                },
                                hideBack: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Prestige Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
