import 'package:flutter/material.dart';
import 'core/game_manager.dart';
import 'ui/screens/home_screen.dart'; // Use HomeScreen if you have navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures async init can run

  final gameManager = GameManager();
  await gameManager.init(); // Properly await init

  runApp(MyApp(gameManager: gameManager));
}

class MyApp extends StatelessWidget {
  final GameManager gameManager;

  const MyApp({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idle Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(gameManager: gameManager), // Prefer HomeScreen
    );
  }
}
