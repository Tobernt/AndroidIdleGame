import 'package:flutter/material.dart';
import '../../features/factions/faction_service.dart';
import '../../features/prestige/prestige_service.dart';
import '../../features/achievements/achievement_service.dart';
import 'hero_screen.dart';

class FactionScreen extends StatefulWidget {
  final FactionManager manager;
  final VoidCallback? onConfirm;
  final bool hideBack;

  // Add optional services to enable debug unlocking
  final PrestigeService? prestigeService;
  final AchievementService? achievementService;

  const FactionScreen({
    super.key,
    required this.manager,
    this.onConfirm,
    this.hideBack = false,
    this.prestigeService,
    this.achievementService,
  });

  @override
  State<FactionScreen> createState() => _FactionScreenState();
}

class _FactionScreenState extends State<FactionScreen> {
  @override
  Widget build(BuildContext context) {
    final factions = widget.manager.allFactions.where((f) => f.unlocked).toList();
    final hasSelected = widget.manager.selected.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🛡 Choose Your Faction'),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: !widget.hideBack,
      ),
      body: Column(
        children: [
          if (factions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No factions unlocked yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: factions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final faction = factions[i];
                  final isSelected = faction.isSelected;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.manager.selectOnly(faction.id);
                        widget.manager.selectedFactionId = faction.id;
                      });
                    },
                    child: Card(
                      color: isSelected ? Colors.blueGrey[700] : Colors.grey[850],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faction.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              faction.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '✔️ Selected',
                                style: TextStyle(color: Colors.lightGreenAccent),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (hasSelected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HeroScreen(),
                    ),
                  );
                  widget.onConfirm?.call();
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Proceed", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextButton(
              onPressed: () {
                debugUnlockEverything();
                setState(() {});
              },
              child: const Text(
                "Debug: Unlock All",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void debugUnlockEverything() {
    widget.manager.unlockAllFactions();

    widget.achievementService?.unlockAllAchievements();
    widget.prestigeService?.maxAllSkills();

    debugPrint("🧪 Debug: All factions, achievements, and prestige skills unlocked.");
  }
}
