import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import '../../services/ads_service.dart';
import 'faction_screen.dart';
import 'skill_screen.dart';
import 'building_screen.dart';
import 'equip_spells_screen.dart';
import 'prestige_screen.dart';
import 'achievement_screen.dart';
import 'conquest_screen.dart';
import 'hero_screen.dart';
import '../../main.dart';

class GameScreen extends StatefulWidget {
  final GameManager gameManager;

  const GameScreen({super.key, required this.gameManager});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameManager gm;
  late final Timer _updateTimer;
  late final Timer _smoothTimer;
  final Map<String, double> _smoothedValues = {};
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    gm = widget.gameManager;
    gm.isGameplayActive = true;

    _initializeResourceSmoothing();
    _startTickLoop();
    _startSmoothingLoop();
    _checkFactionSelection();
  }

  void _initializeResourceSmoothing() {
    for (final entry in gm.state.resourceAmounts.entries) {
      _smoothedValues[entry.key] = entry.value;
    }
  }

  void _startTickLoop() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      gm.tickResources(0.5);
      if (gm.conquestManager.conquestUnlocked && !gm.state.conquestIntroShown) {
        gm.state.conquestIntroShown = true;
        _showConquestIntro();
      }
      setState(() {});
    });
  }

  void _startSmoothingLoop() {
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      const speed = 0.15;
      for (final key in _smoothedValues.keys) {
        final actual = gm.state.getResource(key);
        final current = _smoothedValues[key] ?? 0.0;
        final diff = actual - current;
        _smoothedValues[key] = current + diff * speed;
      }
      setState(() {});
    });
  }

  void _checkFactionSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!gm.hasSelectedFaction) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FactionScreen(manager: gm.factionManager),
          ),
        );
      }
      if (mounted) _maybeShowTutorial();
    });
  }

  void _maybeShowTutorial() {
    if (gm.state.firstPrestigeGuideDone || gm.state.totalPrestiges > 0) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Path to Prestige',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Text(
          'Would you like guidance on forging your first legend? ',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              gm.state.firstPrestigeGuideDone = true;
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _runPrestigeGuide();
            },
            child: const Text('Begin'),
          ),
        ],
      ),
    );
  }

  Future<void> _runPrestigeGuide() async {
    final steps = <_GuideStep>[
      _GuideStep(
        message:
            '1. Construct your first building to lay the foundation of your realm.',
        requirement: () =>
            gm.buildingService.buildings.any((b) => b.level > 0),
      ),
      _GuideStep(
        message:
            '2. Tap the screen to collect tribute from your subjects.',
        requirement: () => gm.state.lifetimeTaps >= 10,
      ),
      _GuideStep(
        message:
            '3. Open the Spells tab and wield a new arcane power.',
        requirement: () => gm.spellService.allSpells.any((s) => s.unlocked),
      ),
      _GuideStep(
        message: '4. Return here and unleash your spell upon the world.',
        requirement: () => gm.state.totalSpellsCast > 0,
      ),
      _GuideStep(
        message:
            '5. Amass 100k gold, claim the achievement, then ascend via Prestige.',
        requirement: () =>
            gm.prestigeService.lifetimeGold >= 100000 &&
            gm.state.totalPrestiges > 0,
      ),
    ];

    for (final step in steps) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Text(step.message,
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      while (!step.requirement()) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    setState(() => _selectedTab = 4);
    gm.state.firstPrestigeGuideDone = true;
  }

  void _showConquestIntro() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('⚔️ Conquest Awaits', style: TextStyle(color: Colors.amber)),
        content: const Text(
          "Rival realms sense your power.\n\n"
          "March forth to challenge them and expand your dominion.\n"
          "Each victory grants permanent boons, new spells and skills, or even lets you absorb their strength.\n\n"
          "**Only a true warlord can unite these lands.**",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Begin Conquest", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gm.isGameplayActive = false;
    _updateTimer.cancel();
    _smoothTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            gm.tapGold();
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTabContent(),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final rows = <Widget>[];
    final resources = gm.state.resourceAmounts;
    final modifiers = gm.state.resourceModifiers;

    resources.forEach((id, value) {
      final income = modifiers['${id}_per_sec'] ?? 0.0;
      final emoji = _resourceEmoji(id);
      final smoothed = _smoothedValues[id] ?? 0.0;

      rows.add(
        Text(
          '$emoji ${id[0].toUpperCase()}${id.substring(1)}: ${formatNumber(smoothed)}  +${formatNumber(income)}/s',
          style: const TextStyle(color: Colors.white),
        ),
      );
    });

    final endStr = gm.state.metaValues['gold_ad_bonus_ends'];
    if (endStr is String) {
      final endTime = DateTime.tryParse(endStr);
      if (endTime != null && endTime.isAfter(DateTime.now())) {
        final duration = endTime.difference(DateTime.now());
        final minutes = duration.inMinutes % 60;
        final hours = duration.inHours;
        final seconds = duration.inSeconds % 60;
        final remainingTime = '${hours}h ${minutes}m ${seconds}s';

        rows.add(
          Text(
            '⏱️ 2× Boost Active — $remainingTime left',
            style: const TextStyle(color: Colors.lightGreenAccent),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  String _resourceEmoji(String key) => {
    'gold': '💰',
    'mana': '💧',
    'ore': '⛏️',
    'population': '🧟',
  }[key] ?? '';

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildMainContent();
      case 1: return BuildingScreen(gameManager: gm);
      case 2: return SkillScreen(
        manager: gm.skillManager,
        state: gm.state,
        selectedFactions: gm.factionManager.selected.map((f) => f.id).toList(),
      );
      case 3: return EquipSpellsScreen(gameManager: gm);
      case 4: return PrestigeScreen(gameManager: gm);
      case 5: return AchievementScreen(
        achievementService: gm.achievementService,
        gameState: gm.state,
        onConquestUnlocked: () => setState(() {}),
      );
      case 6:
        return gm.conquestManager.conquestUnlocked
            ? ConquestScreen(gameManager: gm)
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '⚔️ Conquest will unlock after reaching Prestige 10 and claiming the achievement.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        );
      case 7:
        return gm.state.heroesUnlocked
            ? const HeroScreen()
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '👥 Heroes will unlock through gameplay achievements.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        );
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildMainContent() {
    final maxSpells = gm.prestigeService.maxEquippedSpells;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              final ads = AdsService();
              await ads.showRewardedAd(() {
                gm.addGoldAdModifier();
                setState(() {});
              });
            },
            child: const Text('📺 Watch Ad for 2× Gold (4h)'),
          ),
          const SizedBox(height: 16),
          const Text('💥 Tap anywhere to gain gold 💰', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white30),
          if (gm.spellService.equippedSpells.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('🎯 Equipped Spells (Max $maxSpells)',
                style: const TextStyle(fontSize: 18, color: Colors.amber)),
            const SizedBox(height: 12),
          ],
          ...gm.spellService.equippedSpells.take(maxSpells).map((spell) {
            final isReady = spell.canCast(gm.state);

            final costString = spell.costs.entries.map((e) {
              final reduced = spell.getFinalCost(e.key, gm.state);
              return '${e.key}: ${reduced.toStringAsFixed(0)}';
            }).join(', ');

            final remaining = spell.getRemainingCooldown(gm.state);
            final cooldownString = remaining == Duration.zero
                ? 'CD: ${spell.getFinalCooldown(gm.state).inSeconds}s'
                : 'Cooldown: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s';

            final isDivineAura = spell.id == 'human_spell_5';
            final isDivineAuraActive = isDivineAura && gm.state.metaValues['divine_aura_active'] == true;

            return Card(
              color: isDivineAuraActive ? Colors.blue[800] : Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  if (isDivineAuraActive)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(right: 120),
                          color: Colors.blue.withAlpha(125),
                        ),
                      ),
                    ),
                  if (!isDivineAura && spell.isInDuration)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 1.0 - spell.durationProgress,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(right: 120),
                              color: Colors.blue.withAlpha(125),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spell.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (costString.isNotEmpty) 'Cost: $costString',
                                  if (!isReady || remaining > Duration.zero) cooldownString,
                                  if (spell.description.isNotEmpty) spell.description,
                                ].join('\n'),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isReady
                              ? () {
                            gm.castSpell(spell);
                            setState(() {});
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isDivineAuraActive || spell.isInDuration)
                                ? Colors.blue
                                : null,
                          ),
                          child: Text(
                            isDivineAura
                                ? (isDivineAuraActive ? 'Deactivate' : 'Activate')
                                : 'Cast',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final hasUnclaimedAchievements = gm.achievementService.all.any(
          (a) => a.isUnlocked && !a.isClaimed,
    );

    final tabs = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
      const BottomNavigationBarItem(icon: Icon(Icons.business), label: "Buildings"),
      const BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Skills"),
      const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Spells"),
      const BottomNavigationBarItem(icon: Icon(Icons.stars), label: "Prestige"),

      BottomNavigationBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.emoji_events),
            if (hasUnclaimedAchievements)
              const Positioned(
                top: -6,
                right: -4,
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        label: "Achievements",
      ),

      const BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: "Conquest"),
    ];

    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) {
        if (i == 6) {
          final conquestAchievement = gm.achievementService.all
              .firstWhereOrNull((a) => a.reward?.type == 'unlock_conquest');
          final isClaimed = conquestAchievement?.isClaimed ?? false;

          if (!isClaimed) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('🔒 Conquest Locked'),
                content: const Text(
                  'You must prestige 10 times and claim the “Unify the World” achievement to unlock Conquest.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        }

        setState(() => _selectedTab = i);
      },
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFFB0C4DE),
      type: BottomNavigationBarType.fixed,
      items: tabs,
    );
  }
}

class _GuideStep {
  final String message;
  final bool Function() requirement;

  _GuideStep({required this.message, required this.requirement});
}

// Add this after the class, at the bottom of the file
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}