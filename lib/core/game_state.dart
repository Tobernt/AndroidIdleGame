class GameState {
  Map<String, dynamic> toJson() {
    return {
      'resourceAmounts': resourceAmounts,
      'resourceModifiers': resourceModifiers,
      'resourceMax': resourceMax,
      'metaValues': metaValues,
      'tapPower': tapPower,
      'prestigeLevel': prestigeLevel,
      'heroesUnlocked': heroesUnlocked,
      'conquestUnlocked': conquestUnlocked,
      'conquestIntroShown': conquestIntroShown,
      'lifetimeTaps': lifetimeTaps,
      'currentRunTaps': currentRunTaps,
      'totalPrestiges': totalPrestiges,
      'lifetimeResources': lifetimeResources,
      'conqueredFactions': conqueredFactions.toList(),
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final state = GameState();
    state.resourceAmounts.addAll(Map<String, double>.from(json['resourceAmounts']));
    state.resourceModifiers.addAll(Map<String, double>.from(json['resourceModifiers']));
    state.resourceMax.addAll(Map<String, double>.from(json['resourceMax']));
    state.metaValues.addAll(Map<String, dynamic>.from(json['metaValues']));
    state.tapPower = json['tapPower'];
    state.prestigeLevel = json['prestigeLevel'];
    state.heroesUnlocked = json['heroesUnlocked'];
    state.conquestUnlocked = json['conquestUnlocked'];
    state.conquestIntroShown = json['conquestIntroShown'];
    state.lifetimeTaps = json['lifetimeTaps'];
    state.currentRunTaps = json['currentRunTaps'];
    state.totalPrestiges = json['totalPrestiges'];
    state.lifetimeResources.addAll(Map<String, double>.from(json['lifetimeResources']));
    state.conqueredFactions.addAll(List<String>.from(json['conqueredFactions']));
    return state;
  }

  // Core resource tracking
  final Map<String, double> resourceAmounts = {
    'gold': 0.0,
    'mana': 100.0,
    'ore': 0.0,
    'population': 0.0,
    'essence': 0.0,
    'crystals': 0.0,
  };

  // Lifetime total resources gained (not reset on prestige)
  final Map<String, double> lifetimeResources = {
    'gold': 0.0,
    'mana': 0.0,
    'ore': 0.0,
    'population': 0.0,
    'essence': 0.0,
    'crystals': 0.0,
  };

  // Multipliers and effects from skills, buildings, bonuses
  final Map<String, double> resourceModifiers = {};
  final Set<String> conqueredFactions = {};
  final Set<String> destroyedFactions = {};

  // Max caps for resources (can be overridden by skills or buildings)
  final Map<String, double> resourceMax = {
    'mana': 100.0,
    'population': 0.0,
  };

  // Meta values (for tracking purposes like "mana_spent_last_30s")
  final Map<String, dynamic> metaValues = {};

  // Progression values
  double tapPower = 1.0;
  int prestigeLevel = 0;

  // ✅ Persistent flags
  bool heroesUnlocked = false;
  bool conquestUnlocked = false;
  bool conquestIntroShown = false;

  // Lifetime & run stats
  int lifetimeTaps = 0;
  int currentRunTaps = 0;
  int totalPrestiges = 0;

  Map<String, double> snapshot() => Map.from(resourceAmounts);

  // ====== Resource Logic ======

  double getResource(String id) => resourceAmounts[id] ?? 0.0;

  double getMax(String id) => resourceMax[id] ?? double.infinity;

  void addResource(String id, double amount) {
    final current = getResource(id);
    final max = getMax(id);
    final newValue = (current + amount).clamp(0.0, max);
    resourceAmounts[id] = newValue;

    // Track lifetime separately
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

  void setMax(String id, double max) {
    resourceMax[id] = max;
  }

  // ====== Meta Logic ======

  double getMetaValue(String key) => metaValues[key] ?? 0.0;

  void setMetaValue(String key, double value) {
    metaValues[key] = value;
  }

  void incrementMetaValue(String key, double amount) {
    metaValues[key] = getMetaValue(key) + amount;
  }

  // ====== Reset Logic ======

  /// ❌ This is used for full game reset — conquest flags should stay
  void reset() {
    resourceAmounts.updateAll((key, _) => 0.0);
    resourceModifiers.clear();
    resourceMax.updateAll((key, _) => key == 'mana' ? 100.0 : 100.0);
    metaValues.clear();
    tapPower = 1.0;
    prestigeLevel = 0;
    currentRunTaps = 0;
    heroesUnlocked = false;

  }

  /// ✅ This is used during prestige and must preserve conquest/hero flags
  void resetForPrestige() {
    resourceAmounts.updateAll((key, _) => 0.0);
    resourceModifiers.clear();
    resourceMax.updateAll((key, _) => key == 'mana' ? 100.0 : 100.0);
    metaValues.clear();
    tapPower = 1.0;
    currentRunTaps = 0;

    // Clear the list of conquered factions on prestige (do NOT reset conquestUnlocked):
    conqueredFactions.clear();
  }
}
