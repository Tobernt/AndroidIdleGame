import '../../core/game_state.dart';
import '../../features/achievements/achievement.dart';
import '../../features/spells/spell_service.dart';
import '../../features/skill_tree/skill_manager.dart';
import 'package:flutter/foundation.dart';

class AchievementService {
  final List<Achievement> _achievements = [];

  List<Achievement> get all => List.unmodifiable(_achievements);

  late SpellService _spellService;
  late SkillManager _skillManager;

  void init({
    required SpellService spellService,
    required SkillManager skillManager,
  }) {
    _spellService = spellService;
    _skillManager = skillManager;
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
    debugPrint("🔍 Attempting to claim '${achievement.id}' — Unlocked: ${achievement.isUnlocked}, Claimed: ${achievement.isClaimed}");

    if (!achievement.isUnlocked || achievement.isClaimed) {
      debugPrint("⛔ Cannot claim '${achievement.id}': Either not unlocked or already claimed.");
      return;
    }

    _achievements[index] = achievement.copyWith(isClaimed: true);
    debugPrint("✅ Claimed achievement '${achievement.id}'");

    final reward = achievement.reward;
    if (reward != null) {
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
          debugPrint("⚔️ Conquest unlocked via achievement '${achievement.id}'");
          break;

        default:
          debugPrint("⚠️ Unknown reward type: ${reward.type}");
          break;
      }
    } else {
      debugPrint("ℹ️ No reward to apply for '${achievement.id}'");
    }
  }

  void applyClaimedRewards(GameState state) {
    for (final achievement in _achievements) {
      if (achievement.isClaimed && achievement.reward != null) {
        switch (achievement.reward!.type) {
          case 'unlock_spell':
            _spellService.unlockSpellById(achievement.reward!.targetId);
            break;
          case 'unlock_skill':
            _skillManager.markSkillAsAvailable(achievement.reward!.targetId);
            break;
          case 'unlock_conquest':
            state.conquestUnlocked = true;
            break;
          default:
            break;
        }
      }
    }
  }

  void evaluate({
    required GameState state,
    required double lifetimeGold,
    required int buildingsOwned,
    required int tapCount,
  }) {
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
        case 'prestige_level':
        case 'prestige_total':
          fulfilled = state.totalPrestiges >= r.amount;
          break;
        case 'resource_lifetime':
          final resource = r.extra ?? 'gold';
          fulfilled = (state.lifetimeResources[resource] ?? 0) >= r.amount;
          break;
        default:
          break;
      }

      if (fulfilled) {
        _achievements[i] = a.copyWith(isUnlocked: true);
      }
    }
  }
}
