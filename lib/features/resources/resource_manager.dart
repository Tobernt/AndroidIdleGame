import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'resource.dart';
import 'resource_type.dart';

class ResourceManager {
  final Map<ResourceType, Resource> config = {};
  final Map<ResourceType, double> current = {};

  Future<void> loadFromConfig() async {
    final jsonStr = await rootBundle.loadString('assets/data/resources_config.json');
    final List<dynamic> jsonList = json.decode(jsonStr);

    for (var jsonItem in jsonList) {
      final resource = Resource.fromJson(jsonItem);
      config[resource.type] = resource;
      current[resource.type] = 0.0; // initialize with zero
    }
  }

  double getAmount(ResourceType type) => current[type] ?? 0.0;

  void add(ResourceType type, double amount) {
    current[type] = (current[type] ?? 0.0) + amount;
  }

  bool spend(ResourceType type, double amount) {
    if ((current[type] ?? 0.0) >= amount) {
      current[type] = current[type]! - amount;
      return true;
    }
    return false;
  }

  Map<ResourceType, double> getAll() => Map.unmodifiable(current);
}
