class AchievementRequirement {
  final String type; // e.g. 'gold_total', 'tap_gold', etc.
  final double amount;
  final String? extra;

  const AchievementRequirement({
    required this.type,
    required this.amount,
    this.extra,
  });

  factory AchievementRequirement.fromJson(Map<String, dynamic> json) {
    return AchievementRequirement(
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      extra: json['extra'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    if (extra != null) 'extra': extra,
  };
}

class AchievementReward {
  final String type; // 'unlock_spell' | 'unlock_skill'
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
  final AchievementRequirement? requirement;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.reward,
    this.requirement,
  });

  Achievement copyWith({
    bool? isUnlocked,
    bool? isClaimed,
    AchievementReward? reward,
    AchievementRequirement? requirement,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      hint: hint,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isClaimed: isClaimed ?? this.isClaimed,
      reward: reward ?? this.reward,
      requirement: requirement ?? this.requirement,
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      hint: json['hint'] ?? '',
      isUnlocked: json['isUnlocked'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
      reward: json['reward'] != null
          ? AchievementReward.fromJson(Map<String, dynamic>.from(json['reward']))
          : null,
      requirement: json['requirement'] != null
          ? AchievementRequirement.fromJson(Map<String, dynamic>.from(json['requirement']))
          : null,
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
    if (requirement != null) 'requirement': requirement!.toJson(),
  };
}
