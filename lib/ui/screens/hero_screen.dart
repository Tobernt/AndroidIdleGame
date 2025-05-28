import 'dart:convert';
import 'package:androididlegame/core/game_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/heroes/hero_service.dart';
import '../../features/heroes/hero.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  bool _loading = true;
  bool _shouldSkip = false;
  @override
  void initState() {
    super.initState();
    _initHeroService();
  }

  Future<void> _initHeroService() async {
    final heroService = Provider.of<HeroService>(context, listen: false);
    final raw = await rootBundle.loadString('assets/data/hero_list.json');
    final List<dynamic> jsonList = json.decode(raw);
    final effectMap = heroService.effectMap;
    heroService.clearAll();
    for (var e in jsonList) {
      final id = e['id'];
      final effect = effectMap[id] ?? ((_, __) {});
      final hero = HeroData.fromJson(Map<String, dynamic>.from(e), effect);
      heroService.addHero(hero);
    }

    final meta = heroService.gameState.metaValues;
    final unlocked = meta['unlocked_heroes'] as List<String>? ?? [];
    heroService.loadUnlockedFromMeta(unlocked);

    if (!mounted) return;

    if (heroService.unlockedHeroes.isEmpty) {
      _shouldSkip = true;
      Future.microtask(() {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _shouldSkip) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }

    return Consumer<HeroService>(
      builder: (context, heroService, _) {
        final visible = heroService.unlockedHeroes;
        final selected = heroService.selectedHeroes;


        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('🦸 Heroes'),
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Selected: ${selected.length}',
                  style: const TextStyle(color: Colors.amber, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final hero = visible[index];
                      final isSelected = hero.selected;

                      return GestureDetector(
                        onTap: () {
                          heroService.toggleHeroSelection(hero.id);
                        },
                        child: Card(
                          color: isSelected ? Colors.green[700] : Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hero.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hero.description,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (mounted) Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continue"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
