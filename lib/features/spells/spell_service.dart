import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../modifiers/modifier.dart';
import '../modifiers/modifier_manager.dart';
import '../../core/game_state.dart';
import '../prestige/prestige_service.dart';
import 'spell.dart';
import 'spell_data.dart';

class SpellService extends ChangeNotifier {
  final List<Spell> _allSpells = [];
  final List<Spell> equippedSpells = [];
  final PrestigeService _prestigeService;
  final ModifierManager _modifierManager;


  List<Spell> get allSpells => List.unmodifiable(_allSpells);
  List<Spell> get visibleSpells => _allSpells.where((s) => s.unlocked).toList();

  SpellService({
    required PrestigeService prestigeService,
    required ModifierManager modifierManager,
  })  : _prestigeService = prestigeService,
        _modifierManager = modifierManager;

  Map<String, SpellEffect> buildEffectMap(ModifierManager manager) {
    return {
      // HUMAN SPELLS
      "human_spell_1": (state) {
        final income = state.resourceModifiers['gold_per_sec'] ?? 0.0;
        state.addResource('gold', income * 30);
      },
      "human_spell_2": (state) {
        manager.addModifier(Modifier(
          id: 'building_cost',
          multiplier: 0.5,
          duration: const Duration(seconds: 10),
        ));
      },
      "human_spell_3": (state) {
        manager.addModifier(Modifier(
          id: 'gold_income_multiplier',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },
      "human_spell_4": (state) {
        manager.addModifier(Modifier(
          id: 'gold_income_multiplier',
          multiplier: 1.2,
          duration: const Duration(seconds: 60),
        ));
      },
      "human_spell_5": (state) {
        final enabled = state.metaValues['divine_aura_active'] == true;
        if (enabled) {
          state.metaValues['divine_aura_active'] = false;
          state.resourceModifiers.remove('global_output');
          state.resourceMax['mana'] = 100.0;
        } else {
          state.metaValues['divine_aura_active'] = true;
          state.resourceModifiers['global_output'] = 2.0;
          state.resourceMax['mana'] = 50.0;
          final current = state.getResource('mana');
          if (current > 50.0) {
            state.resourceAmounts['mana'] = 50.0;
          }
        }
      },

      // UNDEAD SPELLS
      "undead_spell_1": (state) {
        state.addResource('population', 10);
      },
      "undead_spell_2": (state) {
        final pop = state.getResource('population');
        if (pop <= 0) return;
        final amount = pop * 0.10;
        state.spendResource('population', amount);
        state.addResource('mana', amount * 10);
      },
      "undead_spell_3": (state) {
        final pop = state.getResource('population');
        final multiplier = 1.0 + (pop * 0.005).clamp(0.0, 2.0); // max 200%
        manager.addModifier(Modifier(
          id: 'gold_income_multiplier',
          multiplier: multiplier,
          duration: const Duration(seconds: 15),
        ));
      },
      "undead_spell_4": (state) {
        final pop = state.getResource('population');
        final goldGain = pop * 5;
        state.addResource('gold', goldGain);
      },
      "undead_spell_5": (state) {
        final pop = state.getResource('population');
        final multiplier = 1.0 + (pop * 0.0025).clamp(0.0, 1.5); // max 250%
        manager.addModifier(Modifier(
          id: 'global_output',
          multiplier: multiplier,
          duration: const Duration(seconds: 20),
        ));
      },
      // Dwarf Spells
      "dwarf_spell_1": (state) {
        // Golden Draft: Gain 100 gold instantly
        state.addResource("gold", 100);
      },

      "dwarf_spell_2": (state) {
        // Forge Burst: +50% global production for 15s
        manager.addModifier(Modifier(
          id: "global_bonus",
          multiplier: 1.5,
          duration: const Duration(seconds: 15),
        ));
      },

      "dwarf_spell_3": (state) {
        // Reinforce Walls: Reduce building cost by 25% for 20s
        manager.addModifier(Modifier(
          id: "building_cost_multiplier",
          multiplier: 0.75,
          duration: const Duration(seconds: 20),
        ));
      },

      "dwarf_spell_4": (state) {
        // Deep Delve: Gain 25 ore instantly
        state.addResource("ore", 25);
      },

      "dwarf_spell_5": (state) {
        // King's Vault: Double gold income for 30s
        manager.addModifier(Modifier(
          id: "gold_income",
          multiplier: 2.0,
          duration: const Duration(seconds: 30),
        ));
      },

      // Elf Spells
      "elf_spell_1": (state) {
        state.addResource('mana', 15);
      },

      "elf_spell_2": (state) {
        final manaSpent = state.getMetaValue('mana_spent_last_30s') ?? 0.0;
        state.addResource('gold', manaSpent * 2.0);
      },

      "elf_spell_3": (state) {
        final now = DateTime.now();
        const cooldownReduction = Duration(seconds: 10);

        for (final spell in state.metaValues['equipped_spells'] ?? <Spell>[]) {
          // Skip this spell (elf_spell_3) itself
          if (spell.id == 'elf_spell_3') continue;

          final lastCast = spell.lastCast;
          final cooldown = spell.getFinalCooldown(state);

          if (lastCast != null) {
            final elapsed = now.difference(lastCast);
            final newElapsed = elapsed + cooldownReduction;

            // Only adjust if not already ready
            if (elapsed < cooldown) {
              final adjustedLastCast = now.subtract(newElapsed);
              spell.lastCast = adjustedLastCast.isBefore(now.subtract(cooldown))
                  ? now.subtract(cooldown)
                  : adjustedLastCast;
            }
          }
        }
      },

      "elf_spell_4": (state) {
        manager.addModifier(Modifier(
          id: 'mana_regen',
          multiplier: 2.0,
          duration: const Duration(seconds: 20),
        ));
      },

      "elf_spell_5": (state) {
        // Note: This must be handled in GameManager or spell system
        // as it requires invoking all equipped spells
        debugPrint("⚡ elf_spell_5: CastAllEquippedSpells triggered");
        state.metaValues['cast_all_equipped'] = true;
      },

      // ORC SPELLS
      "orc_spell_1": (state) {
        // Battle Roar: Boost tap power for 10 seconds
        manager.addModifier(Modifier(
          id: 'tap_power',
          multiplier: 4.0,
          duration: const Duration(seconds: 10),
        ));
      },
      "orc_spell_2": (state) {
        // Smash & Grab: Gain gold equal to 60 seconds of tap value
        final tapPower = state.tapPower;
        state.addResource('gold', tapPower * 60);
      },
      "orc_spell_3": (state) {
        // Unstoppable Force: Double all building output for 15 seconds
        manager.addModifier(Modifier(
          id: 'building_output',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },
      "orc_spell_4": (state) {
        // Warchief's Command: Reduce all building costs by 50% for 10 seconds
        manager.addModifier(Modifier(
          id: 'building_cost',
          multiplier: 0.5,
          duration: const Duration(seconds: 10),
        ));
      },
      "orc_spell_5": (state) {
        // Bloodfury: Trigger passive + tap-based gold gain (handled elsewhere)
        manager.addModifier(Modifier(
          id: 'bloodfury',
          multiplier: 1.0,
          duration: const Duration(seconds: 20),
        ));

        manager.addModifier(Modifier(
          id: 'bloodfury_gold_boost',
          multiplier: 1.0,
          duration: const Duration(seconds: 20),
        ));
      },
      // AUTOMATON SPELLS
      "auto_spell_1": (state) {
        // Auto-Trigger: Triggers 5 auto-taps instantly
        state.resourceModifiers['auto_tap_trigger'] = 5.0;
      },

      "auto_spell_2": (state) {
        // Coolant Pulse: Reduce all cooldowns by 20%
        state.resourceModifiers['cooldown_reduction'] =
            (state.resourceModifiers['cooldown_reduction'] ?? 0.0) + 0.2;
      },

      "auto_spell_3": (state) {
        // Mana Reactor: Restore 30 mana
        state.addResource('mana', 30);
      },

      "auto_spell_4": (state) {
        // Overdrive: Doubles auto-tap power for 10s
        manager.addModifier(Modifier(
          id: 'auto_tap',
          multiplier: 2.0,
          duration: const Duration(seconds: 10),
        ));
      },

      "auto_spell_5": (state) {
        // System Purge: Duration resets on tap; max duration decreases
        // Logic for dynamic reset & decay must be handled in GameManager
        debugPrint("⚙️ auto_spell_5 triggered: start dynamic System Purge mode");
        state.metaValues['auto_spell_5_active'] = true;
        state.metaValues['auto_spell_5_duration'] = 15.0; // Initial max duration in seconds
        state.metaValues['auto_spell_5_last_tap'] = DateTime.now().toIso8601String();

        // Apply initial modifier (re-applied or extended externally)
        manager.addModifier(Modifier(
          id: 'global_bonus',
          multiplier: 1.25,
          duration: const Duration(seconds: 1), // Keep alive with refresh logic
        ));
      },
    };
  }

  Future<void> loadFromJsonAssets(List<String> paths) async {
    final List<Spell> all = [];
    final map = buildEffectMap(_modifierManager); // Build once

    for (final path in paths) {
      final raw = await rootBundle.loadString(path);
      final List<dynamic> decoded = json.decode(raw);
      final data = decoded.map((e) => SpellData.fromJson(Map<String, dynamic>.from(e)));

      all.addAll(data.map((d) {
        final effect = map[d.effectId];
        if (effect == null) {
          debugPrint("❌ Unknown effect: ${d.effectId}");
        }
        return d.toSpell(map);
      }));
    }

    _allSpells
      ..clear()
      ..addAll(all);

    equippedSpells
      ..clear()
      ..addAll(
        _allSpells
            .where((s) => s.unlocked)
            .take(_prestigeService.maxEquippedSpells),
      );

    notifyListeners();
  }

  void cast(Spell spell, GameState state) {
    if (spell.tryCast(state)) {
      notifyListeners();
    }
  }

  void unlockSpellById(String id) {
    final spell = _allSpells.firstWhere(
          (s) => s.id == id,
      orElse: () => throw Exception('Spell not found: $id'),
    );
    spell.unlocked = true;
    notifyListeners();
  }

  void reset() {
    equippedSpells.clear();
    for (var spell in _allSpells) {
      spell.unlocked = false;
    }
    notifyListeners();
  }

  void tickCooldowns() {}
  void setEquipped(List<String> spellIds) {
    equippedSpells.clear();
    for (final id in spellIds) {
      final match = allSpells.firstWhere((s) => s.id == id,);
      if (match != null) {
        equippedSpells.add(match);
      }
    }
  }
}
