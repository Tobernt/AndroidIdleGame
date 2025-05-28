class GameState {
  // Core resource tracking
  final Map<String, double> resourceAmounts = {
    'gold': 0.0,
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

  final Map<String, dynamic> metaValues = {};

  // Game progression
  double tapPower = 1.0;
  int prestigeLevel = 0;
  int prestigePoints = 0;
  final Set<String> prestigeSkills = {};
  bool adGoldBoostActive = false;
  int adGoldBoostRemainingSeconds = 0;

  // Features and flags
  bool heroesUnlocked = false;
  bool conquestUnlocked = false;
  bool conquestIntroShown = false;

  // Stats
  int lifetimeTaps = 0;
  int currentRunTaps = 0;
  int totalPrestiges = 0;

  // Player progress and unlocks
  final Set<String> conqueredFactions = {};
  final Set<String> destroyedFactions = {};
  final Set<String> achievementsUnlocked = {};
  final Set<String> achievementsClaimed = {};

  // Gameplay state
  final Map<String, int> buildingCounts = {};
  final List<String> equippedSpells = [];
  final List<String> equippedSkills = [];

  // ====== Serialization ======

  Map<String, dynamic> toJson() {
    return {
      'resourceAmounts': resourceAmounts,
      'lifetimeResources': lifetimeResources,
      'resourceModifiers': resourceModifiers,
      'resourceMax': resourceMax,
      'metaValues': metaValues,
      'tapPower': tapPower,
      'adGoldBoostActive': adGoldBoostActive,
      'adGoldBoostRemainingSeconds': adGoldBoostRemainingSeconds,
      'prestigeLevel': prestigeLevel,
      'prestigePoints': prestigePoints,
      'prestigeSkills': prestigeSkills.toList(),
      'heroesUnlocked': heroesUnlocked,
      'conquestUnlocked': conquestUnlocked,
      'conquestIntroShown': conquestIntroShown,
      'lifetimeTaps': lifetimeTaps,
      'currentRunTaps': currentRunTaps,
      'totalPrestiges': totalPrestiges,
      'conqueredFactions': conqueredFactions.toList(),
      'destroyedFactions': destroyedFactions.toList(),
      'achievementsUnlocked': achievementsUnlocked.toList(),
      'achievementsClaimed': achievementsClaimed.toList(),
      'buildingCounts': buildingCounts,
      'equippedSpells': equippedSpells,
      'equippedSkills': equippedSkills,
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

    state.tapPower = (json['tapPower'] ?? 1.0).toDouble();
    state.prestigeLevel = (json['prestigeLevel'] ?? 0) as int;
    state.prestigePoints = (json['prestigePoints'] ?? 0) as int;

    state.prestigeSkills.addAll(List<String>.from(json['prestigeSkills'] ?? []));

    state.heroesUnlocked = json['heroesUnlocked'] ?? false;
    state.conquestUnlocked = json['conquestUnlocked'] ?? false;
    state.conquestIntroShown = json['conquestIntroShown'] ?? false;

    state.lifetimeTaps = json['lifetimeTaps'] ?? 0;
    state.currentRunTaps = json['currentRunTaps'] ?? 0;
    state.totalPrestiges = json['totalPrestiges'] ?? 0;

    state.conqueredFactions.addAll(List<String>.from(json['conqueredFactions'] ?? []));
    state.destroyedFactions.addAll(List<String>.from(json['destroyedFactions'] ?? []));
    state.achievementsUnlocked.addAll(List<String>.from(json['achievementsUnlocked'] ?? []));
    state.achievementsClaimed.addAll(List<String>.from(json['achievementsClaimed'] ?? []));

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

    metaValues
      ..clear()
      ..addAll(old.metaValues);

    conquestUnlocked = old.conquestUnlocked;
    conquestIntroShown = old.conquestIntroShown;
  }

  void setMax(String id, double max) {
    resourceMax[id] = max;
  }

  double getMetaValue(String key) => metaValues[key] ?? 0.0;

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
    currentRunTaps = 0;
    totalPrestiges = 0;
    heroesUnlocked = false;
    conquestUnlocked = false;
    conquestIntroShown = false;
    conqueredFactions.clear();
    destroyedFactions.clear();
    achievementsUnlocked.clear();
    achievementsClaimed.clear();
    buildingCounts.clear();
    equippedSpells.clear();
    equippedSkills.clear();
    prestigeSkills.clear();
  }

  void resetForPrestige() {
    resourceAmounts.updateAll((key, _) => 0.0);
    resourceModifiers.clear();
    resourceMax.updateAll((key, _) => key == 'mana' ? 100.0 : 100.0);
    metaValues.clear();
    tapPower = 1.0;
    currentRunTaps = 0;

    // Keep some values, clear others
    conqueredFactions.clear();
    buildingCounts.clear();
    equippedSpells.clear();
    equippedSkills.clear();
  }
}
