import '../../core/game_state.dart';

typedef SpellEffect = void Function(GameState);

class Spell {
  final String id;
  final String name;
  final String description;
  final Duration cooldown;
  final SpellEffect effect;
  final Map<String, double> costs;
  final int tier;
  final String unlockRequirementId;
  final String faction;
  bool unlocked;
  final Duration? duration;
  DateTime? lastCast;
  bool get isDivineAuraActive =>
      id == 'human_spell_5' && lastCast != null && isOnCooldown;

  Spell({
    required this.id,
    required this.name,
    required this.description,
    required this.cooldown,
    required this.effect,
    required this.costs,
    required this.tier,
    required this.unlockRequirementId,
    required this.faction,
    this.unlocked = false,
    this.duration,
  });

  void markCastTime() {
    lastCast = DateTime.now();
  }

  bool get isOnCooldown {
    if (lastCast == null) return false;
    return DateTime.now().difference(lastCast!) < cooldown;
  }

  bool get isInDuration {
    if (duration == null || lastCast == null) return false;
    return DateTime.now().difference(lastCast!) < duration!;
  }

  double get cooldownProgress {
    if (!isOnCooldown || lastCast == null) return 0.0;
    final elapsed = DateTime.now().difference(lastCast!).inMilliseconds;
    return (elapsed / cooldown.inMilliseconds).clamp(0.0, 1.0);
  }

  double get durationProgress {
    if (!isInDuration || duration == null || lastCast == null) return 0.0;
    final elapsed = DateTime.now().difference(lastCast!).inMilliseconds;
    return (elapsed / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  bool canCast(GameState state) {
    if (!unlocked || isOnCooldown) return false;
    return costs.entries.every((e) => state.getResource(e.key) >= e.value);
  }

  bool tryCast(GameState state) {
    if (!canCast(state)) return false;
    for (final entry in costs.entries) {
      state.spendResource(entry.key, entry.value);
    }
    lastCast = DateTime.now();
    effect(state);
    return true;
  }
  double getFinalCost(String resource, GameState state) {
    final base = costs[resource] ?? 0.0;
    final costMult = state.resourceModifiers['spell_cost_multiplier'] ?? 1.0;
    return base * costMult;
  }

  Duration getFinalCooldown(GameState state) {
    final reduction = state.resourceModifiers['cooldown_reduction'] ?? 0.0;
    final reductionFactor = (1.0 - reduction).clamp(0.0, 1.0);

    final multiplier = state.resourceModifiers['spell_cooldown_mult'] ?? 1.0;

    final totalFactor = (reductionFactor * multiplier).clamp(0.1, 1.0); // Min cap to prevent zero-CD
    return Duration(milliseconds: (cooldown.inMilliseconds * totalFactor).round());
  }


  Duration getRemainingCooldown(GameState state) {
    if (lastCast == null) return Duration.zero;
    final elapsed = DateTime.now().difference(lastCast!);
    final cooldown = getFinalCooldown(state);
    final remaining = cooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  /// Deserialize from JSON
  factory Spell.fromJson(Map<String, dynamic> json, SpellEffect effect) {
    return Spell(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '', // Add this
      cooldown: Duration(seconds: json['cooldown']),
      duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
      effect: effect,
      costs: Map<String, double>.from(json['costs']),
      tier: json['tier'] ?? 1,
      unlockRequirementId: json['unlockRequirementId'] ?? '',
      faction: json['faction'] ?? 'neutral',
      unlocked: json['unlocked'] ?? false,
    );
  }


  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cooldown': cooldown.inSeconds,
    if (duration != null) 'duration': duration!.inSeconds,
    'costs': costs,
    'tier': tier,
    'unlockRequirementId': unlockRequirementId,
    'faction': faction,
    'unlocked': unlocked,
  };
}
