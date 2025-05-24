import '../../core/game_state.dart';

typedef HeroEffect = void Function(GameState state, double multiplier);

class HeroData {
  final String id;
  final String name;
  final String description;
  final String faction;             // <-- added
  final String unlockAchievementId;
  final HeroEffect effect;

  bool unlocked;
  bool selected;

  HeroData({
    required this.id,
    required this.name,
    required this.description,
    required this.faction,          // <-- added
    required this.unlockAchievementId,
    required this.effect,
    this.unlocked = false,
    this.selected = false,
  });

  factory HeroData.fromJson(Map<String, dynamic> json, HeroEffect effect) {
    return HeroData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      faction: json['faction'],                     // <-- added
      unlockAchievementId: json['unlockAchievementId'],
      effect: effect,
      unlocked: json['unlocked'] ?? false,
      selected: json['selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'faction': faction,                         // <-- added
    'unlockAchievementId': unlockAchievementId,
    'unlocked': unlocked,
    'selected': selected,
  };
}
