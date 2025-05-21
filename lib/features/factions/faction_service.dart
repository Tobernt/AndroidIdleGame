import 'package:flutter/foundation.dart';
import '../prestige/prestige_service.dart';
import 'faction.dart';

class FactionManager extends ChangeNotifier {
  final List<Faction> _allFactions = [
    Faction(
      id: 'humans',
      name: 'Humans',
      description: 'Versatile and balanced economy.',
      resourceBoosts: {
        'gold': 1.2,
      },
      unlocked: true,
    ),
    Faction(
      id: 'undead',
      name: 'Undead',
      description: 'Amass population with ritualistic power.',
      resourceBoosts: {
        'population': 1.5,
        'mana': 1.1,
      },
      unlocked: false,
    ),
    Faction(
      id: 'elves',
      name: 'Elves',
      description: 'Masters of mana and spells.',
      resourceBoosts: {
        'mana': 1.3,
      },
      unlocked: false,
    ),
    Faction(
      id: 'orcs',
      name: 'Orcs',
      description: 'Aggressive and brute force cooldown play.',
      resourceBoosts: {
        'gold': 1.25,
      },
      unlocked: false,
    ),
    Faction(
      id: 'dwarves',
      name: 'Dwarves',
      description: 'Efficient builders and resource miners.',
      resourceBoosts: {
        'ore': 1.5,
        'gold': 1.15,
      },
      unlocked: false,
    ),
    Faction(
      id: 'automatons',
      name: 'Automatons',
      description: 'Autonomous tapping and hybrid growth.',
      resourceBoosts: {
        'gold': 1.1,
        'mana': 1.1,
        'ore': 1.1,
      },
      unlocked: false,
    ),
  ];

  final PrestigeService _prestigeService;

  FactionManager({required PrestigeService prestigeService})
      : _prestigeService = prestigeService;

  List<Faction> get allFactions => _allFactions;

  /// ✅ Returns currently selected factions (up to maxSelectable)
  List<Faction> get selected =>
      _allFactions.where((f) => f.isSelected).toList();

  /// ✅ Returns all selected faction IDs (for filtering buildings, skills, etc.)
  List<String> getSelectedFactionIds() {
    return selected.map((f) => f.id).toList();
  }

  /// ✅ Returns IDs of unlocked factions
  List<String> getUnlockedFactionIds() {
    return _allFactions.where((f) => f.unlocked).map((f) => f.id).toList();
  }

  int get maxSelectable => _prestigeService.maxFactions;

  bool canSelectMore() => selected.length < maxSelectable;

  /// ✅ Toggles a faction as selected, respecting max limit and unlocks
  void toggleSelect(String id) {
    final faction = _allFactions.firstWhere((f) => f.id == id);

    if (!faction.unlocked) return;

    if (faction.isSelected) {
      faction.isSelected = false;
    } else if (canSelectMore()) {
      faction.isSelected = true;
    }

    notifyListeners();
  }
  void selectOnly(String id) {
    clearSelection();
    toggleSelect(id);
  }

  /// ✅ Unlocks a faction
  void unlock(String id) {
    final faction = _allFactions.firstWhere((f) => f.id == id);
    faction.unlocked = true;
    notifyListeners();
  }

  /// ✅ Clears all selected factions (e.g. on prestige)
  void clearSelection() {
    for (final faction in _allFactions) {
      faction.isSelected = false;
    }
    notifyListeners();
  }

  /// ✅ Clears unlocks and resets to only Humans (for prestige reset if needed)
  void resetUnlocks() {
    for (final faction in _allFactions) {
      faction.unlocked = faction.id == 'humans';
      faction.isSelected = false;
    }
    notifyListeners();
  }
}
