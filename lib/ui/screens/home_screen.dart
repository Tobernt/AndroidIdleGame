import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/game_manager.dart';
import 'faction_screen.dart';
import 'game_screen.dart';
import 'info_screen.dart';
import 'dart:async';
import '../../core/game_state.dart';

class HomeScreen extends StatefulWidget {
  final GameManager gameManager;

  const HomeScreen({super.key, required this.gameManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialized = false;
  Duration idleDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('last_active');

    if (lastActiveStr != null) {
      final last = DateTime.tryParse(lastActiveStr);
      if (last != null) {
        final now = DateTime.now();
        final diff = now.difference(last);
        final clamped = diff < Duration.zero
            ? Duration.zero
            : (diff > const Duration(hours: 8)
            ? const Duration(hours: 8)
            : diff);
        idleDuration = clamped;
      }
    }

    if (!widget.gameManager.isInitialized) {
      await widget.gameManager.init(idleDuration: idleDuration);
    }

    // ✅ Stay on HomeScreen regardless of faction
    setState(() => initialized = true);
  }

  void _saveLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_active', DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    _saveLastActiveTime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Idle Realms',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.amber),
            ],
          ),
        ),
      );
    }

    final idleText = idleDuration.inSeconds > 0
        ? 'Welcome back!\nYou were away for ${idleDuration.inHours}h '
        '${idleDuration.inMinutes % 60}m ${idleDuration.inSeconds % 60}s.'
        : 'Welcome to Idle Realms!';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Idle Realms',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                idleText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final hasFaction = widget.gameManager.hasSelectedFaction;

                  if (hasFaction) {
                    // Already selected, go directly to game screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(gameManager: widget.gameManager),
                      ),
                    );
                  } else {
                    // Let user select faction, then continue from HeroScreen to GameScreen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FactionScreen(
                          manager: widget.gameManager.factionManager,
                          hideBack: true,
                        ),
                      ),
                    );

                    if (mounted && result == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(gameManager: widget.gameManager),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 32),
                ),
                child: const Text('Enter Game'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                ),
                child: const Text('How to Play'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Reset Game?"),
                      content: const Text("This will erase all progress and reset the game completely. Are you sure?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Reset", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    // 🚫 Dispose of the old manager
                    widget.gameManager.dispose();

                    // ✅ Create a fresh one
                    final newManager = GameManager();
                    await newManager.init();

                    // ✅ Rebuild the HomeScreen with the new instance
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(gameManager: newManager),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                ),
                child: const Text('Full Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
