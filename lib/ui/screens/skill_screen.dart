import 'package:flutter/material.dart';
import '../../features/skill_tree/skill.dart';
import '../../features/skill_tree/skill_manager.dart';
import '../../core/game_state.dart';

class SkillScreen extends StatefulWidget {
  final SkillManager manager;
  final GameState state;
  final List<String> selectedFactions; // 👈 add this

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

    // Group by tier only unlocked or unlockable
    final selectedFactionIds = widget.selectedFactions;

    for (Skill skill in widget.manager.allSkills) {
      if (skill.available && selectedFactionIds.contains(skill.faction)) {
        skillsByTier.putIfAbsent(skill.tier, () => []).add(skill);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Skill Tree')),
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
                      child: Card(
                        color: skill.unlocked ? Colors.green.shade700 : Colors.grey.shade900,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
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
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              skill.unlocked
                                  ? const Icon(Icons.check, color: Colors.lightGreenAccent)
                                  : ElevatedButton(
                                onPressed: () {
                                  final success = widget.manager.unlock(skill, widget.state);
                                  if (success) setState(() {});
                                },
                                child: Text('Unlock (${skill.cost})'),
                              ),
                            ],
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
}
