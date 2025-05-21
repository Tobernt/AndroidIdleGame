import 'dart:math';

class ConquestData {
  final String factionId;
  final String name;
  final String description;
  final double baseMightThreshold;
  bool conquered;

  ConquestData({
    required this.factionId,
    required this.name,
    required this.description,
    required this.baseMightThreshold,
    this.conquered = false,
  });

  factory ConquestData.fromJson(Map<String, dynamic> json) {
    return ConquestData(
      factionId: json['factionId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      baseMightThreshold: (json['baseMightThreshold'] as num).toDouble(),
      conquered: (json['conquered'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'factionId': factionId,
    'name': name,
    'description': description,
    'baseMightThreshold': baseMightThreshold,
    'conquered': conquered,
  };

  /// Computes the actual required might, factoring in conquered count
  double getAdjustedThreshold(int conqueredCount) {
    return baseMightThreshold * pow(2.5, conqueredCount);
  }
}
