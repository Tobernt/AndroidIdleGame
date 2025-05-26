import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/game_state.dart';
import 'core/game_manager.dart';
<<<<<<< Updated upstream
import 'ui/screens/home_screen.dart'; // Use HomeScreen if you have navigation
import 'package:provider/provider.dart'; // Ensure this is at the top
=======
import 'ui/screens/home_screen.dart';
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameManager = GameManager();

  // Load saved game state and simulate idle gain
  await _loadGameWithIdleCatchUp(gameManager);

  await gameManager.init();
  runApp(MyApp(gameManager: gameManager));

  // Save on app pause or exit
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.paused.toString() ||
        msg == AppLifecycleState.detached.toString()) {
      await _saveGame(gameManager);
    }
    return null;
  });
}

/// Load saved state and simulate idle progress
Future<void> _loadGameWithIdleCatchUp(GameManager gameManager) async {
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('game_state');
  final lastActiveStr = prefs.getString('last_active');

  if (savedJson != null) {
    gameManager.state = GameState.fromJson(json.decode(savedJson));
    if (lastActiveStr != null) {
      final last = DateTime.tryParse(lastActiveStr);
      final now = DateTime.now();
      if (last != null) {
        final seconds = now.difference(last).inSeconds.clamp(0, 8 * 3600);
        gameManager.tickResources(seconds.toDouble());
      }
    }
  }
}

/// Save current state and last active time
Future<void> _saveGame(GameManager gameManager) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('game_state', json.encode(gameManager.state.toJson()));
  prefs.setString('last_active', DateTime.now().toIso8601String());
}

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

String formatNumber(double value, {int precision = 2}) {
  if (value == 0) return '0';

  final abs = value.abs();
  final suffixes = _generateSuffixes();
  final tier = (log(abs) / log(1000)).floor();

  final scaled = value / pow(1000, tier);
  final fixed = scaled.toStringAsFixed(precision).replaceFirst(RegExp(r'\.?0+$'), '');
  final index = (tier - 2).clamp(0, suffixes.length - 1);

  if (tier < 2) {
    return '$fixed${tier == 1 ? 'K' : ''}';
  }

  return '$fixed${suffixes[index]}';
}

/// Generate aa, ab, ..., zz (max 26*26 = 676)
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
