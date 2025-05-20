import 'dart:math';
import '../../core/game_state.dart';

class PrestigeService {
  int prestigeLevel = 0;
  double lifetimeGold = 0;
  double _prestigedMultiplier = 1.0;

  // Prestige currency
  int prestigePoints = 0;
  int _usedPrestigePoints = 0;

  // Upgrade states
  int _spellSlotUpgrades = 0;
  int _factionSlotUpgrades = 0;
  int _extraSkillPointsBought = 0;

  // Skill point usage tracking
  int _spentSkillPoints = 0;

  int heroRosterSize = 1;
  static const int maxHeroRosterSize = 6;

  /// Upgrade limits
  static const int maxSpellSlotLimit = 5;
  static const int maxFactionSlotLimit = 3;
  static const int maxTotalSkillPoints = 15;

  /// Multiplier from lifetime gold
  double get prestigeMultiplier => _prestigedMultiplier;

  /// Base skill points from gold
  int get _baseSkillPoints =>
      min(maxTotalSkillPoints, (log(1 + lifetimeGold) / 15).floor());

  /// Total available skill points (gold-based + prestige-bought)
  int get totalSkillPoints =>
      min(maxTotalSkillPoints, _baseSkillPoints + _extraSkillPointsBought);

  int get availableSkillPoints => totalSkillPoints - _spentSkillPoints;
  int get availablePrestigePoints => prestigePoints - _usedPrestigePoints;

  int get maxEquippedSpells => 1 + _spellSlotUpgrades;
  int get maxFactions => 1 + _factionSlotUpgrades;

  /// Track gold for prestige
  void applyGold(double amount) {
    lifetimeGold += amount;
  }

  /// Perform prestige, grant bonuses and unlock conquest
  void prestige(GameState state) {
    prestigeLevel++;
    state.totalPrestiges++; // ✅ TRACK TOTAL PRESTIGES
    prestigePoints++;

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
    if (availablePrestigePoints > 0 && _spellSlotUpgrades < maxSpellSlotLimit - 1) {
      _spellSlotUpgrades++;
      _usedPrestigePoints++;
      return true;
    }
    return false;
  }

  bool buyFactionSlot() {
    if (availablePrestigePoints > 0 && _factionSlotUpgrades < maxFactionSlotLimit - 1) {
      _factionSlotUpgrades++;
      _usedPrestigePoints++;
      return true;
    }
    return false;
  }

  bool buyExtraSkillPoint() {
    if (availablePrestigePoints > 0 && totalSkillPoints < maxTotalSkillPoints) {
      _extraSkillPointsBought++;
      _usedPrestigePoints++;
      return true;
    }
    return false;
  }

  bool buyHeroSlot() {
    if (availablePrestigePoints > 0 && heroRosterSize < maxHeroRosterSize) {
      heroRosterSize++;
      _usedPrestigePoints++;
      return true;
    }
    return false;
  }

  void checkConquestUnlock(GameState state) {
    if (!state.conquestUnlocked &&
        prestigeLevel >= 10) {
      state.conquestUnlocked = true;
    }
  }

  /// Reset only prestige upgrade tracking (optional)
  void resetPrestigeUpgrades() {
    _usedPrestigePoints = 0;
    _spellSlotUpgrades = 0;
    _factionSlotUpgrades = 0;
    _extraSkillPointsBought = 0;
  }

  // UI accessors
  int get usedPrestigePoints => _usedPrestigePoints;
  int get spellUpgradeLevel => _spellSlotUpgrades;
  int get factionUpgradeLevel => _factionSlotUpgrades;
  int get extraSkillPointsBought => _extraSkillPointsBought;
}
