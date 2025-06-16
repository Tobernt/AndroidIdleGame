import 'package:flutter/material.dart';
import '../../core/game_state.dart';
import '../../features/achievements/achievement_service.dart';

class AchievementScreen extends StatefulWidget {
  final AchievementService achievementService;
  final GameState gameState;
  final VoidCallback onConquestUnlocked; // ✅ Callback to notify parent

  const AchievementScreen({
    super.key,
    required this.achievementService,
    required this.gameState,
    required this.onConquestUnlocked,
  });

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  @override
  Widget build(BuildContext context) {
    final achievements = widget.achievementService.all;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🏆 Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'Unlock & Claim All (Debug)',
            onPressed: () {
              for (final a in achievements) {
                widget.achievementService.unlock(a.id, force: true);
                if (!a.isClaimed) {
                  widget.achievementService.claim(a.id, widget.gameState);
                }
              }

              if (!widget.gameState.conquestIntroShown &&
                  widget.gameState.conquestUnlocked) {
                widget.gameState.conquestIntroShown = true;
                widget.onConquestUnlocked();
                _showConquestIntro();
              }

              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!, width: 2),
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[900],
          ),
          child: GridView.builder(
            itemCount: achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final a = achievements[index];

              final iconText = a.isClaimed ? '' : a.isUnlocked ? '!' : '?';
              final borderColor = a.isClaimed
                  ? Colors.green
                  : a.isUnlocked
                  ? Colors.amber
                  : Colors.white30;
              final textColor = a.isUnlocked ? Colors.amber : Colors.white54;

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                        a.isClaimed
                            ? a.name
                            : a.isUnlocked
                            ? "Unlocked!"
                            : "Hint",
                      ),
                      content: Text(
                        a.isClaimed
                            ? a.description
                            : a.isUnlocked
                            ? "Claim this achievement reward"
                            : a.hint,
                      ),
                      actions: [
                        if (a.isUnlocked && !a.isClaimed)
                          TextButton(
                            onPressed: () {
                              final reward = a.reward;
                              widget.achievementService
                                  .claim(a.id, widget.gameState);
                              Navigator.pop(context);
                              setState(() {});

                              if (reward?.type == 'unlock_conquest' &&
                                  !widget.gameState.conquestIntroShown) {
                                widget.gameState.conquestIntroShown = true;
                                widget.onConquestUnlocked();
                                _showConquestIntro();
                              }
                            },
                            child: const Text("Claim"),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: a.isClaimed
                        ? const Icon(Icons.check,
                        size: 32, color: Colors.greenAccent)
                        : Text(
                      iconText,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showConquestIntro() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '⚔️ Conquest Unlocked!',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Text(
          "As your legend grows, rival factions grow wary.\n\n"
              "You may now challenge and **conquer** other factions.\n"
              "Each conquest grants you permanent bonuses, new spells, skills, or even the ability to assimilate them into your own empire.\n\n"
              "**Only the strongest may unify the world.**",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Begin Conquest", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
