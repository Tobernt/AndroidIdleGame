import '../../core/game_state.dart';
import '../factions/faction_service.dart';
import '../heroes/hero_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart'; // <-- needed for debugPrint

class ConquestManager {
  final GameState state;
  final FactionManager factionManager;
  final HeroService heroService;

  static const double baseConquestThreshold = 500;
  static const Duration roundDuration = Duration(hours: 8);

  final Set<String> conqueredFactions = {};
  final Set<String> destroyedFactions = {};
  DateTime runStartTime = DateTime.now();

  bool get conquestUnlocked => state.conquestUnlocked;
  bool get isGameCompleted => conqueredFactions.length >= 6;

  ConquestManager({
    required this.state,
    required this.factionManager,
    required this.heroService,
  }) {
    conqueredFactions.addAll(state.conqueredFactions);

    final rawTime = state.metaValues['run_start_time'];
    runStartTime = rawTime is String
        ? DateTime.tryParse(rawTime) ?? DateTime.now()
        : DateTime.now();

    state.metaValues['run_start_time'] = runStartTime.toIso8601String();
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

  double mightRequiredForFaction(String factionId) {
    final index = factionManager.allFactions.indexWhere((f) => f.id == factionId);
    final base = 500 + index * 250;

    final now = DateTime.now();
    final elapsed = now.difference(runStartTime);
    final seconds = elapsed.inSeconds;
    final scalingInterval = 8 * 3.6;

    final rounds = seconds / scalingInterval;

    final remaining = factionManager.allFactions.where((f) =>
    !f.isSelected &&
        !conqueredFactions.contains(f.id) &&
        !destroyedFactions.contains(f.id)).length;

    final dangerMultiplier = max(1, 6 - remaining + 1); // 1 to 6
    final growthRate = min(5.0, 1.25 * dangerMultiplier); // CAP to prevent overflow

    final totalRemoved = conqueredFactions.length + destroyedFactions.length;
    return base * pow(growthRate, rounds).toDouble() * pow(10, totalRemoved);
  }

  List<String> get conquerableFactions {
    return factionManager.allFactions
        .where((f) =>
    !conqueredFactions.contains(f.id) &&
        !destroyedFactions.contains(f.id) &&
        !f.isSelected)
        .map((f) => f.id)
        .toList();
  }

  bool canAddMoreFactions() => factionManager.canSelectMore();

  double getDangerMultiplier() {
    final remaining = factionManager.allFactions.where((f) =>
    !f.isSelected &&
        !conqueredFactions.contains(f.id) &&
        !destroyedFactions.contains(f.id)).length;

    return remaining > 1
        ? 1 + ((6 - remaining) * 0.2)
        : 2.0;
  }

  bool tryConquer(String factionId) {
    if (!conquestUnlocked ||
        conqueredFactions.contains(factionId) ||
        !conquerableFactions.contains(factionId)) {
      return false;
    }

    final required = mightRequiredForFaction(factionId);
    if (currentMight < required) return false;

    conqueredFactions.add(factionId);
    state.conqueredFactions.add(factionId);
    factionManager.unlock(factionId);

    // 🔍 DEBUG LOGGING
    debugPrint("✅ Faction conquered: $factionId");
    debugPrint("🎯 Playing faction: ${state.metaValues['selected_faction_id']}");
    debugPrint("📜 Conquered: ${state.conqueredFactions.toList()}");
    debugPrint("💀 Destroyed: ${state.destroyedFactions.toList()}");

    if (canAddMoreFactions()) {
      factionManager.toggleSelect(factionId);
    } else {
      state.resourceModifiers['global_bonus'] =
          (state.resourceModifiers['global_bonus'] ?? 1.0) * 1.05;
    }

    if (conqueredFactions.length == 1) {
      state.heroesUnlocked = true;
      for (var faction in factionManager.allFactions) {
        try {
          final hero = heroService.all.firstWhere((h) => h.faction == faction.id);
          heroService.unlockByAchievementId(hero.unlockAchievementId);
        } catch (_) {}
      }
    }

    return true;
  }

  void checkFactionAnnihilation() {
    final elapsed = DateTime.now().difference(runStartTime);
    final rounds = elapsed.inHours ~/ 8;

    final factionsLeft = factionManager.allFactions.where((f) {
      return !f.isSelected &&
          !conqueredFactions.contains(f.id) &&
          !destroyedFactions.contains(f.id);
    }).toList();

    final shouldRemain = max(1, 6 - rounds * 2);

    if (factionsLeft.length > shouldRemain) {
      final toDestroy = factionsLeft.length - shouldRemain;
      factionsLeft.shuffle();
      for (int i = 0; i < toDestroy; i++) {
        destroyedFactions.add(factionsLeft[i].id);
        debugPrint("💥 Faction annihilated: ${factionsLeft[i].id}");
      }
    }

    // 🔍 DEBUG LOGGING
    debugPrint("🎯 Playing faction: ${state.metaValues['selected_faction_id']}");
    debugPrint("📜 Conquered: ${state.conqueredFactions.toList()}");
    debugPrint("💀 Destroyed: ${state.destroyedFactions.toList()}");

    if (factionsLeft.length == 1 && elapsed.inHours >= 32) {
      state.metaValues['force_prestige'] = true;
    }
  }
  void reset() {
    conqueredFactions.clear();
    destroyedFactions.clear();
    state.conqueredFactions.clear();

    runStartTime = DateTime.now();
    state.metaValues['run_start_time'] = runStartTime.toIso8601String();
  }

  Map<String, dynamic> toJson() {
    return {
      'conqueredFactions': conqueredFactions.toList(),
      'destroyedFactions': destroyedFactions.toList(),
      'runStartTime': runStartTime.toIso8601String(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    final conquered = json['conqueredFactions'] ?? [];
    final destroyed = json['destroyedFactions'] ?? [];
    final start = json['runStartTime'];

    conqueredFactions
      ..clear()
      ..addAll(List<String>.from(conquered));
    destroyedFactions
      ..clear()
      ..addAll(List<String>.from(destroyed));
    state.conqueredFactions
      ..clear()
      ..addAll(conqueredFactions);

    if (start != null) {
      runStartTime = DateTime.tryParse(start.toString()) ?? DateTime.now();
    }
  }
}
