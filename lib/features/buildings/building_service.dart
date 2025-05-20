import 'dart:convert';
import 'package:flutter/services.dart';
import 'building.dart';
import '../../core/game_state.dart';

class BuildingService {
  final List<Building> _buildings = [];

  Future<void> loadFromJsonAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final jsonList = json.decode(raw) as List;
    _buildings.clear();
    _buildings.addAll(jsonList.map((e) => Building.fromJson(e)));
  }

  List<Building> get buildings => List.unmodifiable(_buildings);

  void buy(Building building, GameState state) {
    final cost = building.currentCost();
    for (final entry in cost.entries) {
      if (state.getResource(entry.key) < entry.value) return;
    }

    for (final entry in cost.entries) {
      state.spendResource(entry.key, entry.value);
    }

    building.level += 1;
  }

  void reset() {
    for (final b in _buildings) {
      b.level = 0;
    }
  }

  double totalOutputPerSecond({required String resource}) {
    return _buildings.fold<double>(0.0, (sum, b) {
      return sum + (b.outputPerSecond()[resource] ?? 0);
    });
  }

  /// ✅ Add this
  int get allOwnedCount =>
      _buildings.fold(0, (sum, b) => sum + b.level);
}
