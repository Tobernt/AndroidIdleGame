import '../../core/game_state.dart';
import '../../features/achievements/achievement.dart';
import '../../features/spells/spell_service.dart';
import '../../features/skill_tree/skill_manager.dart';

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
    _achievements.clear();
    _achievements.addAll(initialData);
  }

  void unlock(String id) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = _achievements[index].copyWith(isUnlocked: true);
    }
  }

  void claim(String id, GameState state) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final achievement = _achievements[index];
    if (!achievement.isUnlocked || achievement.isClaimed) return;

    _achievements[index] = achievement.copyWith(isClaimed: true);

    final reward = achievement.reward;
    if (reward != null) {
      switch (reward.type) {
        case 'unlock_spell':
          _spellService.unlockSpellById(reward.targetId);
          break;
        case 'unlock_skill':
          _skillManager.markSkillAsAvailable(reward.targetId);
          break;
        case 'unlock_conquest':
          state.conquestUnlocked = true;
          break;
        default:
          break;
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
          fulfilled = state.totalPrestiges >= r.amount;
          break;
        case 'prestige_total':
          fulfilled = state.totalPrestiges >= r.amount;
          break;
        case 'resource_lifetime':
          final resource = r.extra ?? 'gold'; // fallback to gold
          fulfilled = state.lifetimeResources[resource] != null &&
              state.lifetimeResources[resource]! >= r.amount;
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
