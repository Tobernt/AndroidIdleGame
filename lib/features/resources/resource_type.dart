enum ResourceType {
  gold,
  mana,
  ore,
  population,
  might,
}

extension ResourceTypeExtension on ResourceType {
  String get name => toString().split('.').last;

  static ResourceType fromName(String name) {
    return ResourceType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw Exception("Unknown ResourceType: $name"),
    );
  }
}
