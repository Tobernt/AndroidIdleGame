import 'package:flutter/material.dart';
import '../../features/heroes/hero_service.dart';

class HeroScreen extends StatefulWidget {
  final HeroService heroService;

  const HeroScreen({super.key, required this.heroService});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  @override
  Widget build(BuildContext context) {
    final unlocked = widget.heroService.unlockedHeroes;
    final selected = widget.heroService.selectedHeroes;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🦸 Heroes'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: unlocked.isEmpty
            ? const Center(
          child: Text(
            'No heroes unlocked yet.',
            style: TextStyle(color: Colors.white70),
          ),
        )
            : Column(
          children: [
            Text(
              'Roster Slots: ${selected.length} / ${widget.heroService.maxRosterSize}',
              style: const TextStyle(color: Colors.amber, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: unlocked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final hero = unlocked[index];
                  final isSelected = selected.contains(hero);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.heroService.toggleHeroSelection(hero.id);
                      });
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
                                  const Icon(Icons.check_circle,
                                      color: Colors.lightGreenAccent),
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
          ],
        ),
      ),
    );
  }
}
