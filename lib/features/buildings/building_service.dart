import 'dart:convert';
import 'package:flutter/services.dart';
import 'building.dart';
import '../../core/game_state.dart';

class BuildingService {
  final List<Building> _buildings = [];

  /// Loads a list of buildings from a JSON file
  Future<void> loadFromJsonAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final jsonList = json.decode(raw) as List;
    _buildings.addAll(jsonList.map((e) => Building.fromJson(e)));
  }

  /// Unmodifiable list of all buildings loaded
  List<Building> get buildings => List.unmodifiable(_buildings);

  /// ✅ Filters buildings to only those belonging to selected factions
  List<Building> getBuildingsForFactions(List<String> activeFactions) {
    return _buildings.where((b) => activeFactions.contains(b.faction)).toList();
  }

  /// ✅ Attempts to buy a building if player can afford it
  void buy(Building building, GameState state) {
    final cost = building.currentCost(state);

    if (!state.canAfford(cost)) return;

    state.trySpend(cost);
    building.level += 1;
  }

  /// ✅ Resets all buildings to level 0 (e.g. on prestige)
  void reset() {
    for (final b in _buildings) {
      b.level = 0;
    }
  }

  /// ✅ Total output for a given resource per second
  double totalOutputPerSecond({required String resource}) {
    return _buildings.fold<double>(
      0.0,
          (sum, b) => sum + (b.outputPerSecond()[resource] ?? 0),
    );
  }

  /// ✅ Total number of buildings owned (summed across all levels)
  int get allOwnedCount =>
      _buildings.fold(0, (sum, b) => sum + b.level);
}
