import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import '../../main.dart'; // make sure formatNumber() is defined there

class ConquestScreen extends StatefulWidget {
  final GameManager gameManager;

  const ConquestScreen({super.key, required this.gameManager});

  @override
  State<ConquestScreen> createState() => _ConquestScreenState();
}

class _ConquestScreenState extends State<ConquestScreen> {
  Timer? _updateTimer;
  final Map<String, double> requiredMightPerFaction = {};

  @override
  void initState() {
    super.initState();
    widget.gameManager.conquestManager.checkFactionAnnihilation();
    _updateTimers();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimers());
  }

  void _updateTimers() {
    final conquest = widget.gameManager.conquestManager;
    setState(() {
      for (var faction in conquest.factionManager.allFactions) {
        requiredMightPerFaction[faction.id] =
            conquest.mightRequiredForFaction(faction.id);
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conquest = widget.gameManager.conquestManager;
    final currentMight = conquest.currentMight;
    final canConquer = conquest.conquestUnlocked;
    final ownFactionId = conquest.factionManager.selectedFactionId;

    final visibleFactions = conquest.factionManager.allFactions
        .where((f) => f.id != ownFactionId)
        .toList();

    final allEliminated = visibleFactions.every((f) =>
    conquest.conqueredFactions.contains(f.id) ||
        conquest.destroyedFactions.contains(f.id));

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
              'Your Might: ${formatNumber(currentMight)}',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (!canConquer)
              const Text(
                '🔒 Conquest unlocks at prestige level 10.',
                style: TextStyle(color: Colors.redAccent),
              ),
            if (allEliminated)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '🏆 Your faction reigns supreme. All others have fallen.',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                ),
              ),
            const SizedBox(height: 20),
            if (!allEliminated) ...[
              const Text(
                'Factions in Play:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: visibleFactions.map((faction) {
                    final isConquered = conquest.conqueredFactions.contains(faction.id);
                    final isDestroyed = conquest.destroyedFactions.contains(faction.id);
                    final isEligible = conquest.conquerableFactions.contains(faction.id);
                    final requiredMight = requiredMightPerFaction[faction.id] ?? 0.0;

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
                                'Required Might: ${formatNumber(requiredMight)}',
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
                                final success = conquest.tryConquer(faction.id);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${faction.name} conquered!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState(() {});
                                  _updateTimers();
                                }
                              }
                                  : null,
                              child: const Text('Conquer'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: (canConquer && currentMight >= requiredMight)
                                  ? () {
                                conquest.destroyedFactions.add(faction.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${faction.name} annihilated!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() {});
                                _updateTimers();
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
            ]
          ],
        ),
      ),
    );
  }
}
