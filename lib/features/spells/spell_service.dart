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
      "InstantGoldFromIncome(30)": (state) {
        final goldPerSecond = 1.0;
        state.addResource('gold', goldPerSecond * 30);
      },

      "Modifier(gold_income_multiplier=2.0, duration=15)": (state) {
        manager.addModifier(Modifier(
          id: 'gold_income_multiplier',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },

      "GainResources(gold=150, mana=20)": (state) {
        state.addResource('gold', 150);
        state.addResource('mana', 20);
      },

      "GainResources(mana=15)": (state) => state.addResource('mana', 15),
      "GainResources(mana=30)": (state) => state.addResource('mana', 30),
      "GainResources(gold=100)": (state) => state.addResource('gold', 100),
      "GainResources(ore=25)": (state) => state.addResource('ore', 25),
      "GainResources(population=10)": (state) => state.addResource('population', 10),

      "InstantGoldFromTapRate(60)": (state) {
        final tapPower = state.tapPower;
        state.addResource('gold', tapPower * 60);
      },

      "GoldFromPopulation(5)": (state) {
        final pop = state.getResource('population');
        state.addResource('gold', pop * 5);
      },

      "TriggerAutoTap(5)": (state) {
        state.resourceModifiers['auto_tap_trigger'] = 5.0;
      },

      "ReduceAllCooldowns(0.2)": (state) {
        state.resourceModifiers['cooldown_reduction'] =
            (state.resourceModifiers['cooldown_reduction'] ?? 0.0) + 0.2;
      },

      "ReduceAllCooldowns(10)": (state) {
        state.resourceModifiers['cooldown_reduction'] =
            (state.resourceModifiers['cooldown_reduction'] ?? 0.0) + 10.0;
      },

      "Modifier(global_bonus=1.5, duration=15)": (state) {
        manager.addModifier(Modifier(
          id: 'global_bonus',
          multiplier: 1.5,
          duration: const Duration(seconds: 15),
        ));
      },

      "Modifier(global_bonus=1.25, duration=15)": (state) {
        manager.addModifier(Modifier(
          id: 'global_bonus',
          multiplier: 1.25,
          duration: const Duration(seconds: 15),
        ));
      },

      "Modifier(auto_tap=2.0, duration=10)": (state) {
        manager.addModifier(Modifier(
          id: 'auto_tap',
          multiplier: 2.0,
          duration: const Duration(seconds: 10),
        ));
      },

      "Modifier(global_output=1.25, duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'global_output',
          multiplier: 1.25,
          duration: const Duration(seconds: 20),
        ));
      },

      "ReduceBuildingCost(duration=10)": (state) {
        manager.addModifier(Modifier(
          id: 'building_cost_multiplier',
          multiplier: 0.5,
          duration: const Duration(seconds: 10),
        ));
      },

      "AutoTap(duration=10, rate=3)": (state) {
        manager.addModifier(Modifier(
          id: 'auto_tap',
          multiplier: 3.0,
          duration: const Duration(seconds: 10),
        ));
      },

      "ConvertPopulationToMana(0.1)": (state) {
        final pop = state.getResource('population');
        final amount = pop * 0.1;
        state.addResource('mana', amount);
        state.spendResource('population', amount);
      },

      "GenerateOreBurst": (state) {
        state.addResource('ore', 100);
      },

      "BoostSpellPower(duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'spell_power',
          multiplier: 1.5,
          duration: const Duration(seconds: 20),
        ));
      },

      "ManaBasedGoldBurst(duration=30)": (state) {
        final manaSpent = state.getMetaValue('mana_spent_last_30s');
        state.addResource('gold', manaSpent * 2.0);
      },

      "CastAllEquippedSpells": (state) {
        debugPrint("⚠️ CastAllEquippedSpells triggered — must be handled in GameManager");
      },

      "Modifier(mana_regen=2.0, duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'mana_regen',
          multiplier: 2.0,
          duration: const Duration(seconds: 20),
        ));
      },

      "Modifier(tap_power_mult=4.0, duration=10)": (state) {
        manager.addModifier(Modifier(
          id: 'tap_power',
          multiplier: 4.0,
          duration: const Duration(seconds: 10),
        ));
      },

      "Modifier(building_output_mult=2.0, duration=15)": (state) {
        manager.addModifier(Modifier(
          id: 'building_output',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },

      "Modifier(building_cost_multiplier=0.5, duration=10)": (state) {
        manager.addModifier(Modifier(
          id: 'building_cost_multiplier',
          multiplier: 0.5,
          duration: const Duration(seconds: 10),
        ));
      },

      "Modifier(building_cost_multiplier=0.75, duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'building_cost_multiplier',
          multiplier: 0.75,
          duration: const Duration(seconds: 20),
        ));
      },

      "Modifier(gold_income=2.0, duration=30)": (state) {
        manager.addModifier(Modifier(
          id: 'gold_income',
          multiplier: 2.0,
          duration: const Duration(seconds: 30),
        ));
      },

      "Modifier(bloodfury=1.0, duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'bloodfury',
          multiplier: 1.0,
          duration: const Duration(seconds: 20),
        ));
      },

      "Modifier(bloodfury_gold_boost=1.0, duration=20)": (state) {
        manager.addModifier(Modifier(
          id: 'bloodfury_gold_boost',
          multiplier: 1.0,
          duration: const Duration(seconds: 20),
        ));
      },

      "Modifier(gold_income_multiplier=1.2, duration=60)": (state) {
        manager.addModifier(Modifier(
          id: 'gold_income_multiplier',
          multiplier: 1.2,
          duration: const Duration(seconds: 60),
        ));
      },
      "Modifier(tap_power=4.0, duration=10)": (state) {
        _modifierManager.addModifier(Modifier(
          id: 'tap_power',
          multiplier: 4.0,
          duration: const Duration(seconds: 10),
        ));
      },
      "Modifier(building_output=2.0, duration=15)": (state) {
        _modifierManager.addModifier(Modifier(
          id: 'building_output',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },
      "Modifier(building_cost=0.5, duration=10)": (state) {
        _modifierManager.addModifier(Modifier(
          id: 'building_cost',
          multiplier: 0.5,
          duration: const Duration(seconds: 10),
        ));
      },
      "Modifier(gold_income=2.0, duration=15)": (state) {
        _modifierManager.addModifier(Modifier(
          id: 'gold_income',
          multiplier: 2.0,
          duration: const Duration(seconds: 15),
        ));
      },
      "ConvertPopulationToMana(10)": (state) {
        final pop = state.getResource('population');
        final amount = pop * 0.10;
        state.addResource('mana', amount);
        state.spendResource('population', amount);
      },
    };
  }

  Future<void> loadFromJsonAssets(List<String> paths) async {
    final List<Spell> all = [];
    final map = buildEffectMap(_modifierManager); // ✅ Build once

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
}
