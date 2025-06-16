import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import 'game_screen.dart';
import 'faction_screen.dart';
import 'prestige_upgrade_screen.dart';
import '../../main.dart'; // Ensure formatNumber() is defined here

class PrestigeScreen extends StatelessWidget {
  final GameManager gameManager;

  const PrestigeScreen({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final prestige = gameManager.prestigeService;
    final state = gameManager.state;

    String formatDuration(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final s = d.inSeconds.remainder(60);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🌟 Prestige'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('🏆 Total Prestiges', '${state.totalPrestiges}', Colors.orangeAccent),
                    _infoRow('🎖 Prestige Points', '${prestige.availablePrestigePoints}', Colors.amberAccent),
                    _infoRow('🎯 Current Run Taps', '${state.currentRunTaps}', Colors.lightBlueAccent),
                    _infoRow('🖱️ Lifetime Taps', '${state.lifetimeTaps}', Colors.lightBlueAccent),
                    _infoRow('📈 Multiplier', 'x${prestige.prestigeMultiplier.toStringAsFixed(2)}', Colors.lightGreenAccent),
                    _infoRow('⏱ Run Time / 🕰 Total', '${formatDuration(state.currentRunTime)} / ${formatDuration(state.totalPlayTime)}', Colors.cyanAccent),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Text('📊 Resources', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
                    const SizedBox(height: 12),

// Table Headers
                    Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Resource', style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text('Current', style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Lifetime', style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),

                    ...state.resourceAmounts.keys.map((key) {
                      final current = formatNumber(state.resourceAmounts[key] ?? 0);
                      final lifetime = formatNumber(state.lifetimeResources[key] ?? 0);
                      final label = '${key[0].toUpperCase()}${key.substring(1)}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(label, style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(current, style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(lifetime, style: const TextStyle(color: Colors.white54)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

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
                  final currentGold = gameManager.state.getResource('gold');
                  if (currentGold < 100000) {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Insufficient Gold'),
                        content: const Text('You need at least 100k gold to prestige.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK')),
                        ],
                      ),
                    );
                    return;
                  }
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Confirm Prestige'),
                      content: const Text(
                        'This will reset most progress in exchange for permanent upgrades.\n\nProceed?',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Prestige')),
                      ],
                    ),
                  );

                  if (!context.mounted || confirmed != true) return;

                  prestige.prestige(gameManager.state);
                  gameManager.resetForPrestige();

                  gameManager.achievementService.evaluate(
                    state: gameManager.state,
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

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
