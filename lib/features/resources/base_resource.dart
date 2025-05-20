abstract class BaseResource {
  String get id;
  String get name;
  double get amount;
  double get generationRate;

  void tick(double dt);
}
