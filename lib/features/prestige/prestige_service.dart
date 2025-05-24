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


  /// Upgrade limits
  static const int maxSpellSlotLimit = 5;
  static const int maxFactionSlotLimit = 3;
  static const int maxTotalSkillPoints = 15;

  double get prestigeMultiplier => _prestigedMultiplier;

  int get _baseSkillPoints =>
      min(maxTotalSkillPoints, (log(1 + lifetimeGold) / 15).floor());

  int get totalSkillPoints =>
      min(maxTotalSkillPoints, _baseSkillPoints + _extraSkillPointsBought);

  int get availableSkillPoints => totalSkillPoints - _spentSkillPoints;
  int get availablePrestigePoints => prestigePoints - _usedPrestigePoints;

  int get maxEquippedSpells => 1 + _spellSlotUpgrades;
  int get maxFactions => 1 + _factionSlotUpgrades;

  void applyGold(double amount) {
    lifetimeGold += amount;
  }

  void prestige(GameState state) {
    prestigeLevel++;
    state.totalPrestiges++;

    // 🎯 1 point per 100k active gold
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
    final cost = pow(10, _spellSlotUpgrades).toInt();
    if (availablePrestigePoints >= cost && _spellSlotUpgrades < maxSpellSlotLimit - 1) {
      _spellSlotUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyFactionSlot() {
    final cost = pow(10, _factionSlotUpgrades).toInt();
    if (availablePrestigePoints >= cost && _factionSlotUpgrades < maxFactionSlotLimit - 1) {
      _factionSlotUpgrades++;
      _usedPrestigePoints += cost;
      return true;
    }
    return false;
  }

  bool buyExtraSkillPoint() {
    final cost = pow(10, _extraSkillPointsBought).toInt();
    if (availablePrestigePoints >= cost && totalSkillPoints < maxTotalSkillPoints) {
      _extraSkillPointsBought++;
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
  }

  int get usedPrestigePoints => _usedPrestigePoints;
  int get spellUpgradeLevel => _spellSlotUpgrades;
  int get factionUpgradeLevel => _factionSlotUpgrades;
  int get extraSkillPointsBought => _extraSkillPointsBought;
}
