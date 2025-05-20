import 'modifier.dart';

class ModifierManager {
  final List<Modifier> _modifiers = [];

  void addModifier(Modifier modifier) {
    final existing = _modifiers.firstWhere(
          (m) => m.id == modifier.id && !m.isExpired,
      orElse: () => Modifier(id: '', multiplier: 1.0, duration: Duration.zero),
    );

    if (existing.id.isNotEmpty) {
      final timeLeft = existing.remainingSeconds;
      _modifiers.remove(existing);
      _modifiers.add(Modifier(
        id: modifier.id,
        multiplier: modifier.multiplier,
        duration: Duration(seconds: (timeLeft + modifier.duration.inSeconds).toInt()),
      ));
    } else {
      _modifiers.add(modifier);
    }
  }

  /// 💡 Multiplies all active modifiers for given resource
  double getCombinedMultiplier(String id) {
    final active = _modifiers.where((m) => !m.isExpired && m.id == id);
    return active.fold(1.0, (acc, mod) => acc * mod.multiplier);
  }

  double getRemainingTimeFor(String id) {
    return _modifiers
        .firstWhere((m) => m.id == id && !m.isExpired, orElse: () => Modifier(id: '', multiplier: 1.0, duration: Duration.zero))
        .remainingSeconds;
  }
  void clear() {
    _modifiers.clear();
  }

  void cleanup() {
    _modifiers.removeWhere((m) => m.isExpired);
  }
}
