import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/modifiers/modifier.dart';
import 'core/game_state.dart';
import 'core/game_manager.dart';
import 'ui/screens/home_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final gameManager = GameManager();

  // Load from storage if available
  final loaded = await _loadGameWithIdleCatchUp(gameManager);

  // If no saved state, initialize fresh
  if (!loaded) {
    await gameManager.init();
  }

  // Save on app pause/detach
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.paused.toString() ||
        msg == AppLifecycleState.detached.toString()) {
      await _saveGame(gameManager);
    }
    return null;
  });

  runApp(MyApp(gameManager: gameManager));
}

/// Load saved state and simulate idle resources
Future<bool> _loadGameWithIdleCatchUp(GameManager gm) async {
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('game_state');
  final lastActiveStr = prefs.getString('last_active');

  if (savedJson != null) {
    try {
      gm.state = GameState.fromJson(json.decode(savedJson));
      await gm.init(fromLoad: true); // initialize all services
      gm.restoreFromState();         // now safe to restore from state
      if (lastActiveStr != null) {
        final last = DateTime.tryParse(lastActiveStr);
        if (last != null) {
          final seconds = DateTime.now().difference(last).inSeconds.clamp(0, 8 * 3600);
          gm.tickResources(seconds.toDouble());
          if (gm.state.adGoldBoostActive) {
            gm.state.adGoldBoostRemainingSeconds -= seconds;
            if (gm.state.adGoldBoostRemainingSeconds <= 0) {
              gm.state.adGoldBoostActive = false;
              gm.state.adGoldBoostRemainingSeconds = 0;
            } else {
              gm.modifierManager.addModifier(
                Modifier(
                  id: 'gold',
                  multiplier: 2.0,
                  duration: Duration(seconds: gm.state.adGoldBoostRemainingSeconds),
                ),
              );
            }
          }
          debugPrint("✅ Game state loaded with ${gm.state} gold");
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ Failed to load save: $e');
    }
  }
  return false;
}

Future<void> _saveGame(GameManager gm) async {
  gm.prepareStateForSave();
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('game_state', json.encode(gm.state.toJson()));
  prefs.setString('last_active', DateTime.now().toIso8601String());
  debugPrint("✅ Game saved to SharedPreferences");
}



/// App Root
class MyApp extends StatelessWidget {
  final GameManager gameManager;

  const MyApp({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gameManager.heroService,
      child: MaterialApp(
        title: 'Idle Realms',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: HomeScreen(gameManager: gameManager),
      ),
    );
  }
}

/// Format numbers like 1.2AB, 3.5K, etc.
String formatNumber(double value, {int precision = 1}) {
  if (value == 0) return '0';

  final abs = value.abs();
  final suffixes = _generateSuffixes();
  final tier = max(0, (log(abs) / log(1000)).floor());

  final scaled = value / pow(1000, tier);
  final fixed = scaled.toStringAsFixed(precision).replaceFirst(RegExp(r'\.?0+$'), '');

  if (tier == 0) return fixed;
  if (tier == 1) return '${fixed}K';

  final index = (tier - 2).clamp(0, suffixes.length - 1);
  return '$fixed${suffixes[index]}';
}

/// aa–zz suffixes
List<String> _generateSuffixes() {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final suffixes = <String>[];
  for (final a in chars.split('')) {
    for (final b in chars.split('')) {
      suffixes.add('$a$b');
    }
  }
  return suffixes.map((s) => s.toUpperCase()).toList();
}
