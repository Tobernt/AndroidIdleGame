class Faction {
  final String id;
  final String name;
  final String description;

  /// Map of resourceType → boost multiplier (e.g., {"mana": 1.2})
  final Map<String, double> resourceBoosts;

  bool unlocked;
  bool isSelected;

  Faction({
    required this.id,
    required this.name,
    required this.description,
    this.resourceBoosts = const {},
    this.unlocked = true,
    this.isSelected = false,
  });

  double getBoost(String resourceId) => resourceBoosts[resourceId] ?? 1.0;
}
