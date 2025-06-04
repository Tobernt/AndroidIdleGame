class AchievementRequirement {
  final String type;
  final double amount;
  final String? extra;
  final String? selectedFaction;
  final List<String> conqueredFactions;
  final int? durationSeconds;

  const AchievementRequirement({
    required this.type,
    this.amount = 0,
    this.extra,
    this.selectedFaction,
    this.conqueredFactions = const [],
    this.durationSeconds,
  });

  factory AchievementRequirement.fromJson(Map<String, dynamic> json) {
    return AchievementRequirement(
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      extra: json['extra'] as String?,
      selectedFaction: json['selectedFaction'] as String?,
      conqueredFactions: (json['conqueredFactions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    if (extra != null) 'extra': extra,
    if (selectedFaction != null) 'selectedFaction': selectedFaction,
    if (conqueredFactions.isNotEmpty)
      'conqueredFactions': conqueredFactions,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
  };
}

class AchievementReward {
  final String type; // 'unlock_spell' | 'unlock_skill' | etc.
  final String targetId;

  const AchievementReward({
    required this.type,
    required this.targetId,
  });

  factory AchievementReward.fromJson(Map<String, dynamic> json) {
    return AchievementReward(
      type: json['type'] ?? '',
      targetId: json['targetId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'targetId': targetId,
  };
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String hint;
  final bool isUnlocked;
  final bool isClaimed;
  final AchievementReward? reward;
  final List<AchievementRequirement> requirements;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.reward,
    this.requirements = const [],
  });

  Achievement copyWith({
    bool? isUnlocked,
    bool? isClaimed,
    AchievementReward? reward,
    List<AchievementRequirement>? requirements,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      hint: hint,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isClaimed: isClaimed ?? this.isClaimed,
      reward: reward ?? this.reward,
      requirements: requirements ?? this.requirements,
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final rawRequirements = json['requirements'] ??
        (json['requirement'] != null ? [json['requirement']] : []);

    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      hint: json['hint'] ?? '',
      isUnlocked: json['isUnlocked'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
      reward: json['reward'] != null
          ? AchievementReward.fromJson(
          Map<String, dynamic>.from(json['reward']))
          : null,
      requirements: (rawRequirements as List)
          .map((r) => AchievementRequirement.fromJson(
          Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'hint': hint,
    'isUnlocked': isUnlocked,
    'isClaimed': isClaimed,
    if (reward != null) 'reward': reward!.toJson(),
    if (requirements.isNotEmpty)
      'requirements': requirements.map((r) => r.toJson()).toList(),
  };
}
