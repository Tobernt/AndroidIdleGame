import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/game_state.dart';
import '../prestige/prestige_service.dart';
import 'skill.dart';
import 'skill_data.dart';

class SkillManager {
  final List<Skill> allSkills = [];
  final PrestigeService prestigeService;

  SkillManager({required this.prestigeService});

  final Map<String, SkillEffect> effectMap = {
    "max_mana_50": (state) {
      final currentMax = state.getMax('mana');
      state.setMax('mana', currentMax + 50);
    },
    "tap_power_1": (state) => state.tapPower += 1,
    "gold_income_20": (state) {
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * 1.2;
    },
    "cooldown_reduce_10": (state) {
      state.resourceModifiers['spell_cooldown_mult'] =
          (state.resourceModifiers['spell_cooldown_mult'] ?? 1.0) * 0.9;
    },
    "building_cost_reduce_10": (state) {
      state.resourceModifiers['building_cost_multiplier'] =
          (state.resourceModifiers['building_cost_multiplier'] ?? 1.0) * 0.9;
    },
    "gold_per_building": (state) {
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * 1.1;
    },
    "population_capless": (state) {
      state.setMax('population', double.infinity);
    },
  };

  /// Load multiple skill lists from asset paths
  Future<void> loadFactionSkills(List<String> factionPaths) async {
    allSkills.clear();

    for (final path in factionPaths) {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw) as List<dynamic>;

      allSkills.addAll(decoded
          .map((e) => SkillData.fromJson(Map<String, dynamic>.from(e)))
          .map((data) => data.toSkill(effectMap)));
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
      equip(skill, state); // <- auto-equip and apply effect!
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

  /// Used by achievements or other systems
  void unlockSkillById(String id) {
    final skill = allSkills.firstWhere(
          (s) => s.id == id,
      orElse: () => throw Exception('Skill not found: $id'),
    );
    skill.available = true;
  }

  void markSkillAsAvailable(String id) => unlockSkillById(id);

  /// Apply available skill visibility after selecting factions
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
}
