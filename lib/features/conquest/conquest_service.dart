import '../../core/game_state.dart';
import '../factions/faction_service.dart';
import '../heroes/hero_service.dart';
import 'dart:math';

class ConquestManager {
  final GameState state;
  final FactionManager factionManager;
  final HeroService heroService;

  static const double minGoldToPrestige = 100000;
  static const double baseConquestThreshold = 500;

  final Set<String> conqueredFactions = {};

  bool get conquestUnlocked => state.conquestUnlocked;
  bool get isGameCompleted => conqueredFactions.length >= 6;

  ConquestManager({
    required this.state,
    required this.factionManager,
    required this.heroService,
  }) {
    // Load persisted conquest data from GameState
    conqueredFactions.addAll(state.conqueredFactions);
  }

  double get currentMight {
    final gold = state.getResource('gold');
    final mana = state.getResource('mana');
    final ore = state.getResource('ore');
    final population = state.getResource('population');
    final essence = state.getResource('essence');
    final crystals = state.getResource('crystals');

    final sum = gold + mana + ore + population + essence + crystals;
    final average = sum / 6;

    return pow(average, 1.25).toDouble();
  }

  double requiredMightForNext() {
    return pow(2.5, conqueredFactions.length) * baseConquestThreshold;
  }

  List<String> get conquerableFactions {
    return factionManager.allFactions
        .where((f) => !f.unlocked && !conqueredFactions.contains(f.id))
        .map((f) => f.id)
        .toList();
  }

  bool tryConquer(String factionId) {
    if (!conquestUnlocked) return false;
    if (conqueredFactions.contains(factionId)) return false;
    if (!conquerableFactions.contains(factionId)) return false;

    double required = requiredMightForNext();
    if (currentMight < required) return false;

    // Mark as conquered and unlock faction
    conqueredFactions.add(factionId);
    state.conqueredFactions.add(factionId); // Persist to GameState
    factionManager.unlock(factionId);

    // Select faction if room
    if (factionManager.canSelectMore()) {
      factionManager.toggleSelect(factionId);
    } else {
      state.resourceModifiers['global_bonus'] =
          (state.resourceModifiers['global_bonus'] ?? 1.0) * 1.05;
    }

    // First conquest triggers hero unlocks
    if (conqueredFactions.length == 1) {
      state.heroesUnlocked = true;

      for (var faction in factionManager.allFactions) {
        try {
          final hero = heroService.all.firstWhere((h) => h.faction == faction.id);
          heroService.unlockByAchievementId(hero.unlockAchievementId);
        } catch (_) {
          // Hero not found for this faction — skip
        }
      }
    }

    return true;
  }

  void reset() {
    conqueredFactions.clear();
    state.conqueredFactions.clear(); // Reset persistent data too
  }

  Map<String, dynamic> toJson() {
    return {
      'conqueredFactions': conqueredFactions.toList(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['conqueredFactions'] ?? [];
    conqueredFactions
      ..clear()
      ..addAll(list.map((e) => e.toString()));
    state.conqueredFactions
      ..clear()
      ..addAll(conqueredFactions);
  }
}
