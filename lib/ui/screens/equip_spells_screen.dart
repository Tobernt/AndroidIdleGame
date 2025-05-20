import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import '../../features/spells/spell.dart';

class EquipSpellsScreen extends StatefulWidget {
  final GameManager gameManager;

  const EquipSpellsScreen({super.key, required this.gameManager});

  @override
  State<EquipSpellsScreen> createState() => _EquipSpellsScreenState();
}

class _EquipSpellsScreenState extends State<EquipSpellsScreen> {
  late List<Spell> equipped;
  int get maxSpells => widget.gameManager.prestigeService.maxEquippedSpells;

  @override
  void initState() {
    super.initState();
    equipped = List.from(widget.gameManager.spellService.equippedSpells);
  }

  void _updateEquippedSpells() {
    widget.gameManager.spellService.equippedSpells
      ..clear()
      ..addAll(equipped);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.gameManager.spellService,
      builder: (_, __) {
        final selectedFactionIds =
        widget.gameManager.factionManager.selected.map((f) => f.id).toSet();

        final availableSpells = widget.gameManager.spellService.allSpells.where((spell) {
          return spell.unlocked && selectedFactionIds.contains(spell.faction);
        }).toList();

        // Group spells by tier
        final tierGroups = <int, List<Spell>>{};
        for (var spell in availableSpells) {
          tierGroups.putIfAbsent(spell.tier, () => []).add(spell);
        }

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(5, (tierIndex) {
                final tier = tierIndex + 1;
                final tierSpells = tierGroups[tier] ?? [];

                if (tierSpells.isEmpty) return const SizedBox.shrink();

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
                    Center(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: tierSpells.map((spell) {
                          final isEquipped = equipped.contains(spell);
                          final canEquip = equipped.length < maxSpells || isEquipped;

                          return SizedBox(
                            width: MediaQuery.of(context).size.width / 3 - 32,
                            child: Card(
                              color: isEquipped ? Colors.blueGrey[700] : Colors.grey[850],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      spell.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'CD: ${spell.cooldown.inSeconds}s\n${spell.costs.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}').join(', ')}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    isEquipped
                                        ? IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          equipped.remove(spell);
                                          _updateEquippedSpells();
                                        });
                                      },
                                    )
                                        : canEquip
                                        ? IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                                      onPressed: () {
                                        setState(() {
                                          equipped.add(spell);
                                          _updateEquippedSpells();
                                        });
                                      },
                                    )
                                        : const Text('Full', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}