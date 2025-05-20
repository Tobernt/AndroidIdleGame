import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import 'faction_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  final GameManager gameManager;

  const HomeScreen({super.key, required this.gameManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialized = false;
  bool inGameScreen = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (widget.gameManager.isInitialized) {
      setState(() => initialized = true);
    } else {
      await widget.gameManager.init();
      setState(() => initialized = true);
    }
  }

  void _enterGameScreen() {
    setState(() => inGameScreen = true);
  }

  void restartGame() {
    widget.gameManager.init();
    setState(() {
      inGameScreen = true;
      initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (inGameScreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: GameScreen(gameManager: widget.gameManager),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FactionScreen(
        manager: widget.gameManager.factionManager,
        onConfirm: _enterGameScreen,
        hideBack: true,
      ),
    );
  }
}
