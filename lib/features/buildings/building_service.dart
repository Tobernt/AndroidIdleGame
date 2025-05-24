import 'dart:convert';
import 'package:flutter/services.dart';
import 'building.dart';
import '../../core/game_state.dart';
import '../modifiers/modifier_manager.dart';

class BuildingService {
  final List<Building> _buildings = [];

  Future<void> loadFromJsonAssets(List<String> paths) async {
    for (final path in paths) {
      final raw = await rootBundle.loadString(path);
      final jsonList = json.decode(raw) as List;

      for (final entry in jsonList) {
        if (entry is Map<String, dynamic>) {
          _buildings.add(Building.fromJson(entry));
        } else {
          return;
        }
      }
    }
  }

  List<Building> get buildings => List.unmodifiable(_buildings);

  List<Building> getBuildingsForFactions(List<String> activeFactions) {
    return _buildings.where((b) => activeFactions.contains(b.faction)).toList();
  }

  void buy(Building building, GameState state, ModifierManager modifierManager) {
    final finalCost = getFinalCost(building, state, modifierManager);
    if (!state.canAfford(finalCost)) return;

    state.trySpend(finalCost);
    building.level += 1;
  }

  void reset() {
    for (final b in _buildings) {
      b.level = 0;
    }
  }
  Map<String, double> getFinalCost(Building building, GameState state, ModifierManager modifierManager) {
    final baseCost = building.currentCost(state);

    // Apply only temporary modifier, since skill is already baked into state-modified cost
    final tempDiscount = modifierManager.getCombinedMultiplier('building_cost');

    return {
      for (final entry in baseCost.entries)
        entry.key: entry.value * tempDiscount,
    };
  }

  double totalOutputPerSecond({required String resource}) {
    return _buildings.fold<double>(
      0.0,
          (sum, b) => sum + (b.outputPerSecond()[resource] ?? 0),
    );
  }

  /// ✅ Collect all numeric-based building modifiers (scaled by level)
  Map<String, double> getActiveModifiers() {
    final Map<String, double> modifiers = {};

    for (final b in _buildings) {
      if (b.level > 0 && b.modifier.isNotEmpty) {
        for (final entry in b.modifier.entries) {
          final key = entry.key;
          final dynamic rawValue = entry.value;

          if (rawValue is num) {
            final value = rawValue.toDouble();
            modifiers[key] = (modifiers[key] ?? 0.0) + value * b.level;
          }
          // For non-numeric effects (like flags), extend here if needed
        }
      }
    }

    return modifiers;
  }

  /// ✅ Aggregate all tap-per-second effects (e.g. from Auto-Press)
  double getAutomatedTapsPerSecond() {
    return _buildings.fold(
      0.0,
          (sum, b) => sum + (b.tapPerSecond * b.level),
    );
  }

  /// ✅ Sum all owned building levels
  int get allOwnedCount => _buildings.fold(0, (sum, b) => sum + b.level);
}
