import 'resource_manager.dart';
import 'resource_type.dart';

class ResourceService {
  final ResourceManager manager;

  ResourceService(this.manager);

  void tickIncome(double multiplier) {
    for (var entry in manager.config.entries) {
      final resource = entry.value;
      final amount = resource.baseGeneration * multiplier;
      manager.add(resource.type, amount);
    }
  }

  bool trySpend(ResourceType type, double amount) {
    return manager.spend(type, amount);
  }

  double getAmount(ResourceType type) => manager.getAmount(type);
}
