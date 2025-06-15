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
        final selectedFactionIds = widget.gameManager.factionManager.selected.map((f) => f.id).toSet();

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

                          final state = widget.gameManager.state;
                          final finalCooldown = spell.getFinalCooldown(state);
                          final remaining = spell.getRemainingCooldown(state);

                          final cooldownText = remaining > Duration.zero
                              ? 'Cooldown: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s'
                              : 'CD: ${finalCooldown.inSeconds}s';

                          final costText = spell.costs.entries.map((e) {
                            final finalCost = spell.getFinalCost(e.key, state);
                            return '${e.key}: ${finalCost.toStringAsFixed(0)}';
                          }).join(', ');

                          return SizedBox(
                            width: MediaQuery.of(context).size.width / 3 - 32,
                            child: Material(
                              color: isEquipped
                                  ? Colors.green.shade700
                                  : Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: (!isEquipped && canEquip)
                                    ? () => _confirmEquip(spell)
                                    : null,
                                splashColor:
                                    Colors.greenAccent.withAlpha((0.3 * 255).toInt()),
                                highlightColor:
                                    Colors.white.withAlpha((0.05 * 255).toInt()),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            spell.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isEquipped)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.lightGreenAccent,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        spell.description,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$cooldownText\n$costText',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white54, fontSize: 11),
                                      ),
                                      const SizedBox(height: 8),
                                      if (!isEquipped && !canEquip)
                                        const Text('Full',
                                            style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
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

  void _confirmEquip(Spell spell) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Equip Spell?', style: TextStyle(color: Colors.amber)),
        content: Text(
          'Equip ${spell.name}? This cannot be changed until you prestige.',
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
              setState(() {
                equipped.add(spell);
                _updateEquippedSpells();
              });
            },
            child: const Text('Equip',
                style: TextStyle(color: Colors.lightGreenAccent)),
          ),
        ],
      ),
    );
  }
}
