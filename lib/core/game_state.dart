class GameState {
  // Core resource tracking
  final Map<String, double> resourceAmounts = {
    'gold': 100.0,
    'mana': 100.0,
    'ore': 0.0,
    'population': 0.0,
  };

  final Map<String, double> lifetimeResources = {
    'gold': 0.0,
    'mana': 0.0,
    'ore': 0.0,
    'population': 0.0,
  };

  final Map<String, double> resourceModifiers = {};
  final Map<String, double> resourceMax = {
    'mana': 100.0,
    'population': 0.0,
  };
  double getManaRegenPerSecond() {
    return resourceModifiers['mana_per_sec'] ?? 0.0;
  }

  final Map<String, dynamic> metaValues = {};

  // Game progression
  double tapPower = 1.0;
  int prestigeLevel = 0;
  int prestigePoints = 0;
  int usedPrestigePoints = 0;
  int spellUpgradeLevel = 0;
  int factionUpgradeLevel = 0;
  int extraSkillPointsBought = 0;
  int goldBonusLevel = 0;
  int manaBonusLevel = 0;
  int oreBonusLevel = 0;
  int buildingDiscountLevel = 0;
  int tapPowerLevel = 0;
  int cooldownReductionLevel = 0;
  int populationGrowthLevel = 0;
  int autoTapLevel = 0;
  int globalOutputLevel = 0;
  int spellCostReductionLevel = 0;
  final Set<String> prestigeSkills = {};
  bool adGoldBoostActive = false;
  int adGoldBoostRemainingSeconds = 0;
  List<DateTime> recentSpellCastTimestamps = [];
  int totalSpellsCast = 0;
  int highestSpellChain = 0;
  // Features and flags
  bool heroesUnlocked = false;
  bool conquestUnlocked = false;
  bool conquestIntroShown = false;
  bool tutorialShown = false;
  bool firstPrestigeGuideDone = false;

  // Stats
  int lifetimeTaps = 0;
  int currentRunTaps = 0;
  int totalPrestiges = 0;
  Duration currentRunTime = Duration.zero;
  Duration totalPlayTime = Duration.zero;
  DateTime currentRunStart = DateTime.now();

  // Player progress and unlocks
  final Set<String> conqueredFactions = {};
  final Set<String> destroyedFactions = {};
  final Set<String> achievementsUnlocked = {};
  final Set<String> achievementsClaimed = {};
  final Set<String> unlockedSpells = {};
  final Set<String> unlockedSkills = {};

  // Gameplay state
  final Map<String, int> buildingCounts = {};
  final List<String> equippedSpells = [];
  final List<String> equippedSkills = [];
  DateTime sessionStartTime = DateTime.now();
  DateTime lastPrestigeTime = DateTime.now();

  Map<String, DateTime> timedAchievementStartTimes = {};


  void resetTimers() {
    sessionStartTime = DateTime.now();
    lastPrestigeTime = DateTime.now();
    timedAchievementStartTimes.clear();
  }
  // ====== Serialization ======

  Map<String, dynamic> toJson() {
    return {
      'resourceAmounts': resourceAmounts,
      'lifetimeResources': lifetimeResources,
      'resourceModifiers': resourceModifiers,
      'resourceMax': resourceMax,
      'metaValues': metaValues.map((k, v) {
        if (v is num || v is String || v is bool || v == null) {
          return MapEntry(k, v);
        } else if (v is DateTime) {
          return MapEntry(k, v.toIso8601String());
        } else if (v is Duration) {
          return MapEntry(k, v.inSeconds);
        } else {
          return MapEntry(k, null);
        }
      }),
      'tapPower': tapPower,
      'adGoldBoostActive': adGoldBoostActive,
      'adGoldBoostRemainingSeconds': adGoldBoostRemainingSeconds,
      'prestigeMultiplier': metaValues['prestigeMultiplier'] ?? 1.0,
      'prestigeLevel': prestigeLevel,
      'prestigePoints': prestigePoints,
      'usedPrestigePoints': usedPrestigePoints,
      'spellUpgradeLevel': spellUpgradeLevel,
      'factionUpgradeLevel': factionUpgradeLevel,
      'extraSkillPointsBought': extraSkillPointsBought,
      'goldBonusLevel': goldBonusLevel,
      'manaBonusLevel': manaBonusLevel,
      'oreBonusLevel': oreBonusLevel,
      'buildingDiscountLevel': buildingDiscountLevel,
      'tapPowerLevel': tapPowerLevel,
      'cooldownReductionLevel': cooldownReductionLevel,
      'populationGrowthLevel': populationGrowthLevel,
      'autoTapLevel': autoTapLevel,
      'globalOutputLevel': globalOutputLevel,
      'spellCostReductionLevel': spellCostReductionLevel,
      'prestigeSkills': prestigeSkills.toList(),
      'heroesUnlocked': heroesUnlocked,
      'conquestUnlocked': conquestUnlocked,
      'conquestIntroShown': conquestIntroShown,
      'tutorialShown': tutorialShown,
      'firstPrestigeGuideDone': firstPrestigeGuideDone,
      'lifetimeTaps': lifetimeTaps,
      'currentRunTaps': currentRunTaps,
      'totalPrestiges': totalPrestiges,
      'conqueredFactions': conqueredFactions.toList(),
      'destroyedFactions': destroyedFactions.toList(),
      'achievementsUnlocked': achievementsUnlocked.toList(),
      'achievementsClaimed': achievementsClaimed.toList(),
      'unlockedSpells': unlockedSpells.toList(),
      'unlockedSkills': unlockedSkills.toList(),
      'buildingCounts': buildingCounts,
      'equippedSpells': equippedSpells,
      'equippedSkills': equippedSkills,
      'currentRunTime': currentRunTime.inSeconds,
      'totalPlayTime': totalPlayTime.inSeconds,
      'currentRunStart': currentRunStart.toIso8601String(),
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final state = GameState();
    state.adGoldBoostActive = json['adGoldBoostActive'] ?? false;
    state.adGoldBoostRemainingSeconds = json['adGoldBoostRemainingSeconds'] ?? 0;
    state.resourceAmounts.addAll(Map<String, double>.from(json['resourceAmounts'] ?? {}));
    state.lifetimeResources.addAll(Map<String, double>.from(json['lifetimeResources'] ?? {}));
    state.resourceModifiers.addAll(Map<String, double>.from(json['resourceModifiers'] ?? {}));
    state.resourceMax.addAll(Map<String, double>.from(json['resourceMax'] ?? {}));
    state.metaValues.addAll(Map<String, dynamic>.from(json['metaValues'] ?? {}));
    state.currentRunTime = Duration(seconds: json['currentRunTime'] ?? 0);
    state.totalPlayTime = Duration(seconds: json['totalPlayTime'] ?? 0);
    state.currentRunStart = DateTime.tryParse(json['currentRunStart'] ?? '') ?? DateTime.now();
    final multiplier = (json['prestigeMultiplier'] ?? 1.0) as num;
    state.metaValues['prestigeMultiplier'] = multiplier.toDouble();

    state.tapPower = (json['tapPower'] ?? 1.0).toDouble();
    state.prestigeLevel = (json['prestigeLevel'] ?? 0) as int;
    state.prestigePoints = (json['prestigePoints'] ?? 0) as int;
    state.usedPrestigePoints = (json['usedPrestigePoints'] ?? 0) as int;
    state.spellUpgradeLevel = (json['spellUpgradeLevel'] ?? 0) as int;
    state.factionUpgradeLevel = (json['factionUpgradeLevel'] ?? 0) as int;
    state.extraSkillPointsBought = (json['extraSkillPointsBought'] ?? 0) as int;
    state.goldBonusLevel = (json['goldBonusLevel'] ?? 0) as int;
    state.manaBonusLevel = (json['manaBonusLevel'] ?? 0) as int;
    state.oreBonusLevel = (json['oreBonusLevel'] ?? 0) as int;
    state.buildingDiscountLevel = (json['buildingDiscountLevel'] ?? 0) as int;
    state.tapPowerLevel = (json['tapPowerLevel'] ?? 0) as int;
    state.cooldownReductionLevel = (json['cooldownReductionLevel'] ?? 0) as int;
    state.populationGrowthLevel = (json['populationGrowthLevel'] ?? 0) as int;
    state.autoTapLevel = (json['autoTapLevel'] ?? 0) as int;
    state.globalOutputLevel = (json['globalOutputLevel'] ?? 0) as int;
    state.spellCostReductionLevel = (json['spellCostReductionLevel'] ?? 0) as int;

    state.prestigeSkills.addAll(List<String>.from(json['prestigeSkills'] ?? []));

    state.heroesUnlocked = json['heroesUnlocked'] ?? false;
    state.conquestUnlocked = json['conquestUnlocked'] ?? false;
    state.conquestIntroShown = json['conquestIntroShown'] ?? false;
    state.tutorialShown = json['tutorialShown'] ?? false;
    state.firstPrestigeGuideDone = json['firstPrestigeGuideDone'] ?? false;

    state.lifetimeTaps = json['lifetimeTaps'] ?? 0;
    state.currentRunTaps = json['currentRunTaps'] ?? 0;
    state.totalPrestiges = json['totalPrestiges'] ?? 0;

    state.conqueredFactions.addAll(List<String>.from(json['conqueredFactions'] ?? []));
    state.destroyedFactions.addAll(List<String>.from(json['destroyedFactions'] ?? []));
    state.achievementsUnlocked.addAll(List<String>.from(json['achievementsUnlocked'] ?? []));
    state.achievementsClaimed.addAll(List<String>.from(json['achievementsClaimed'] ?? []));
    state.unlockedSpells.addAll(List<String>.from(json['unlockedSpells'] ?? []));
    state.unlockedSkills.addAll(List<String>.from(json['unlockedSkills'] ?? []));

    state.buildingCounts.addAll(Map<String, int>.from(json['buildingCounts'] ?? {}));
    state.equippedSpells.addAll(List<String>.from(json['equippedSpells'] ?? []));
    state.equippedSkills.addAll(List<String>.from(json['equippedSkills'] ?? []));

    return state;
  }

  // ====== Game Logic Helpers ======

  Map<String, double> snapshot() => Map.from(resourceAmounts);

  double getResource(String id) => resourceAmounts[id] ?? 0.0;

  double getMax(String id) => resourceMax[id] ?? double.infinity;

  void addResource(String id, double amount) {
    final current = getResource(id);
    final max = getMax(id);
    final newValue = (current + amount).clamp(0.0, max);
    resourceAmounts[id] = newValue;
    lifetimeResources[id] = (lifetimeResources[id] ?? 0.0) + amount;
  }

  void spendResource(String id, double amount) {
    final current = getResource(id);
    if (current >= amount) {
      resourceAmounts[id] = current - amount;
    }
  }

  bool canAfford(Map<String, double> costs) {
    return costs.entries.every((entry) => getResource(entry.key) >= entry.value);
  }

  bool trySpend(Map<String, double> costs) {
    if (!canAfford(costs)) return false;
    for (final entry in costs.entries) {
      spendResource(entry.key, entry.value);
    }
    return true;
  }
  void preserveMetaFrom(GameState old) {
    totalPrestiges = old.totalPrestiges;
    lifetimeTaps = old.lifetimeTaps;

    lifetimeResources
      ..clear()
      ..addAll(old.lifetimeResources);

    achievementsUnlocked
      ..clear()
      ..addAll(old.achievementsUnlocked);

    achievementsClaimed
      ..clear()
      ..addAll(old.achievementsClaimed);

    prestigeSkills
      ..clear()
      ..addAll(old.prestigeSkills);

    prestigePoints = old.prestigePoints;
    usedPrestigePoints = old.usedPrestigePoints;
    spellUpgradeLevel = old.spellUpgradeLevel;
    factionUpgradeLevel = old.factionUpgradeLevel;
    extraSkillPointsBought = old.extraSkillPointsBought;
    goldBonusLevel = old.goldBonusLevel;
    manaBonusLevel = old.manaBonusLevel;
    oreBonusLevel = old.oreBonusLevel;
    buildingDiscountLevel = old.buildingDiscountLevel;
    tapPowerLevel = old.tapPowerLevel;
    cooldownReductionLevel = old.cooldownReductionLevel;
    populationGrowthLevel = old.populationGrowthLevel;
    autoTapLevel = old.autoTapLevel;
    globalOutputLevel = old.globalOutputLevel;
    spellCostReductionLevel = old.spellCostReductionLevel;

    metaValues
      ..clear()
      ..addAll(old.metaValues);

    conquestUnlocked = old.conquestUnlocked;
    conquestIntroShown = old.conquestIntroShown;
    tutorialShown = old.tutorialShown;
    firstPrestigeGuideDone = old.firstPrestigeGuideDone;
  }

  void setMax(String id, double max) {
    resourceMax[id] = max;
  }

  double getMetaValue(String key) {
    final value = metaValues[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }

  void setMetaValue(String key, double value) {
    metaValues[key] = value;
  }

  void incrementMetaValue(String key, double amount) {
    metaValues[key] = getMetaValue(key) + amount;
  }

  // ====== Reset Logic ======

  void reset() {
    resourceAmounts.updateAll((key, _) => 0.0);
    resourceModifiers.clear();
    resourceMax.updateAll((key, _) => key == 'mana' ? 100.0 : 100.0);
    metaValues.clear();
    tapPower = 1.0;
    prestigeLevel = 0;
    prestigePoints = 0;
    usedPrestigePoints = 0;
    spellUpgradeLevel = 0;
    factionUpgradeLevel = 0;
    extraSkillPointsBought = 0;
    goldBonusLevel = 0;
    manaBonusLevel = 0;
    oreBonusLevel = 0;
    buildingDiscountLevel = 0;
    tapPowerLevel = 0;
    cooldownReductionLevel = 0;
    populationGrowthLevel = 0;
    autoTapLevel = 0;
    globalOutputLevel = 0;
    spellCostReductionLevel = 0;
    currentRunTaps = 0;
    totalPrestiges = 0;
    heroesUnlocked = false;
    conquestUnlocked = false;
    conquestIntroShown = false;
    tutorialShown = false;
    firstPrestigeGuideDone = false;
    conqueredFactions.clear();
    destroyedFactions.clear();
    achievementsUnlocked.clear();
    achievementsClaimed.clear();
    buildingCounts.clear();
    equippedSpells.clear();
    equippedSkills.clear();
    prestigeSkills.clear();
  }
}
