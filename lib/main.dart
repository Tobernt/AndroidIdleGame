import 'package:flutter/material.dart';
import 'core/game_manager.dart';
import 'ui/screens/home_screen.dart'; // Use HomeScreen if you have navigation
import 'package:provider/provider.dart'; // Ensure this is at the top

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
