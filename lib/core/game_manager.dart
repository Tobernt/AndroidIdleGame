import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/achievements/achievement.dart';
import '../features/achievements/achievement_service.dart';
import '../features/buildings/building.dart';
import '../features/buildings/building_service.dart';
import '../features/factions/faction_service.dart';
import '../features/modifiers/modifier.dart';
import '../features/modifiers/modifier_manager.dart';
import '../features/prestige/prestige_service.dart';
import '../features/resources/resource_manager.dart';
import '../features/resources/resource_service.dart';
import '../features/skill_tree/skill_manager.dart';
import '../features/spells/spell.dart';
import '../features/spells/spell_service.dart';
import '../features/heroes/hero_service.dart';
import '../features/conquest/conquest_service.dart';
import 'game_state.dart';

class GameManager with ChangeNotifier {
  late GameState state;
  late ResourceManager resourceManager;
  late ResourceService resourceService;
  late ModifierManager modifierManager;
  late BuildingService buildingService;
  late SpellService spellService;
  late FactionManager factionManager;
  late SkillManager skillManager;
  late PrestigeService prestigeService;
  late AchievementService achievementService;
  late HeroService heroService;
  late ConquestManager conquestManager;
  final List<DateTime> _tapTimestamps = [];
  double _autoTapAccumulator = 0.0;
  bool isGameplayActive = false;

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool get hasSelectedFaction => factionManager.selected.isNotEmpty;

  Timer? _loopTimer;
  DateTime? _lastUpdate;
  int tapCount = 0;
  Future<void> init({bool fromLoad = false}) async {
    if (_initialized) return;

    if (!fromLoad) {
      // Only replace if state is actually uninitialized
      state = GameState();
      state.addResource('gold', 0);
      state.addResource('mana', 0);
    }

    // Core managers
    prestigeService = PrestigeService();
    modifierManager = ModifierManager();
    buildingService = BuildingService();
    spellService = SpellService(
      prestigeService: prestigeService,
      modifierManager: modifierManager,
    );
    factionManager = FactionManager(prestigeService: prestigeService);
    skillManager = SkillManager(prestigeService: prestigeService);
    resourceManager = ResourceManager();
    resourceService = ResourceService(resourceManager);
    achievementService = AchievementService();
    heroService = HeroService();
    conquestManager = ConquestManager(
      state: state,
      factionManager: factionManager,
      heroService: heroService,
      achievementService: achievementService,
    );


    // Load data
    await resourceManager.loadFromConfig();
    await buildingService.loadFromJsonAssets([
      'assets/data/humans_buildings.json',
      'assets/data/elf_buildings.json',
      'assets/data/orc_buildings.json',
      'assets/data/dwarf_buildings.json',
      'assets/data/undead_buildings.json',
      'assets/data/automaton_buildings.json',
    ]);
    await spellService.loadFromJsonAssets([
      'assets/data/humans_spells.json',
      'assets/data/elf_spells.json',
      'assets/data/orc_spells.json',
      'assets/data/dwarf_spells.json',
      'assets/data/undead_spells.json',
      'assets/data/automaton_spells.json',
    ]);
    await skillManager.loadFactionSkills([
      'assets/data/humans_skills.json',
      'assets/data/undead_skills.json',
      'assets/data/elf_skills.json',
      'assets/data/orc_skills.json',
      'assets/data/dwarf_skills.json',
      'assets/data/automaton_skills.json',
    ]);
    await heroService.loadFromJsonAsset('assets/data/hero_list.json');

    final rawJson = await rootBundle.loadString('assets/data/achievements.json');
    final List<dynamic> decoded = json.decode(rawJson);
    final achievements = decoded
        .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    achievementService.init(
      spellService: spellService,
      skillManager: skillManager,
      factionManager: factionManager,
    );
    achievementService.load(achievements);

    factionManager.clearSelection();
    applyFactionBonuses();
    if (factionManager.selected.isNotEmpty) {
      state.metaValues['selected_faction_id'] = factionManager.selected.first.id;
    }
    achievementService.applyClaimedRewards(state);
    final unlocked = state.metaValues['unlocked_heroes'] as List<String>? ?? [];
    heroService.attachState(state);
    heroService.loadUnlockedFromMeta(unlocked);
// ✅ Restore gold ad modifier if still active
    final adEndStr = state.metaValues['gold_ad_bonus_ends'];
    if (adEndStr is String) {
      final adEndTime = DateTime.tryParse(adEndStr);
      if (adEndTime != null) {
        final now = DateTime.now();
        if (adEndTime.isAfter(now)) {
          modifierManager.addModifier(
            Modifier(
              id: 'gold',
              multiplier: 2.0,
              duration: adEndTime.difference(now),
            ),
          );
        }
      }
    }

    startLoop();

    _initialized = true;
  }

  void tickResources(double deltaSeconds) {
    applyFactionBonuses(); // Reapply skills and effects

    // 🌱 Passive skill: Elf Skill 4 — max mana growth over time
    if (skillManager.getUnlockedEffects().contains('elf_skill_4')) {
      final key = 'elf_skill_4_mana_growth';
      final prev = state.getMetaValue(key);
      final growth = prev + (0.1 * deltaSeconds); // +0.1 per second
      state.setMetaValue(key, growth);
      state.setMax('mana', 100.0 + growth);
    }

    // 🧍 Passive skill: Human Skill 5 — global output from building count
    if (skillManager.getUnlockedEffects().contains('human_skill_5')) {
      final count = buildingService.allOwnedCount;
      final bonus = 1.0 + (count ~/ 10) * 0.01;
      state.resourceModifiers['global_from_buildings'] = bonus;
    }

    // 🔁 Recalculate income per second for each resource
    for (final entry in state.resourceAmounts.entries) {
      final id = entry.key;
      double base = buildingService.totalOutputPerSecond(resource: id);

      if (id == 'ore' && skillManager.getUnlockedEffects().contains('dwarf_skill_4')) {
        final buildingCount = state.metaValues['buildings_owned'] ?? 0;
        base += buildingCount.toDouble(); // +1 ore/sec per building
      }

      double baseIncome = 0.0;
      if (id == 'mana') baseIncome = 1.0;
      if (id == 'population' && skillManager.getUnlockedEffects().contains('undead_skill_1')) {
        baseIncome += 0.5;
      }

      double multiplier = 1.0;

      if (id == 'gold') {
        multiplier *= (state.resourceModifiers['gold_income'] ?? 1.0);
        multiplier *= modifierManager.getCombinedMultiplier('gold');
        multiplier *= modifierManager.getCombinedMultiplier('gold_income_multiplier');
        multiplier *= prestigeService.prestigeMultiplier;
      } else if (id == 'mana') {
        multiplier *= state.resourceModifiers['mana_regen'] ?? 1.0;
      } else {
        multiplier *= state.resourceModifiers['${id}_multiplier'] ?? 1.0;
      }

      // 🌐 Global modifiers
      if (id != 'mana') {
        multiplier *= (state.resourceModifiers['building_output'] ?? 1.0);
        multiplier *= (state.resourceModifiers['global_output'] ?? 1.0);
      }
      multiplier *= (state.resourceModifiers['global_from_buildings'] ?? 1.0);

      // Final calculation
      final incomePerSecond = (base + baseIncome) * multiplier;
      final delta = incomePerSecond * deltaSeconds;

      state.addResource(id, delta);
      state.resourceModifiers['${id}_per_sec'] = incomePerSecond;

      // ✅ Apply to lifetimeGold if gold
      if (id == 'gold') {
        prestigeService.applyGold(delta);
      }
    }

    // 👥 Hero scaling (e.g. lifetime bonus)
    final lifetimeMult = 1 + (log(prestigeService.lifetimeGold + 1) / 100);
    heroService.applySelectedHeroes(state, lifetimeMult);

    // 🪄 Spell cost backup
    state.resourceModifiers['spell_final_cost_multiplier'] =
        state.resourceModifiers['spell_cost_multiplier'] ?? 1.0;

    // ⚔️ Unlock conquest if needed
    if (!state.conquestUnlocked) {
      final claimed = achievementService.all.any(
            (a) => a.reward?.type == 'unlock_conquest' && a.isClaimed,
      );
      if (claimed) {
        state.conquestUnlocked = true;
      }
    }
  }

  void checkForPassiveUnlocks() {
    if (!state.conquestUnlocked) {
      final claimed = achievementService.all.any(
            (a) => a.reward?.type == 'unlock_conquest' && a.isClaimed,
      );
      if (claimed) {
        state.conquestUnlocked = true;
      }
    }
  }
  void unlockHeroesFromAchievements() {
    for (final achievement in achievementService.all) {
      if (achievement.isClaimed) {
        heroService.unlockByAchievementId(achievement.id);
      }
    }
  }

  void applyFactionBonuses() {
    state.resourceModifiers.clear();
    state.tapPower = 1.0;
    state.metaValues['buildings_owned'] = buildingService.allOwnedCount;
    state.metaValues['auto_building_count'] = buildingService.buildings
        .where((b) => b.tapPerSecond > 0 && b.level > 0)
        .length;

    // 1. Faction resource boosts
    for (var faction in factionManager.selected) {
      for (var entry in faction.resourceBoosts.entries) {
        final key = entry.key;
        final bonus = entry.value;
        state.resourceModifiers[key] =
            (state.resourceModifiers[key] ?? 1.0) * bonus;
      }
    }

    // 2. Building modifiers
    final buildingModifiers = buildingService.getActiveModifiers();
    for (final entry in buildingModifiers.entries) {
      final key = entry.key;
      final value = entry.value;
      state.resourceModifiers[key] =
          (state.resourceModifiers[key] ?? 0.0) + value;
    }

    // 3. Mana cap from buildings
    if (state.resourceModifiers.containsKey('max_mana_bonus')) {
      state.resourceMax['mana'] = 100.0 + state.resourceModifiers['max_mana_bonus']!;
    }

    // 4. Re-apply skill effects (with dynamic conditions)
    for (final skill in skillManager.unlocked.where((s) => s.equipped)) {
      switch (skill.effectId) {
        case 'undead_skill_2':
          if (state.getResource('population') > 50) {
            state.resourceModifiers['building_cost_multiplier'] =
                (state.resourceModifiers['building_cost_multiplier'] ?? 1.0) * 0.9;
          }
          break;

        case 'undead_skill_4':
          if (state.getResource('population') > 100) {
            state.resourceModifiers['spell_cooldown_mult'] =
                (state.resourceModifiers['spell_cooldown_mult'] ?? 1.0) * 0.9;
          }
          break;

        case 'orc_skill_2':
        // Battle Infrastructure: +10% building output
          state.resourceModifiers['building_output'] =
              (state.resourceModifiers['building_output'] ?? 1.0) * 1.10;
          break;

        case 'orc_skill_5':
          final taps = state.getMetaValue('taps_last_60s') ?? 0;
          final bonus = (taps ~/ 10) * 0.01;
          state.resourceModifiers['gold_income'] =
              (state.resourceModifiers['gold_income'] ?? 1.0) * (1.0 + bonus);
          break;

        default:
          skill.effect(state);
      }
    }
  }


  void startLoop() {
    _lastUpdate = DateTime.now();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastUpdate!).inMilliseconds / 1000.0;
      _lastUpdate = now;
      modifierManager.cleanup();
      applyFactionBonuses();
      tickResources(delta);
      saveGame();

      // ✅ Auto-taps trigger actual taps
      final autoTapsPerSecond = buildingService.getAutomatedTapsPerSecond();
      _autoTapAccumulator += autoTapsPerSecond * delta;
      final autoTapCount = _autoTapAccumulator.floor();
      _autoTapAccumulator -= autoTapCount;
      final autoTapMultiplier = state.resourceModifiers['auto_tap'] ?? 1.0;
      for (int i = 0; i < autoTapCount; i++) {
        tapGold(isAuto: true, multiplier: autoTapMultiplier);
      }


      conquestManager.checkFactionAnnihilation();
      resourceService.tickIncome(delta);
      notifyListeners();
    });
  }

  void resetForPrestige() {
    final old = state;

    // ✅ Apply remaining gold to lifetimeGold before wipe
    final goldBeforeReset = old.getResource('gold');
    prestigeService.applyGold(goldBeforeReset);

    // ✅ Preserve lifetimeGold
    final preservedLifetimeGold = prestigeService.lifetimeGold;

    final newState = GameState();
    state = newState;

    // ✅ Restore preserved lifetimeGold
    prestigeService.lifetimeGold = preservedLifetimeGold;

    // Preserve meta progression
    state.totalPrestiges = old.totalPrestiges;
    state.lifetimeTaps = old.lifetimeTaps;
    state.currentRunTaps = old.currentRunTaps;
    state.prestigePoints = old.prestigePoints;
    state.conquestUnlocked = old.conquestUnlocked;
    state.conquestIntroShown = old.conquestIntroShown;

    state.lifetimeResources
      ..clear()
      ..addAll(old.lifetimeResources);

    state.achievementsUnlocked
      ..clear()
      ..addAll(old.achievementsUnlocked);

    state.achievementsClaimed
      ..clear()
      ..addAll(old.achievementsClaimed);

    state.prestigeSkills
      ..clear()
      ..addAll(old.prestigeSkills);

    state.metaValues
      ..clear()
      ..addAll(old.metaValues);

    state.conqueredFactions
      ..clear()
      ..addAll(old.conqueredFactions);

    state.destroyedFactions
      ..clear()
      ..addAll(old.destroyedFactions);

    // Reset services
    modifierManager = ModifierManager();
    buildingService.reset();
    spellService.equippedSpells.clear();
    heroService.clearSelectedHeroes();
    skillManager.unlocked.forEach((s) {
      s.unlocked = false;
      s.equipped = false;
    });
    conquestManager.reset();
    factionManager.clearSelection();

    // Rebind
    heroService.attachState(state);
    heroService.loadUnlockedFromMeta(
      state.metaValues['unlocked_heroes'] as List<String>? ?? [],
    );

    applyFactionBonuses();
    notifyListeners();
  }

  void tapGold({bool isAuto = false, double multiplier = 1.0}) {
    // Count taps
    if (!isAuto) {
      state.currentRunTaps++;
      _tapTimestamps.add(DateTime.now());
    }
    state.lifetimeTaps++;
    tapCount++;

// 🕒 Prune old taps (older than 60 seconds)
    final now = DateTime.now();
    _tapTimestamps.removeWhere((ts) => now.difference(ts).inSeconds > 60);
    state.setMetaValue('taps_last_60s', _tapTimestamps.length.toDouble());

    final globalOutput =
        (state.resourceModifiers['global_output'] ?? 1.0) *
            (state.resourceModifiers['global_from_buildings'] ?? 1.0);
    final tapBase = state.tapPower * goldMultiplier * globalOutput * multiplier;

    // Base tap gold
    state.addResource('gold', tapBase);
    prestigeService.applyGold(tapBase);

    // Bloodfury: extra tap bonus
    if (modifierManager.hasModifier('bloodfury')) {
      state.addResource('gold', tapBase);
      prestigeService.applyGold(tapBase);
    }

    // Count taps
    if (!isAuto) state.currentRunTaps++;
    state.lifetimeTaps++;
    tapCount++;

    // Handle System Purge duration logic
    if (state.metaValues['system_purge_active'] == true) {
      final now = DateTime.now();
      final maxDur = state.metaValues['system_purge_max_duration'] ?? 0.0;

      if (maxDur > 1.0) {
        final newDuration = (maxDur - 1.0).clamp(1.0, 999.0);
        state.metaValues['system_purge_max_duration'] = newDuration;
        state.metaValues['system_purge_start_time'] = now.toIso8601String();

        modifierManager.addModifier(Modifier(
          id: 'global_output',
          multiplier: 1.25,
          duration: Duration(seconds: newDuration.toInt()),
        ));
      } else {
        state.metaValues['system_purge_active'] = false;
      }
    }

    _checkAchievements();
    notifyListeners();
  }

  void castSpell(Spell spell) {
    // Special case: Elf Spell 5 casts all other equipped spells
    if (spell.id == 'elf_spell_5') {
      spell.markCastTime();

      for (final s in spellService.equippedSpells) {
        if (s.id != 'elf_spell_5' && s.unlocked) {
          s.effect(state);
          s.lastCast = null;
        }
      }

      // 🔁 Inject equipped spells for any follow-up logic (not strictly needed here)
      state.metaValues['equipped_spells'] = spellService.equippedSpells;
      spell.effect(state);

      notifyListeners();
      _checkAchievements();
      return;
    }

    // ✅ Inject equipped spells before casting
    state.metaValues['equipped_spells'] = spellService.equippedSpells;

    // Default casting logic
    spellService.cast(spell, state);

    notifyListeners();
    _checkAchievements();
  }

  void _checkAchievements() {
    achievementService.evaluate(
      state: state,
      lifetimeGold: prestigeService.lifetimeGold,
      buildingsOwned: buildingService.allOwnedCount,
      tapCount: tapCount,
    );
  }
  void prepareStateForSave() {
    final state = this.state;
    if (factionManager.selected.isNotEmpty) {
      state.metaValues['selected_faction_id'] = factionManager.selected.first.id;
    }
    state.metaValues['lifetime_gold'] = prestigeService.lifetimeGold;
    // ✅ Spells
    state.equippedSpells
      ..clear()
      ..addAll(spellService.equippedSpells.map((s) => s.id));

    // ✅ Skills
    state.equippedSkills
      ..clear()
      ..addAll(skillManager.equippedSkills.map((s) => s.id));

    // ✅ Prestige
    state.prestigeSkills
      ..clear()
      ..addAll(prestigeService.getAllocatedSkills());
    state.prestigePoints = prestigeService.availablePoints;

    // ✅ Buildings
    state.buildingCounts
      ..clear()
      ..addAll(buildingService.buildingCounts); // Map<String, int>

    // ✅ Achievements
    state.achievementsUnlocked
      ..clear()
      ..addAll(achievementService.getUnlocked().map((a) => a.id));
    state.achievementsClaimed
      ..clear()
      ..addAll(achievementService.getClaimed().map((a) => a.id));

    // ✅ Factions
    state.conqueredFactions
      ..clear()
      ..addAll(conquestManager.conqueredFactions);
    state.destroyedFactions
      ..clear()
      ..addAll(conquestManager.destroyedFactions);
  }

  void restoreFromState() {
    final state = this.state;
    final savedGold = state.metaValues['lifetime_gold'];
    if (savedGold is num) {
      prestigeService.lifetimeGold = savedGold.toDouble();
    }
    // ✅ Spells
    spellService.setEquipped(state.equippedSpells);

    // ✅ Skills
    skillManager.setEquipped(state.equippedSkills);
    final selectedId = state.metaValues['selected_faction_id'] as String?;
    if (selectedId != null) {
      final match = factionManager.allFactions.firstWhere(
            (f) => f.id == selectedId,
      );
      if (match != null) {
        factionManager.selectOnly(match.id); // ✅
      }
    }

    // ✅ Prestige
    prestigeService.setAllocated(state.prestigeSkills);
    prestigeService.setAvailablePoints(state.prestigePoints);

    // ✅ Buildings
    buildingService.setBuildingCounts(state.buildingCounts);

    // ✅ Achievements
    achievementService.setUnlocked(state.achievementsUnlocked);
    achievementService.setClaimed(state.achievementsClaimed);

    // ✅ Factions
    conquestManager.setConquered(state.conqueredFactions);
    conquestManager.setDestroyed(state.destroyedFactions);
  }

  void buyBuilding(Building building) {
    buildingService.buy(building, state, modifierManager);
    applyFactionBonuses();
    _checkAchievements();
    notifyListeners();
  }

  void addGoldAdModifier() {
    final now = DateTime.now();
    final endTimeKey = 'gold_ad_bonus_ends';

    // Restore or extend duration
    final existingEndStr = state.metaValues[endTimeKey] as String?;
    DateTime existingEnd = existingEndStr != null ? DateTime.tryParse(existingEndStr) ?? now : now;
    if (existingEnd.isBefore(now)) existingEnd = now;

    final newEnd = existingEnd.add(const Duration(hours: 4));
    state.metaValues[endTimeKey] = newEnd.toIso8601String();

    final duration = newEnd.difference(now);

    modifierManager.addModifier(
      Modifier(
        id: 'gold',
        multiplier: 2.0,
        duration: duration,
      ),
    );

    notifyListeners();
  }

  double get gold => state.getResource('gold');

  double get goldMultiplier =>
      (state.resourceModifiers['gold_income'] ?? 1.0) *
          modifierManager.getCombinedMultiplier('gold') *
          modifierManager.getCombinedMultiplier('gold_income_multiplier') *
          prestigeService.prestigeMultiplier;

  double get goldBoostSecondsLeft =>
      modifierManager.getRemainingTimeFor("gold");

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }
  Future<void> saveGame() async {
    prepareStateForSave();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('game_state', json.encode(state.toJson()));
    prefs.setString('last_active', DateTime.now().toIso8601String());
  }

  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('game_state');
    final lastActiveStr = prefs.getString('last_active');

    if (savedJson != null) {
      state = GameState.fromJson(json.decode(savedJson));

      if (lastActiveStr != null) {
        final lastActive = DateTime.tryParse(lastActiveStr);
        if (lastActive != null) {
          final now = DateTime.now();
          final diffSeconds = now.difference(lastActive).inSeconds;
          final cappedSeconds = diffSeconds.clamp(0, 8 * 3600); // Max 8 hours
          tickResources(cappedSeconds.toDouble());
        }
      }
    }
  }
}
