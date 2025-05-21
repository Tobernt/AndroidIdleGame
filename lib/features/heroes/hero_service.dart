import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/game_state.dart';
import 'hero.dart';

class HeroService {
  final List<HeroData> _allHeroes = [];

  List<HeroData> get all => List.unmodifiable(_allHeroes);
  List<HeroData> get unlockedHeroes => _allHeroes.where((h) => h.unlocked).toList();
  List<HeroData> get selectedHeroes => _allHeroes.where((h) => h.selected).toList();

  int maxRosterSize = 1;

  final Map<String, HeroEffect> _effectMap = {
    "hero_human": (state, multiplier) {
      state.tapPower += 0.5 * multiplier;
    },
    "hero_undead": (state, multiplier) {
      state.addResource('population', 0.05 * multiplier);
    },
    "hero_elf": (state, multiplier) {
      state.resourceModifiers['mana_regen'] =
          (state.resourceModifiers['mana_regen'] ?? 1.0) + 0.1 * multiplier;
    },
    "hero_orc": (state, multiplier) {
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * (1.0 + 0.2 * multiplier);
    },
    "hero_dwarf": (state, multiplier) {
      state.resourceModifiers['building_cost_multiplier'] =
          (state.resourceModifiers['building_cost_multiplier'] ?? 1.0) * (1.0 - 0.1 * multiplier);
    },
    "hero_automaton": (state, multiplier) {
      state.resourceModifiers['gold_income'] =
          (state.resourceModifiers['gold_income'] ?? 1.0) * (1.0 + 0.05 * multiplier);
      state.resourceModifiers['mana_regen'] =
          (state.resourceModifiers['mana_regen'] ?? 1.0) + 0.05 * multiplier;
    },
  };

  /// ✅ FIXED: Reference _allHeroes correctly
  bool hasUnlockedHero(String heroId) {
    return _allHeroes.any((h) => h.id == heroId && h.unlocked);
  }

  Future<void> loadFromJsonAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final List<dynamic> jsonList = json.decode(raw);

    _allHeroes.clear();
    for (var e in jsonList) {
      final id = e['id'];
      final effect = _effectMap[id] ?? ((_, __) {});
      _allHeroes.add(HeroData.fromJson(Map<String, dynamic>.from(e), effect));
    }
  }

  void unlockByAchievementId(String achievementId) {
    try {
      final hero = _allHeroes.firstWhere(
            (h) => h.unlockAchievementId == achievementId,
      );
      hero.unlocked = true;
    } catch (_) {
      // Silently fail — some factions might not have heroes yet
    }
  }

  void toggleHeroSelection(String heroId) {
    final hero = _allHeroes.firstWhere(
          (h) => h.id == heroId,
      orElse: () => throw Exception("Hero $heroId not found"),
    );
    if (!hero.unlocked) return;

    if (hero.selected) {
      hero.selected = false;
    } else if (selectedHeroes.length < maxRosterSize) {
      hero.selected = true;
    }
  }

  void applySelectedHeroes(GameState state, double lifetimeMultiplier) {
    for (final hero in selectedHeroes) {
      hero.effect(state, lifetimeMultiplier);
    }
  }

  void reset() {
    for (final hero in _allHeroes) {
      hero.selected = false;
    }
  }
}
