import 'modifier.dart';

class ModifierManager {
  final List<Modifier> _modifiers = [];

  /// Adds a new modifier or extends an existing one with matching ID.
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

  /// Returns combined multiplier for a given modifier ID.
  double getCombinedMultiplier(String id) {
    final active = _modifiers.where((m) => !m.isExpired && m.id == id);
    return active.fold(1.0, (acc, mod) => acc * mod.multiplier);
  }

  /// Returns time left in seconds for a modifier, or 0.
  double getRemainingTimeFor(String id) {
    return _modifiers
        .firstWhere(
          (m) => m.id == id && !m.isExpired,
      orElse: () => Modifier(id: '', multiplier: 1.0, duration: Duration.zero),
    )
        .remainingSeconds;
  }

  /// Removes all active modifiers.
  void clear() {
    _modifiers.clear();
  }

  /// Removes expired modifiers — should be called in game loop.
  void cleanup() {
    _modifiers.removeWhere((m) => m.isExpired);
  }

  /// Returns list of all active modifiers (for UI/debug).
  List<Modifier> get active => _modifiers.where((m) => !m.isExpired).toList();
}
