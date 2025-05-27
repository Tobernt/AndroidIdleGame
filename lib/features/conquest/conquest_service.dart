import '../../core/game_state.dart';
import '../factions/faction_service.dart';
import '../heroes/hero_service.dart';
import '../achievements/achievement_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class ConquestManager {
  final GameState state;
  final FactionManager factionManager;
  final HeroService heroService;
  final AchievementService achievementService;

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
    required this.achievementService,
  }) {
    conqueredFactions.addAll(state.conqueredFactions);

    final rawTime = state.metaValues['run_start_time'];
    runStartTime = rawTime is String
        ? DateTime.tryParse(rawTime) ?? DateTime.now()
        : DateTime.now();

    state.metaValues['run_start_time'] = runStartTime.toIso8601String();
  }

  double get currentMight {
    final sum = [
      'gold',
      'mana',
      'ore',
      'population',
      'essence',
      'crystals',
    ].map((r) => state.getResource(r)).reduce((a, b) => a + b);
    return pow(sum / 6, 1.25).toDouble();
  }

  double mightRequiredForFaction(String factionId) {
    final index = factionManager.allFactions.indexWhere((f) => f.id == factionId);
    final base = 1000 + index * 750;

    final elapsed = DateTime.now().difference(runStartTime);
    final rounds = elapsed.inSeconds / (8 * 3.6); // Time-based scaling

    final remaining = factionManager.allFactions.where((f) =>
    !f.isSelected &&
        !conqueredFactions.contains(f.id) &&
        !destroyedFactions.contains(f.id)
    ).length;

    final difficultyTier = index + 1; // Tier starts from 1, 2, ..., N

    // 👇 Per-faction exponential base increases with tier
    final dynamicGrowthRate = 10 + (difficultyTier * 0.05); // e.g., 1.20, 1.25, 1.30, etc.
    final growth = min(10.0, pow(dynamicGrowthRate, rounds)); // Optional cap

    return base * growth.toDouble() * pow(10, conqueredFactions.length + destroyedFactions.length);
  }


  List<String> get conquerableFactions => factionManager.allFactions.where((f) =>
  !f.isSelected &&
      !conqueredFactions.contains(f.id) &&
      !destroyedFactions.contains(f.id)
  ).map((f) => f.id).toList();

  bool tryConquer(String factionId) {
    if (!conquestUnlocked || conqueredFactions.contains(factionId) || !conquerableFactions.contains(factionId)) {
      return false;
    }

    final required = mightRequiredForFaction(factionId);
    if (currentMight < required) return false;

    conqueredFactions.add(factionId);
    state.conqueredFactions.add(factionId);
    factionManager.unlock(factionId);

    if (canAddMoreFactions()) {
      factionManager.toggleSelect(factionId);
    } else {
      state.resourceModifiers['global_bonus'] = (state.resourceModifiers['global_bonus'] ?? 1.0) * 1.05;
    }

    if ((state.conqueredFactions.length + destroyedFactions.length) == 5) {
      if (factionManager.selectedFactionId == 'humans') {
        achievementService.forceUnlockById('achieve_hero_human');
      } else if (factionManager.selectedFactionId == 'elves') {
        achievementService.forceUnlockById('achieve_hero_elf');
      } else if (factionManager.selectedFactionId == 'orcs') {
        achievementService.forceUnlockById('achieve_hero_orc');
      } else if (factionManager.selectedFactionId == 'dwarves') {
        achievementService.forceUnlockById('achieve_hero_dwarf');
      } else if (factionManager.selectedFactionId == 'undead') {
        achievementService.forceUnlockById('achieve_hero_undead');
      } else if (factionManager.selectedFactionId == 'automatons') {
        achievementService.forceUnlockById('achieve_hero_automaton');
      }
    }
    achievementService.evaluate(
      state: state,
      lifetimeGold: state.lifetimeResources['gold'] ?? 0,
      buildingsOwned: 0,
      tapCount: state.currentRunTaps,
    );
    return true;
  }

  void checkFactionAnnihilation() {
    final elapsed = DateTime.now().difference(runStartTime);
    final rounds = elapsed.inHours ~/ 8;

    final factionsLeft = factionManager.allFactions.where((f) =>
    !f.isSelected &&
        !conqueredFactions.contains(f.id) &&
        !destroyedFactions.contains(f.id)
    ).toList();

    final shouldRemain = max(1, 6 - rounds * 2);

    if (factionsLeft.length > shouldRemain) {
      factionsLeft.shuffle();
      for (int i = 0; i < factionsLeft.length - shouldRemain; i++) {
        destroyedFactions.add(factionsLeft[i].id);
        debugPrint("💥 Faction annihilated: ${factionsLeft[i].id}");
      }
    }

    if ((state.conqueredFactions.length + destroyedFactions.length) == 5) {
      if (factionManager.selectedFactionId == 'humans') {
        achievementService.forceUnlockById('achieve_hero_human');
      } else if (factionManager.selectedFactionId == 'elves') {
        achievementService.forceUnlockById('achieve_hero_elf');
      } else if (factionManager.selectedFactionId == 'orcs') {
        achievementService.forceUnlockById('achieve_hero_orc');
      } else if (factionManager.selectedFactionId == 'dwarves') {
        achievementService.forceUnlockById('achieve_hero_dwarf');
      } else if (factionManager.selectedFactionId == 'undead') {
        achievementService.forceUnlockById('achieve_hero_undead');
      } else if (factionManager.selectedFactionId == 'automatons') {
        achievementService.forceUnlockById('achieve_hero_automaton');
      }
    }
    if (factionsLeft.length == 1 && elapsed.inHours >= 32) {
      state.metaValues['force_prestige'] = true;
    }

    achievementService.evaluate(
      state: state,
      lifetimeGold: state.lifetimeResources['gold'] ?? 0,
      buildingsOwned: 0,
      tapCount: state.currentRunTaps,
    );
  }

  bool canAddMoreFactions() => factionManager.canSelectMore();

  void reset() {
    conqueredFactions.clear();
    destroyedFactions.clear();
    state.conqueredFactions.clear();

    runStartTime = DateTime.now();
    state.metaValues['run_start_time'] = runStartTime.toIso8601String();
  }
}
