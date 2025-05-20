import '../../core/game_state.dart';

typedef SkillEffect = void Function(GameState);

class Skill {
  final String id;
  final String name;
  final String description;
  final int cost;
  final SkillEffect effect;
  final int tier;
  final String faction;

  bool available = false;
  bool unlocked = false;
  bool equipped = false;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effect,
    required this.tier,
    required this.faction,
  });
}
