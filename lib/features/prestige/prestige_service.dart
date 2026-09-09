import 'dart:math';
import '../../core/game_state.dart';

class PrestigeService {
  int prestigeLevel = 0;
  double lifetimeGold = 0;
  double preservedLifetimeGold = 0;
  double _prestigedMultiplier = 1.0;

  int _calcCost(double base, double growth, int level) =>
      (base * pow(growth, level)).ceil();

  int costForNextSpellSlot() => _calcCost(25, 3, _spellSlotUpgrades);
  int costForNextFactionSlot() => _calcCost(50, 3, _factionSlotUpgrades);
  int costForNextSkillPoint() => _calcCost(20, 2, _extraSkillPointsBought);
  int costForNextGoldBonus() => _calcCost(20, 2, _goldBonusUpgrades);
  int costForNextManaBonus() => _calcCost(15, 1.8, _manaBonusUpgrades);
  int costForNextOreBonus() => _calcCost(15, 2, _oreBonusUpgrades);
  int costForNextBuildingDiscount() =>
      _calcCost(30, 2, _buildingDiscountUpgrades);
  int costForNextTapPower() => _calcCost(10, 1.7, _tapPowerUpgrades);
  int costForNextCooldownBonus() => _calcCost(25, 2, _cooldownUpgrades);
  int costForNextPopulationBonus() => _calcCost(10, 1.5, _populationUpgrades);
  int costForNextAutoTap() => _calcCost(15, 1.7, _autoTapUpgrades);
  int costForNextGlobalOutput() => _calcCost(30, 2.5, _globalOutputUpgrades);
  int costForNextSpellCostReduction() =>
      _calcCost(25, 2, _spellCostReductionUpgrades);

  // Prestige currency
  int prestigePoints = 0;
  int _usedPrestigePoints = 0;

  // Upgrade states
  int _spellSlotUpgrades = 0;
  int _factionSlotUpgrades = 0;
  int _extraSkillPointsBought = 0;
  int _goldBonusUpgrades = 0;
  int _manaBonusUpgrades = 0;
  int _oreBonusUpgrades = 0;
  int _buildingDiscountUpgrades = 0;
  int _tapPowerUpgrades = 0;
  int _cooldownUpgrades = 0;
  int _populationUpgrades = 0;
  int _autoTapUpgrades = 0;
  int _globalOutputUpgrades = 0;
  int _spellCostReductionUpgrades = 0;

  // Skill point usage tracking
  int _spentSkillPoints = 0;


  /// Upgrade limits
  static const int maxSpellSlotLimit = 5;
  static const int maxFactionSlotLimit = 3;
  static const int maxTotalSkillPoints = 15;

  double get prestigeMultiplier => _prestigedMultiplier;
  set prestigeMultiplier(double value) => _prestigedMultiplier = value;

  int get totalSkillPoints =>
      min(maxTotalSkillPoints, _extraSkillPointsBought);

  int get availableSkillPoints => totalSkillPoints - _spentSkillPoints;
  int get availablePrestigePoints => prestigePoints - _usedPrestigePoints;

  int get maxEquippedSpells => 1 + _spellSlotUpgrades;
  int get maxFactions => 1 + _factionSlotUpgrades;
  final Set<String> allocatedSkillIds = {};
  int availablePoints = 0;

  Set<String> getAllocatedSkills() => allocatedSkillIds;

  void setAllocated(Set<String> ids) {
    allocatedSkillIds
      ..clear()
      ..addAll(ids);
  }

  void setAvailablePoints(int points) {
    availablePoints = points;
  }

  void applyGold(double amount) {
    lifetimeGold += amount;
  }

  void prestige(GameState state) {

    // 1 point per 100k active gold
    final earnedPoints = (state.getResource('gold') / 100000).floor();
    prestigePoints += earnedPoints;

    final bonus = 1 + (log(1 + lifetimeGold) / 10);
    _prestigedMultiplier = max(_prestigedMultiplier, bonus);

    _spentSkillPoints = 0;

    checkConquestUnlock(state);
  }

  bool spendSkillPoints(int cost) {
    if (availableSkillPoints >= cost) {
      _spentSkillPoints += cost;
      return true;
    }
    return false;
  }

  bool buySpellSlot() {
    final cost = costForNextSpellSlot();
    if (availablePrestigePoints >= cost && _spellSlotUpgrades < maxSpellSlotLimit - 1) {
      _spellSlotUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyFactionSlot() {
    final cost = costForNextFactionSlot();
    if (availablePrestigePoints >= cost && _factionSlotUpgrades < maxFactionSlotLimit - 1) {
      _factionSlotUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyExtraSkillPoint() {
    final cost = costForNextSkillPoint();
    if (availablePrestigePoints >= cost && totalSkillPoints < maxTotalSkillPoints) {
      _extraSkillPointsBought++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyGoldBonus() {
    final cost = costForNextGoldBonus();
    if (availablePrestigePoints >= cost) {
      _goldBonusUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyManaBonus() {
    final cost = costForNextManaBonus();
    if (availablePrestigePoints >= cost) {
      _manaBonusUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyOreBonus() {
    final cost = costForNextOreBonus();
    if (availablePrestigePoints >= cost) {
      _oreBonusUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyBuildingDiscount() {
    final cost = costForNextBuildingDiscount();
    if (availablePrestigePoints >= cost) {
      _buildingDiscountUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyTapPower() {
    final cost = costForNextTapPower();
    if (availablePrestigePoints >= cost) {
      _tapPowerUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyCooldownBonus() {
    final cost = costForNextCooldownBonus();
    if (availablePrestigePoints >= cost) {
      _cooldownUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyPopulationBonus() {
    final cost = costForNextPopulationBonus();
    if (availablePrestigePoints >= cost) {
      _populationUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyAutoTap() {
    final cost = costForNextAutoTap();
    if (availablePrestigePoints >= cost) {
      _autoTapUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyGlobalOutput() {
    final cost = costForNextGlobalOutput();
    if (availablePrestigePoints >= cost) {
      _globalOutputUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buySpellCostReduction() {
    final cost = costForNextSpellCostReduction();
    if (availablePrestigePoints >= cost) {
      _spellCostReductionUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  void checkConquestUnlock(GameState state) {
    if (!state.conquestUnlocked && prestigeLevel >= 10) {
      state.conquestUnlocked = true;
    }
  }

  void resetPrestigeUpgrades() {
    _usedPrestigePoints = 0;
    _spellSlotUpgrades = 0;
    _factionSlotUpgrades = 0;
    _extraSkillPointsBought = 0;
    _goldBonusUpgrades = 0;
    _manaBonusUpgrades = 0;
    _oreBonusUpgrades = 0;
    _buildingDiscountUpgrades = 0;
    _tapPowerUpgrades = 0;
    _cooldownUpgrades = 0;
    _populationUpgrades = 0;
    _autoTapUpgrades = 0;
    _globalOutputUpgrades = 0;
    _spellCostReductionUpgrades = 0;
  }

  void restoreUpgrades({
    required int usedPoints,
    required int spellSlots,
    required int factionSlots,
    required int extraSkillPoints,
    required int goldBonus,
    required int manaBonus,
    required int oreBonus,
    required int buildingDiscount,
    required int tapPower,
    required int cooldown,
    required int population,
    required int autoTap,
    required int globalOutput,
    required int spellCostReduction,
  }) {
    _usedPrestigePoints = usedPoints;
    _spellSlotUpgrades = spellSlots;
    _factionSlotUpgrades = factionSlots;
    _extraSkillPointsBought = extraSkillPoints;
    _goldBonusUpgrades = goldBonus;
    _manaBonusUpgrades = manaBonus;
    _oreBonusUpgrades = oreBonus;
    _buildingDiscountUpgrades = buildingDiscount;
    _tapPowerUpgrades = tapPower;
    _cooldownUpgrades = cooldown;
    _populationUpgrades = population;
    _autoTapUpgrades = autoTap;
    _globalOutputUpgrades = globalOutput;
    _spellCostReductionUpgrades = spellCostReduction;
  }

  int get usedPrestigePoints => _usedPrestigePoints;
  int get spellUpgradeLevel => _spellSlotUpgrades;
  int get factionUpgradeLevel => _factionSlotUpgrades;
  int get extraSkillPointsBought => _extraSkillPointsBought;
  int get goldBonusLevel => _goldBonusUpgrades;
  int get manaBonusLevel => _manaBonusUpgrades;
  int get oreBonusLevel => _oreBonusUpgrades;
  int get buildingDiscountLevel => _buildingDiscountUpgrades;
  int get tapPowerLevel => _tapPowerUpgrades;
  int get cooldownReductionLevel => _cooldownUpgrades;
  int get populationGrowthLevel => _populationUpgrades;
  int get autoTapLevel => _autoTapUpgrades;
  int get globalOutputLevel => _globalOutputUpgrades;
  int get spellCostReductionLevel => _spellCostReductionUpgrades;
}
