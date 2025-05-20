class Modifier {
  final String id;
  final double multiplier;
  final Duration duration;
  final DateTime _startTime;

  Modifier({
    required this.id,
    required this.multiplier,
    required this.duration,
  }) : _startTime = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(_startTime.add(duration));

  double get remainingSeconds {
    final end = _startTime.add(duration);
    return end
        .difference(DateTime.now())
        .inSeconds
        .toDouble()
        .clamp(0, duration.inSeconds.toDouble());
  }

  double get progress => remainingSeconds / duration.inSeconds;
}
