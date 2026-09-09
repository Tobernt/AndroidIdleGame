# Android Idle Game

A Flutter idle-game prototype with resource production, buildings, heroes, factions, spells, achievements and prestige progression. Game state is stored locally using SharedPreferences.

## Run

Install Flutter with a compatible Dart SDK (the package requires Dart 3.7.2 or later), then run:

```sh
flutter pub get
flutter run
```

## Code guide

- `lib/core`: game state, progression and orchestration.
- `lib/features`: resources, buildings, heroes, spells and progression systems.
- `lib/ui/screens`: game screens and controls.
- `lib/services`: rewarded-ad simulation and in-app purchase integration.

Rewarded ads are simulated locally. Real purchases and Play Games sign-in require separate store configuration; the repository is not a store-ready release. The Android release configuration still uses debug signing.

Use `flutter analyze` for static checks. No automated game tests are currently included.
