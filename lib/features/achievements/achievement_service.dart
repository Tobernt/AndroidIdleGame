import '../../core/game_state.dart';
import '../../features/achievements/achievement.dart';
import '../../features/spells/spell_service.dart';
import '../../features/skill_tree/skill_manager.dart';
import '../../features/factions/faction_service.dart';
import 'package:flutter/foundation.dart';

class AchievementService {
  final List<Achievement> _achievements = [];

  List<Achievement> get all => List.unmodifiable(_achievements);

  late SpellService _spellService;
  late SkillManager _skillManager;
  late FactionManager _factionManager;

  void init({
    required SpellService spellService,
    required SkillManager skillManager,
    required FactionManager factionManager,
  }) {
    _spellService = spellService;
    _skillManager = skillManager;
    _factionManager = factionManager;
  }

  void load(List<Achievement> initialData) {
    _achievements
      ..clear()
      ..addAll(initialData);
  }

  void unlock(String id) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = _achievements[index].copyWith(isUnlocked: true);
    }
  }

  void claim(String id, GameState state) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) {
      debugPrint("❌ Achievement claim failed: ID '$id' not found.");
      return;
    }

    final achievement = _achievements[index];
    if (!achievement.isUnlocked || achievement.isClaimed) {
      debugPrint("⛔ Cannot claim '${achievement.id}': Either not unlocked or already claimed.");
      return;
    }

    _achievements[index] = achievement.copyWith(isClaimed: true);
    debugPrint("✅ Claimed achievement '${achievement.id}'");

    _applyReward(achievement.reward, state);
  }

  void _applyReward(AchievementReward? reward, GameState state) {
    if (reward == null) return;

    switch (reward.type) {
      case 'unlock_spell':
        _spellService.unlockSpellById(reward.targetId);
        debugPrint("🎁 Applied spell reward: ${reward.targetId}");
        break;
      case 'unlock_skill':
        _skillManager.markSkillAsAvailable(reward.targetId);
        debugPrint("🎁 Applied skill reward: ${reward.targetId}");
        break;
      case 'unlock_conquest':
        state.conquestUnlocked = true;
        debugPrint("⚔️ Conquest unlocked");
        break;
      case 'unlock_hero':
        state.metaValues['unlocked_heroes'] ??= <String>[];
        final unlocked = state.metaValues['unlocked_heroes'] as List<String>;
        if (!unlocked.contains(reward.targetId)) {
          unlocked.add(reward.targetId);
          debugPrint("🦸 Hero unlocked: ${reward.targetId}");
        }
        break;
      default:
        debugPrint("⚠️ Unknown reward type: ${reward.type}");
        break;
    }
  }

  void applyClaimedRewards(GameState state) {
    for (final achievement in _achievements) {
      if (achievement.isClaimed && achievement.reward != null) {
        _applyReward(achievement.reward, state);
      }
    }
  }

  void evaluate({
    required GameState state,
    required double lifetimeGold,
    required int buildingsOwned,
    required int tapCount,
  }) {
    final selectedFactionIds = _factionManager.getSelectedFactionIds().toSet();
    final conquered = state.conqueredFactions.toSet();
    final destroyed = state.destroyedFactions.toSet();
    final clearedFactions = {...conquered, ...destroyed};

    for (int i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      if (a.isUnlocked || a.requirement == null) continue;

      final r = a.requirement!;
      bool fulfilled = false;

      switch (r.type) {
        case 'gold_total':
          fulfilled = lifetimeGold >= r.amount;
          break;
        case 'mana_threshold':
          fulfilled = state.getResource('mana') >= r.amount;
          break;
        case 'tap_gold':
          fulfilled = tapCount >= r.amount;
          break;
        case 'tap_lifetime':
          fulfilled = state.lifetimeTaps >= r.amount;
          break;
        case 'buildings_owned':
          fulfilled = buildingsOwned >= r.amount;
          break;
        case 'prestige_total':
          fulfilled = state.totalPrestiges >= r.amount;
          break;
        case 'resource_lifetime':
          final resource = r.extra ?? 'gold';
          fulfilled = (state.lifetimeResources[resource] ?? 0) >= r.amount;
          break;

        case 'faction_conquest':
          final requiredFaction = r.selectedFaction;
          final requiredConquered = r.conqueredFactions.toSet();

          final isPlayingRequired = requiredFaction != null && selectedFactionIds.contains(requiredFaction);

          debugPrint("🧩 Checking faction_conquest for ${a.id}");
          debugPrint("Selected factions: $selectedFactionIds | Required: $requiredFaction");
          debugPrint("Cleared factions: $clearedFactions");
          debugPrint("Required to conquer: $requiredConquered");

          fulfilled = isPlayingRequired && requiredConquered.every(clearedFactions.contains);
          break;

        default:
          debugPrint("⚠️ Unknown requirement type: ${r.type}");
          break;
      }

      if (fulfilled) {
        _achievements[i] = a.copyWith(isUnlocked: true);
      }
    }
  }
}
