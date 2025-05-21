import 'spell.dart';

class SpellData {
  final String id;
  final String name;
  final String description;
  final String effectId;
  final int cooldown;
  final Map<String, double> costs;
  final int tier;
  final String unlockRequirementId;
  final bool unlocked;
  final String faction; // ✅ Add this field

  SpellData({
    required this.id,
    required this.name,
    required this.description,
    required this.effectId,
    required this.cooldown,
    required this.costs,
    required this.tier,
    required this.unlockRequirementId,
    required this.unlocked,
    required this.faction, // ✅ Include in constructor
  });

  factory SpellData.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['name'] == null || json['effect'] == null) {
      throw Exception("Missing required field in spell JSON: $json");
    }

    return SpellData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      effectId: json['effect'] as String,
      cooldown: (json['cooldown'] ?? 0) as int,
      costs: (json['costs'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      tier: (json['tier'] ?? 1) as int,
      unlockRequirementId: json['unlockRequirementId'] ?? '',
      unlocked: json['unlocked'] ?? false,
      faction: json['faction'] ?? 'neutral',
    );
  }

  Spell toSpell(Map<String, SpellEffect> effectMap) {
    final effect = effectMap[effectId] ?? ((_) {});
    return Spell(
      id: id,
      name: name,
      description: description, // ✅ Add this line
      cooldown: Duration(seconds: cooldown),
      effect: effect,
      costs: costs,
      tier: tier,
      unlockRequirementId: unlockRequirementId,
      unlocked: unlocked,
      faction: faction,
    );
  }
}
