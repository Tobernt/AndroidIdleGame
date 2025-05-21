import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/game_state.dart';
import '../prestige/prestige_service.dart';
import 'skill.dart';
import 'skill_data.dart';
import 'package:flutter/foundation.dart';

typedef SkillEffect = void Function(GameState state);

class SkillManager {
  final List<Skill> allSkills = [];
  final PrestigeService prestigeService;

  SkillManager({required this.prestigeService});

  final Map<String, SkillEffect> effectMap = {
    // 🔧 Flat max boosts
    "max_mana_50": (state) {
      final currentMax = state.getMax('mana');
      state.setMax('mana', currentMax + 50);
    },

    // 🔧 Flat tap power increase
    "tap_power_1": (state) => state.tapPower += 1,
    "tap_power_5": (state) => state.tapPower += 5,

    // 🔧 Income multipliers
    "gold_income_20": (state) => _mult(state, 'gold_income', 1.2),
    "mana_regen_10": (state) => _mult(state, 'mana_regen', 1.1),
    "ore_multiplier_15": (state) => _mult(state, 'ore_multiplier', 1.15),

    // 🔧 Cost reduction
    "building_cost_reduce_10": (state) => _mult(state, 'building_cost_multiplier', 0.9),
    "spell_cost_reduce_15": (state) => _mult(state, 'spell_cost_multiplier', 0.85),

    // 🔧 Cooldown reduction
    "cooldown_reduce_10": (state) => _mult(state, 'spell_cooldown_mult', 0.9),

    // 🔧 Building-scaling effects
    "gold_per_building": (state) {
      final count = state.metaValues['buildings_owned'] ?? 0;
      final bonus = 0.01 * count; // +1% per building
      _mult(state, 'gold_income', 1.0 + bonus);
    },

    // 🔧 Unique behavior
    "population_capless": (state) => state.setMax('population', double.infinity),
    "population_growth_bonus_0.5": (state) {
      state.resourceModifiers['population_growth'] =
          (state.resourceModifiers['population_growth'] ?? 1.0) * 1.5;
    },
    "conditional_building_discount_10_if_pop_50": (state) {
      if ((state.getResource('population')) >= 50) {
        state.resourceModifiers['building_cost_multiplier'] =
            (state.resourceModifiers['building_cost_multiplier'] ?? 1.0) * 0.9;
      }
    },
    "gold_per_20_pop": (state) {
      final pop = state.getResource('population');
      final bonus = (pop ~/ 20) * 0.05;
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * (1 + bonus);
    },
    "cooldown_reduce_if_pop_100": (state) {
      if (state.getResource('population') >= 100) {
        state.resourceModifiers['spell_cooldown_mult'] =
            (state.resourceModifiers['spell_cooldown_mult'] ?? 1.0) * 0.9;
      }
    },
    "remove_population_cap": (state) => state.setMax('population', double.infinity),
    "mana_regen_20": (state) {
      state.resourceModifiers['mana_regen'] =
          (state.resourceModifiers['mana_regen'] ?? 1.0) * 1.2;
    },
    "spell_recast_chance_15": (state) {
      state.resourceModifiers['spell_recast_chance'] =
          (state.resourceModifiers['spell_recast_chance'] ?? 0.0) + 0.15;
    },
    "flat_mana_per_second_1": (state) {
      state.resourceModifiers['flat_mana_per_second'] =
          (state.resourceModifiers['flat_mana_per_second'] ?? 0.0) + 1.0;
    },
    "spell_cost_reduce_25": (state) {
      state.resourceModifiers['spell_cost_multiplier'] =
          (state.resourceModifiers['spell_cost_multiplier'] ?? 1.0) * 0.75;
    },
    "building_output_10": (state) {
      state.resourceModifiers['building_output'] =
          (state.resourceModifiers['building_output'] ?? 1.0) * 1.10;
    },
    "gold_per_tap_frenzy": (state) {
      state.resourceModifiers['gold_tap_frenzy'] =
          (state.resourceModifiers['gold_tap_frenzy'] ?? 0.0) + 1.0;
    },
    "gold_and_ore_income_15": (state) {
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * 1.15;
      state.resourceModifiers['ore_multiplier'] =
          (state.resourceModifiers['ore_multiplier'] ?? 1.0) * 1.15;
    },
    "all_income_5": (state) {
      for (var key in ['gold_income', 'mana_regen', 'ore_multiplier']) {
        state.resourceModifiers[key] =
            (state.resourceModifiers[key] ?? 1.0) * 1.05;
      }
    },
    "ore_per_building": (state) {
      final buildings = state.metaValues['buildings_owned'] ?? 0;
      state.resourceModifiers['ore_multiplier'] =
          (state.resourceModifiers['ore_multiplier'] ?? 1.0) * (1 + 0.01 * buildings);
    },
    "gold_scaling_with_ore": (state) {
      final ore = state.getResource('ore');
      final bonus = (ore / 100.0) * 0.05;
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * (1 + bonus);
    },
    "tap_power_15_percent": (state) {
      state.tapPower *= 1.15;
    },
    "auto_tap_boost_25": (state) {
      state.resourceModifiers['auto_tap'] =
          (state.resourceModifiers['auto_tap'] ?? 1.0) * 1.25;
    },
    "output_boost_if_auto": (state) {
      if ((state.resourceModifiers['auto_tap'] ?? 0.0) > 0) {
        state.resourceModifiers['global_output'] =
            (state.resourceModifiers['global_output'] ?? 1.0) * 1.2;
      }
    },
  };

  static void _mult(GameState state, String key, double multiplier) {
    state.resourceModifiers[key] =
        (state.resourceModifiers[key] ?? 1.0) * multiplier;
  }

  /// Load multiple skill lists from asset paths
  Future<void> loadFactionSkills(List<String> factionPaths) async {
    allSkills.clear();

    for (final path in factionPaths) {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw) as List<dynamic>;

      allSkills.addAll(decoded
          .map((e) => SkillData.fromJson(Map<String, dynamic>.from(e)))
          .map((data) {
        final effectId = data.effectId;
        final effect = effectMap[effectId];
        if (effect == null) {
          assert(() {
            debugPrint('⚠️ Unknown skill effectId: $effectId — no effect will be applied');
            return true;
          }());
        }
        return data.toSkill(effect ?? (state) {});
      }));
    }
  }

  void reset() {
    for (final skill in allSkills) {
      skill.available = false;
      skill.unlocked = false;
      skill.equipped = false;
    }
  }

  bool canUnlock(Skill skill, GameState state) {
    return skill.available &&
        !skill.unlocked &&
        prestigeService.availableSkillPoints >= skill.cost;
  }

  /// Unlock and immediately apply the effect
  bool unlock(Skill skill, GameState state) {
    if (canUnlock(skill, state)) {
      prestigeService.spendSkillPoints(skill.cost);
      skill.unlocked = true;
      equip(skill, state); // auto-equip and apply effect
      return true;
    }
    return false;
  }

  /// Equips and applies effect
  void equip(Skill skill, GameState state) {
    if (skill.unlocked && !skill.equipped) {
      skill.equipped = true;
      skill.effect(state);
    }
  }

  void unlockSkillById(String id) {
    final skill = allSkills.firstWhere(
          (s) => s.id == id,
      orElse: () => throw Exception('Skill not found: $id'),
    );
    skill.available = true;
  }

  void markSkillAsAvailable(String id) => unlockSkillById(id);

  void applyFactionFilters(List<String> selectedFactionIds) {
    for (final skill in allSkills) {
      skill.available = selectedFactionIds.contains(skill.faction);
    }
  }

  List<Skill> get unlocked => allSkills.where((s) => s.unlocked).toList();
  List<Skill> get locked => allSkills.where((s) => !s.unlocked).toList();

  Map<int, List<Skill>> get groupedByTier {
    final map = <int, List<Skill>>{};
    for (final skill in allSkills.where((s) => s.available)) {
      map.putIfAbsent(skill.tier, () => []).add(skill);
    }
    return map;
  }

  /// Expose unlocked effect IDs (optional, for external systems like GameManager)
  List<String> getUnlockedEffects() {
    return allSkills.where((s) => s.unlocked).map((s) => s.effectId).toList();
  }
}
