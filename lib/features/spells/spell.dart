import '../../core/game_state.dart';

typedef SpellEffect = void Function(GameState);

class Spell {
  final String id;
  final String name;
  final String description; // ✅ Add this line
  final Duration cooldown;
  final SpellEffect effect;
  final Map<String, double> costs;
  final int tier;
  final String unlockRequirementId;
  final String faction;
  bool unlocked;
  final Duration? duration;
  DateTime? _lastCast;

  Spell({
    required this.id,
    required this.name,
    required this.description, // ✅ Add to constructor
    required this.cooldown,
    required this.effect,
    required this.costs,
    required this.tier,
    required this.unlockRequirementId,
    required this.faction,
    this.unlocked = false,
    this.duration,
  });

  bool get isOnCooldown {
    if (_lastCast == null) return false;
    return DateTime.now().difference(_lastCast!) < cooldown;
  }

  bool get isInDuration {
    if (duration == null || _lastCast == null) return false;
    return DateTime.now().difference(_lastCast!) < duration!;
  }

  double get cooldownProgress {
    if (!isOnCooldown || _lastCast == null) return 0.0;
    final elapsed = DateTime.now().difference(_lastCast!).inMilliseconds;
    return (elapsed / cooldown.inMilliseconds).clamp(0.0, 1.0);
  }

  double get durationProgress {
    if (!isInDuration || duration == null || _lastCast == null) return 0.0;
    final elapsed = DateTime.now().difference(_lastCast!).inMilliseconds;
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
    _lastCast = DateTime.now();
    effect(state);
    return true;
  }

  /// Deserialize from JSON
  factory Spell.fromJson(Map<String, dynamic> json, SpellEffect effect) {
    return Spell(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '', // ✅ Add this
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
