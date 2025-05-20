import 'building.dart';

class BuildingData {
  final String id;
  final String name;
  final String faction;
  final String description;
  final Map<String, double> baseCost;
  final Map<String, double> baseOutput;
  final double costGrowth;

  BuildingData({
    required this.id,
    required this.name,
    required this.faction,
    required this.description,
    required this.baseCost,
    required this.baseOutput,
    this.costGrowth = 1.15,
  });

  factory BuildingData.fromJson(Map<String, dynamic> json) {
    return BuildingData(
      id: json['id'],
      name: json['name'],
      faction: json['faction'],
      description: json['bonus'] ?? '',
      baseCost: Map<String, double>.from(json['baseCost']),
      baseOutput: Map<String, double>.from(json['baseOutput']),
      costGrowth: json['costGrowth'] != null
          ? (json['costGrowth'] as num).toDouble()
          : 1.15,
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
      level: 0,
      costGrowth: costGrowth,
    );
  }
}
