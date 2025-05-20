import '../../core/game_state.dart';
import '../factions/faction_service.dart';
import '../heroes/hero_service.dart';
import 'dart:math';

class ConquestManager {
  final GameState state;
  final FactionManager factionManager;
  final HeroService heroService;

  /// Minimum required prestige level to begin conquering
  static const int requiredPrestigeLevel = 10;

  /// Minimum gold needed to be allowed to prestige (and thus conquer)
  static const double minGoldToPrestige = 100000;

  /// Base might required to conquer the first faction
  static const double baseConquestThreshold = 500;

  /// Tracks which factions have been conquered
  final Set<String> conqueredFactions = {};

  /// Whether the conquest system is available
  bool get conquestUnlocked => state.prestigeLevel >= requiredPrestigeLevel;

  /// Whether all factions are conquered
  bool get isGameCompleted => conqueredFactions.length >= 6;

  ConquestManager({
    required this.state,
    required this.factionManager,
    required this.heroService,
  });

  /// The player’s current might is based on all resources combined
  double get currentMight {
    double sum = 0;
    for (var value in state.resourceAmounts.values) {
      sum += value;
    }
    return sum / 1000; // scale for balance
  }

  /// Gets the conquest cost for the nth conquest (scales exponentially)
  double requiredMightForNext() {
    return pow(2.5, conqueredFactions.length) * baseConquestThreshold;
  }

  /// Returns a list of faction IDs that are eligible for conquest
  List<String> get conquerableFactions {
    return factionManager.allFactions
        .where((f) => !f.unlocked && !conqueredFactions.contains(f.id))
        .map((f) => f.id)
        .toList();
  }

  /// Attempts to conquer a faction
  bool tryConquer(String factionId) {
    if (!conquestUnlocked) return false;
    if (conqueredFactions.contains(factionId)) return false;
    if (!conquerableFactions.contains(factionId)) return false;

    double required = requiredMightForNext();
    if (currentMight < required) return false;

    // Mark as conquered
    conqueredFactions.add(factionId);
    factionManager.unlock(factionId);

    // If player has available slots, let them pick it — otherwise give passive bonus
    if (factionManager.canSelectMore()) {
      factionManager.toggleSelect(factionId);
    } else {
      // Apply global bonus if no free slot (e.g., +5% income)
      state.resourceModifiers['global_bonus'] =
          (state.resourceModifiers['global_bonus'] ?? 1.0) * 1.05;
    }

    // Unlock heroes if this is the first conquest
    if (conqueredFactions.length == 1) {
      state.heroesUnlocked = true;
      for (var f in factionManager.allFactions) {
        heroService.unlockByAchievementId('hero_unlock_${f.id}');
      }
    }

    return true;
  }

  void reset() {
    conqueredFactions.clear();
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
  }
}
