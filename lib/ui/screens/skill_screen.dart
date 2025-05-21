import 'package:flutter/material.dart';
import '../../features/skill_tree/skill.dart';
import '../../features/skill_tree/skill_manager.dart';
import '../../core/game_state.dart';

class SkillScreen extends StatefulWidget {
  final SkillManager manager;
  final GameState state;
  final List<String> selectedFactions;

  const SkillScreen({
    super.key,
    required this.manager,
    required this.state,
    required this.selectedFactions,
  });

  @override
  State<SkillScreen> createState() => _SkillScreenState();
}

class _SkillScreenState extends State<SkillScreen> {
  @override
  Widget build(BuildContext context) {
    final skillsByTier = <int, List<Skill>>{};

    for (Skill skill in widget.manager.allSkills) {
      if (skill.available && widget.selectedFactions.contains(skill.faction)) {
        skillsByTier.putIfAbsent(skill.tier, () => []).add(skill);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Skill Tree'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Skill Points: ${widget.manager.prestigeService.availableSkillPoints}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(5, (tierIndex) {
            final tier = tierIndex + 1;
            final tierSkills = skillsByTier[tier] ?? [];

            if (tierSkills.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tier $tier',
                    style: const TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: tierSkills.map((skill) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width / 3 - 32,
                      child: Material(
                        color: skill.unlocked
                            ? Colors.green.shade700
                            : Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (!skill.unlocked &&
                                widget.manager.prestigeService.availableSkillPoints > 0) {
                              _confirmUnlock(skill);
                            }
                          },
                          splashColor: Colors.greenAccent.withAlpha((0.3 * 255).toInt()),
                          highlightColor: Colors.white.withAlpha((0.05 * 255).toInt()),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  skill.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  skill.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _confirmUnlock(Skill skill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Unlock Skill?', style: TextStyle(color: Colors.amber)),
        content: Text(
          'Do you want to unlock "${skill.name}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final success = widget.manager.unlock(skill, widget.state);
              if (success) setState(() {});
            },
            child: const Text('Unlock', style: TextStyle(color: Colors.lightGreenAccent)),
          ),
        ],
      ),
    );
  }
}
