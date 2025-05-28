import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/game_manager.dart';
import 'faction_screen.dart';
import 'game_screen.dart';
import 'dart:async';

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
      await widget.gameManager.init();
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
            ],
          ),
        ),
      ),
    );
  }
}
