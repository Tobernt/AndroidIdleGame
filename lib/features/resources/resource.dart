import 'resource_type.dart';

class Resource {
  final ResourceType type;
  final String displayName;
  final String iconPath;
  final double baseGeneration;

  Resource({
    required this.type,
    required this.displayName,
    required this.iconPath,
    required this.baseGeneration,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      type: ResourceTypeExtension.fromName(json['type']),
      displayName: json['displayName'],
      iconPath: json['iconPath'],
      baseGeneration: json['baseGeneration'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'displayName': displayName,
    'iconPath': iconPath,
    'baseGeneration': baseGeneration,
  };
}
