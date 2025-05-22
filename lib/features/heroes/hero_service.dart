import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Needed for ChangeNotifier
import '../../core/game_state.dart';
import 'hero.dart';

class HeroService extends ChangeNotifier {
  final List<HeroData> _allHeroes = [];

  List<HeroData> get all => List.unmodifiable(_allHeroes);
  List<HeroData> get unlockedHeroes => _allHeroes.where((h) => h.unlocked).toList();
  List<HeroData> get selectedHeroes => _allHeroes.where((h) => h.selected).toList();
  Map<String, HeroEffect> get effectMap => _effectMap;
  late GameState gameState;

  void addHero(HeroData hero) => _allHeroes.add(hero);
  void clearAll() => _allHeroes.clear();

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
  void loadUnlockedFromMeta(List<String> ids) {
    final selected = gameState.metaValues['selected_heroes'] as List<String>? ?? [];

    for (final hero in _allHeroes) {
      hero.unlocked = ids.contains(hero.id);
      hero.selected = selected.contains(hero.id);
    }

    notifyListeners();
  }

  void attachState(GameState state) {
    gameState = state;
  }

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

    notifyListeners(); // Refresh UI after loading
  }

  void unlockByAchievementId(String achievementId) {
    try {
      final hero = _allHeroes.firstWhere(
            (h) => h.unlockAchievementId == achievementId,
      );
      if (!hero.unlocked) {
        hero.unlocked = true;
        notifyListeners(); // Notify only on change
      }
    } catch (_) {
      // Fail silently if no hero matches
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
    _saveSelectedHeroesToMeta();
    notifyListeners(); // Update UI after toggling
  }

  void _saveSelectedHeroesToMeta() {
    gameState.metaValues['selected_heroes'] =
        selectedHeroes.map((h) => h.id).toList();
  }

  void applySelectedHeroes(GameState state, double lifetimeMultiplier) {
    for (final hero in selectedHeroes) {
      hero.effect(state, lifetimeMultiplier);
    }
  }
  void clearSelectedHeroes() {
    for (final hero in _allHeroes) {
      hero.selected = false;
    }
    gameState.metaValues['selected_heroes'] = <String>[]; // Clear saved list
    notifyListeners();
  }

  void reset() {
    for (final hero in _allHeroes) {
      hero.selected = false;
    }
    notifyListeners(); // Reflect reset in UI
  }
}
