import 'dart:math';
import '../../core/game_state.dart';

class Building {
  final String id;
  final String name;
  final String description;
  final Map<String, double> baseOutput;
  final Map<String, double> baseCost;
  final String faction;
  final Map<String, dynamic> modifier;
  final String? unlockRequirementId;
  final double tapPerSecond;
  int level;
  double costGrowth;

  Building({
    required this.id,
    required this.name,
    required this.description,
    required this.baseOutput,
    required this.baseCost,
    required this.faction,
    required this.modifier,
    required this.level,
    this.costGrowth = 1.15,
    this.unlockRequirementId,
    this.tapPerSecond = 0.0,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(Map<String, dynamic>? raw) {
      if (raw == null) return {};
      return raw.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    final baseOutput = toDoubleMap(
      json['baseOutput'] ?? json['output'] ?? json['outputPerSecond'],
    );

    final costGrowth = (json['costGrowth'] ??
        json['growthRate'] ??
        json['costMultiplier'] ??
        1.15) as num;

    return Building(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? json['bonus'] ?? '',
      faction: json['faction'],
      baseCost: toDoubleMap(json['baseCost']),
      baseOutput: baseOutput,
      costGrowth: costGrowth.toDouble(),
      modifier: Map<String, dynamic>.from(json['modifier'] ?? {}),
      unlockRequirementId: json['unlockRequirementId'],
      tapPerSecond: (json['tapPerSecond'] ?? 0).toDouble(),
      level: json['level'] is int ? json['level'] as int : 0,
    );
  }

  /// Scales the building's cost based on its level and global multipliers
  Map<String, double> currentCost(GameState state) {
    final multiplier =
        state.resourceModifiers['building_cost_multiplier'] ?? 1.0;

    return baseCost.map((key, value) {
      final scaled = value * pow(costGrowth, level);
      return MapEntry(key, scaled * multiplier);
    });
  }

  /// Scales output by building level
  Map<String, double> outputPerSecond() {
    return baseOutput.map(
          (key, value) => MapEntry(key, value * level),
    );
  }

  /// Optional helper: check if building is locked behind an achievement
  bool get isLockedByAchievement => unlockRequirementId != null;
}
