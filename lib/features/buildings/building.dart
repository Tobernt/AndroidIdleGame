import 'dart:math';
import '../../core/game_state.dart';

class Building {
  final String id;
  final String name;
  final String description;
  final Map<String, double> baseOutput;
  final Map<String, double> baseCost;
  final String faction;
  int level;
  double costGrowth;

  Building({
    required this.id,
    required this.name,
    required this.description,
    required this.baseOutput,
    required this.baseCost,
    required this.faction,
    required this.level,
    this.costGrowth = 1.15,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(Map<String, dynamic> raw) {
      return raw.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    return Building(
      id: json['id'],
      name: json['name'],
      description: json['bonus'] ?? '',
      faction: json['faction'],
      baseCost: toDoubleMap(json['baseCost']),
      baseOutput: toDoubleMap(json['baseOutput']),
      level: json['level'] is int ? json['level'] as int : 0,
    );
  }

  /// ✅ Cost scales by level and applies building cost multiplier from GameState
  Map<String, double> currentCost(GameState state) {
    final costMultiplier = state.resourceModifiers['building_cost_multiplier'] ?? 1.0;
    return baseCost.map((key, value) {
      final scaled = value * pow(costGrowth, level);
      return MapEntry(key, scaled * costMultiplier);
    });
  }

  /// Output scales linearly with level
  Map<String, double> outputPerSecond() {
    return baseOutput.map(
          (key, value) => MapEntry(key, value * level),
    );
  }
}
