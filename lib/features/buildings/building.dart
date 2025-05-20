import 'dart:math';

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

  Map<String, double> currentCost() {
    return baseCost.map(
          (key, value) => MapEntry(key, value * pow(costGrowth, level)),
    );
  }

  Map<String, double> outputPerSecond() {
    return baseOutput.map(
          (key, value) => MapEntry(key, value * level),
    );
  }
}
