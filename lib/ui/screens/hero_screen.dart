import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/heroes/hero_service.dart';
import '../../features/heroes/hero.dart';

class HeroScreen extends StatelessWidget {
  const HeroScreen({super.key});

  Future<void> _initHeroService(BuildContext context) async {
    final heroService = Provider.of<HeroService>(context, listen: false);

    // Load hero list from JSON asset
    final raw = await rootBundle.loadString('assets/data/hero_list.json');
    final List<dynamic> jsonList = json.decode(raw);

    final effectMap = heroService.effectMap;

    heroService.clearAll(); // Optional cleanup
    for (var e in jsonList) {
      final id = e['id'];
      final effect = effectMap[id] ?? ((_, __) {});
      final hero = HeroData.fromJson(Map<String, dynamic>.from(e), effect);
      heroService.addHero(hero);
    }

    final meta = heroService.gameState.metaValues;
    final unlocked = meta['unlocked_heroes'] as List<String>? ?? [];
    heroService.loadUnlockedFromMeta(unlocked);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initHeroService(context),
      builder: (context, snapshot) {
        return Consumer<HeroService>(
          builder: (context, heroService, _) {
            final visible = heroService.unlockedHeroes;
            final selected = heroService.selectedHeroes;

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: const Text('🦸 Heroes'),
                backgroundColor: Colors.black,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: visible.isEmpty
                    ? const Center(
                  child: Text(
                    'No heroes unlocked yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : Column(
                  children: [
                    Text(
                      'Roster Slots: ${selected.length} / ${heroService.maxRosterSize}',
                      style: const TextStyle(
                          color: Colors.amber, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final hero = visible[index];
                          final isSelected = hero.selected;

                          return GestureDetector(
                            onTap: () {
                              heroService.toggleHeroSelection(hero.id);
                            },
                            child: Card(
                              color: isSelected
                                  ? Colors.green[700]
                                  : Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                          const Icon(Icons.check_circle,
                                              color: Colors
                                                  .lightGreenAccent),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hero.description,
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
