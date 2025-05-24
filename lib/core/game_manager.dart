import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool get hasSelectedFaction => factionManager.selected.isNotEmpty;

  Timer? _loopTimer;
  DateTime? _lastUpdate;
  int tapCount = 0;
  Future<void> init() async {
    if (_initialized) return;

    // Base state
    state = GameState();
    state.addResource('gold', 0);
    state.addResource('mana', 0);

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

    startLoop();

    _initialized = true;
  }

  void tickResources(double deltaSeconds) {
    state.resourceAmounts.forEach((id, _) {
      final base = buildingService.totalOutputPerSecond(resource: id);
      final baseIncome = id == 'mana' ? 1.0 : 0.0;

      double multiplier = 1.0;
      if (id == 'gold') {
        multiplier = goldMultiplier;
      } else if (id == 'mana') {
        multiplier = state.resourceModifiers['mana_regen'] ?? 1.0;
      } else {
        multiplier = state.resourceModifiers['${id}_multiplier'] ?? 1.0;
      }

      final incomePerSecond = (base + baseIncome) * multiplier;
      final incomeDelta = incomePerSecond * deltaSeconds;

      state.addResource(id, incomeDelta);
      state.resourceModifiers['${id}_per_sec'] = incomePerSecond;
    });

    // ✅ Apply hero effects again (in case tickResources runs before applyFactionBonuses)
    final lifetimeMultiplier = 1 + (log(prestigeService.lifetimeGold + 1) / 100);
    heroService.applySelectedHeroes(state, lifetimeMultiplier);

    // ✅ Ensure conquest unlock is reapplied after claiming achievement
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

    // ✅ 4. Re-apply skill effects for unlocked & equipped skills
    for (final skill in skillManager.unlocked.where((s) => s.equipped)) {
      skill.effect(state);
    }
  }

  void startLoop() {

    _lastUpdate = DateTime.now();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastUpdate!).inMilliseconds / 1000.0;
      _lastUpdate = now;

      modifierManager.cleanup();

      final goldMultiplier = (state.resourceModifiers['gold_income'] ?? 1.0) *
          modifierManager.getCombinedMultiplier('gold') *
          prestigeService.prestigeMultiplier;

      final goldIncome = buildingService.totalOutputPerSecond(resource: 'gold');
      final goldGain = goldIncome * delta * goldMultiplier;
      state.addResource('gold', goldGain);
      prestigeService.applyGold(goldGain);

      final manaMultiplier = state.resourceModifiers['mana_regen'] ?? 1.0;
      final baseManaRegen = 1.0;
      final manaIncome = baseManaRegen + buildingService.totalOutputPerSecond(resource: 'mana');
      state.addResource('mana', manaIncome * delta * manaMultiplier);

      final autoTaps = buildingService.getAutomatedTapsPerSecond();
      final autoTapGain = autoTaps * state.tapPower * goldMultiplier * delta;
      state.addResource('gold', autoTapGain);
      prestigeService.applyGold(autoTapGain);
      tapCount += autoTaps.toInt(); // Optional if you want auto-taps to count
      conquestManager.checkFactionAnnihilation();
      resourceService.tickIncome(delta);
      notifyListeners();
    });
  }

  void resetForPrestige() {
    final preservedTotalPrestiges = state.totalPrestiges;
    final preservedLifetimeTaps = state.lifetimeTaps;
    final preservedLifetimeResources = Map<String, double>.from(state.lifetimeResources);
    final preservedConquestUnlocked = state.conquestUnlocked;
    final preservedConquestIntro = state.conquestIntroShown;
    final unlockedConquest = state.conquestUnlocked;

    state.totalPrestiges = preservedTotalPrestiges;
    state.conquestUnlocked = preservedConquestUnlocked;
    state.lifetimeTaps = preservedLifetimeTaps;
    state.lifetimeResources.addAll(preservedLifetimeResources);
    achievementService.applyClaimedRewards(state);
    state.conquestUnlocked = unlockedConquest; // restore conquestUnlocked
    state.conquestIntroShown = preservedConquestIntro;
    state.resourceAmounts.updateAll((key, _) => 0.0);
    state.resourceModifiers.clear();
    state.resourceMax.updateAll((key, _) => key == 'mana' ? 100.0 : 100.0);
    state.tapPower = 1.0;
    state.currentRunTaps = 0;

    resourceManager.current.updateAll((key, _) => 0.0);
    resourceService = ResourceService(resourceManager);
    state.conqueredFactions.clear();
    conquestManager.reset();  // clears ConquestManager.conqueredFactions and state
    buildingService.reset();
    spellService.equippedSpells.clear();
    heroService.clearSelectedHeroes();

    for (final skill in skillManager.allSkills) {
      skill.unlocked = false;
      skill.equipped = false;
    }

    conquestManager.reset();
    factionManager.clearSelection();
    notifyListeners();
    checkForPassiveUnlocks();
  }

  void tapGold() {
    final multiplier = goldMultiplier;
    final tapGain = state.tapPower * multiplier;
    state.addResource('gold', tapGain);
    prestigeService.applyGold(tapGain);

    state.currentRunTaps++;
    state.lifetimeTaps++;
    tapCount++;

    _checkAchievements();
    notifyListeners();
  }


  void castSpell(Spell spell) {
    spellService.cast(spell, state);
    _checkAchievements();
    notifyListeners();
  }

  void _checkAchievements() {
    achievementService.evaluate(
      state: state,
      lifetimeGold: prestigeService.lifetimeGold,
      buildingsOwned: buildingService.allOwnedCount,
      tapCount: tapCount,
    );
  }

  void buyBuilding(Building building) {
    buildingService.buy(building, state);
    applyFactionBonuses(); // ← Refresh bonuses
    _checkAchievements();
    notifyListeners();
  }


  void addGoldAdModifier() {
    modifierManager.addModifier(
      Modifier(
        id: 'gold',
        multiplier: 1000000.0,
        duration: const Duration(hours: 4),
      ),
    );
    notifyListeners();
  }

  double get gold => state.getResource('gold');

  double get goldMultiplier =>
      modifierManager.getCombinedMultiplier('gold') * prestigeService.prestigeMultiplier;

  double get goldBoostSecondsLeft =>
      modifierManager.getRemainingTimeFor("gold");

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }
}
