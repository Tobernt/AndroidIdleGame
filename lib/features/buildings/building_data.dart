import 'building.dart';

class BuildingData {
  final String id;
  final String name;
  final String faction;
  final String description;
  final Map<String, double> baseCost;
  final Map<String, double> baseOutput;
  final double costGrowth;
  final Map<String, dynamic> modifier;
  final String? unlockRequirementId;
  final double tapPerSecond;

  BuildingData({
    required this.id,
    required this.name,
    required this.faction,
    required this.description,
    required this.baseCost,
    required this.baseOutput,
    this.costGrowth = 1.15,
    this.tapPerSecond = 0.0,
    this.modifier = const {},
    this.unlockRequirementId,
  });

  factory BuildingData.fromJson(Map<String, dynamic> json) {
    return BuildingData(
      id: json['id'],
      name: json['name'],
      faction: json['faction'],
      description: json['description'] ?? json['bonus'] ?? '',
      baseCost: Map<String, double>.from(json['baseCost']),
      baseOutput: Map<String, double>.from(json['baseOutput']),
      costGrowth: json['costGrowth'] != null
          ? (json['costGrowth'] as num).toDouble()
          : 1.15,
      modifier: Map<String, dynamic>.from(json['modifier'] ?? {}),
      unlockRequirementId: json['unlockRequirementId'],
      // 👇 ADD THIS LINE
      tapPerSecond: (json['tapPerSecond'] ?? 0).toDouble(),
    );
  }

  Building toBuilding() {
    return Building(
      id: id,
      name: name,
      description: description,
      faction: faction,
      baseCost: baseCost,
      baseOutput: baseOutput,
      costGrowth: costGrowth,
      level: 0,
      modifier: modifier,
      unlockRequirementId: unlockRequirementId,
      tapPerSecond: tapPerSecond,
    );
  }
}
