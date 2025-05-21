import 'dart:async';
import 'package:flutter/material.dart';
import 'package:big_decimal/big_decimal.dart';
import '../../core/game_manager.dart';
import 'dart:math';

class ConquestScreen extends StatefulWidget {
  final GameManager gameManager;

  const ConquestScreen({super.key, required this.gameManager});

  @override
  State<ConquestScreen> createState() => _ConquestScreenState();
}

class _ConquestScreenState extends State<ConquestScreen> {
  late Duration timeUntilNextStruggle;
  Timer? _updateTimer;
  final Map<String, BigDecimal> requiredMightPerFaction = {};

  @override
  void initState() {
    super.initState();
    widget.gameManager.conquestManager.checkFactionAnnihilation();
    _updateTimers();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimers());
  }

  void _updateTimers() {
    final runStart = widget.gameManager.conquestManager.runStartTime;
    final now = DateTime.now();
    final elapsed = now.difference(runStart);
    final totalSeconds = elapsed.inSeconds;
    final nextRoundIn = const Duration(hours: 8).inSeconds -
        (totalSeconds % const Duration(hours: 8).inSeconds);

    final conquest = widget.gameManager.conquestManager;

    setState(() {
      timeUntilNextStruggle = Duration(seconds: nextRoundIn);
      for (var faction in conquest.factionManager.allFactions) {
        requiredMightPerFaction[faction.id] =
            BigDecimal.parse(conquest.mightRequiredForFaction(faction.id).toString());
      }
    });
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String formatBigDecimal(BigDecimal value) {
    final doubleVal = value.toDouble();
    if (doubleVal == 0.0) return '0';
    final exponent = (log(doubleVal.abs()) / log(10)).floor();

    if (exponent >= 6) {
      final scaled = doubleVal / BigInt.from(10).pow(exponent).toDouble();
      return '${scaled.toStringAsFixed(2)}e$exponent';
    } else {
      return doubleVal.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conquest = widget.gameManager.conquestManager;
    final currentMight = BigDecimal.parse(conquest.currentMight.toString());
    final canConquer = conquest.conquestUnlocked;

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
              'Your Might: ${formatBigDecimal(currentMight)}',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Next power struggle in: ${formatDuration(timeUntilNextStruggle)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
              'Factions in Play:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: conquest.factionManager.allFactions.map((faction) {
                  final isConquered = conquest.conqueredFactions.contains(faction.id);
                  final isDestroyed = conquest.destroyedFactions.contains(faction.id);
                  final isEligible = conquest.conquerableFactions.contains(faction.id);
                  final requiredMight = requiredMightPerFaction[faction.id] ?? BigDecimal.zero;

                  return Card(
                    color: isConquered
                        ? Colors.green[800]
                        : isDestroyed
                        ? Colors.red[900]
                        : isEligible
                        ? Colors.grey[850]
                        : Colors.grey[900],
                    child: ListTile(
                      title: Text(
                        faction.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(faction.description, style: const TextStyle(color: Colors.white70)),
                          if (!isConquered && !isDestroyed)
                            Text(
                              'Required Might: ${formatBigDecimal(requiredMight)}',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                            ),
                          if (isDestroyed)
                            const Text(
                              '❌ This faction was annihilated.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: isConquered
                          ? const Icon(Icons.check, color: Colors.lightGreenAccent)
                          : isDestroyed
                          ? null
                          : isEligible
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: (canConquer &&
                                conquest.canAddMoreFactions() &&
                                currentMight >= requiredMight)
                                ? () {
                              final success =
                              conquest.tryConquer(faction.id);
                              if (success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      '${faction.name} conquered!'),
                                  backgroundColor: Colors.green,
                                ));
                                setState(() {});
                              }
                            }
                                : null,
                            child: const Text('Conquer'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (canConquer &&
                                currentMight >= requiredMight)
                                ? () {
                              conquest.destroyedFactions
                                  .add(faction.id);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    '${faction.name} annihilated!'),
                                backgroundColor: Colors.red,
                              ));
                              setState(() {});
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                            ),
                            child: const Text('Annihilate'),
                          ),
                        ],
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
