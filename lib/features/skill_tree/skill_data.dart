import 'skill.dart';

class SkillData {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String effectId;
  final String faction;
  final int tier;

  SkillData({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effectId,
    required this.faction,
    required this.tier,
  });

  factory SkillData.fromJson(Map<String, dynamic> json) {
    return SkillData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 1,
      effectId: json['effect']?.toString() ?? '',
      faction: json['faction']?.toString() ?? 'global',
      tier: (json['tier'] as num?)?.toInt() ?? 1,
    );
  }

  Skill toSkill(SkillEffect effect) {
    return Skill(
      id: id,
      name: name,
      description: description,
      cost: cost,
      effectId: effectId,
      effect: effect,
      tier: tier,
      faction: faction,
    );
  }
}
