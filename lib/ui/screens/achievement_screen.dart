import 'package:flutter/material.dart';
import '../../core/game_state.dart';
import '../../features/achievements/achievement_service.dart';

class AchievementScreen extends StatefulWidget {
  final AchievementService achievementService;
  final GameState gameState;

  const AchievementScreen({
    super.key,
    required this.achievementService,
    required this.gameState,
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
        backgroundColor: Colors.black,
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
                              widget.achievementService
                                  .claim(a.id, widget.gameState);
                              setState(() {});
                              Navigator.pop(context);
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
}
