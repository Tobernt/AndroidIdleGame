import 'dart:async';
import 'dart:math';
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
import 'package:big_decimal/big_decimal.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!gm.hasSelectedFaction) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FactionScreen(manager: gm.factionManager),
          ),
        );
      }
    });
  }

  void _showConquestIntro() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('⚔️ Conquest Unlocked!', style: TextStyle(color: Colors.amber)),
        content: const Text(
          "As your legend grows, rival factions grow wary.\n\n"
              "You may now challenge and **conquer** other factions.\n"
              "Each conquest grants you permanent bonuses, new spells, skills, or even the ability to assimilate them into your own empire.\n\n"
              "**Only the strongest may unify the world.**",
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

    resources.forEach((id, _) {
      final income = modifiers['${id}_per_sec'] ?? 0.0;

      final emoji = _resourceEmoji(id);
      final value = BigDecimal.parse((_smoothedValues[id] ?? 0.0).toStringAsFixed(1));
      final inc = BigDecimal.parse(income.toString());

      rows.add(
        Text(
          '$emoji ${id[0].toUpperCase()}${id.substring(1)}: ${formatBigDecimal(value)}  +${formatBigDecimal(inc)}/s',
          style: const TextStyle(color: Colors.white),
        ),
      );
    });

    if (gm.goldBoostSecondsLeft > 0) {
      rows.add(const Text('⏱️ 2× Gold Boost Active!', style: TextStyle(color: Colors.lightGreenAccent)));
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
    'essence': '✨',
    'crystals': '🔮',
  }[key] ?? '';

  String formatBigDecimal(BigDecimal number) {
    if (number.intVal == BigInt.zero) return '0';

    final doubleVal = number.toDouble().abs();

    // Show normal numbers below 1e3
    if (doubleVal < 1000) {
      return number.toPlainString();
    }

    final exponent = doubleVal == 0.0 ? 0 : (log(doubleVal) / ln10).floor();
    int scale = (exponent ~/ 3) * 3;

    // ✅ Fix: Prevent negative exponent errors
    if (scale < 0) scale = 0;

    final scaled = number.divide(
      BigDecimal.parse(pow(10, scale).toStringAsFixed(0)),
      scale: 3,
      roundingMode: RoundingMode.HALF_UP,
    );

    return '${scaled.toPlainString()}e$scale';
  }

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
          const SizedBox(height: 12),
          Text('🎯 Equipped Spells (Max $maxSpells)', style: const TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 12),
          ...gm.spellService.equippedSpells.take(maxSpells).map((spell) {
            final isReady = spell.canCast(gm.state);
            final costString = spell.costs.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}').join(', ');
            final progress = spell.cooldownProgress;

            return Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(spell.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  [
                    if (costString.isNotEmpty) 'Cost: $costString',
                    if (!isReady) 'Cooldown: ${(100 * (1 - progress)).toStringAsFixed(0)}%',
                    if (spell.description.isNotEmpty) spell.description,
                  ].join('\n'),
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  onPressed: isReady ? () {
                    gm.castSpell(spell);
                    setState(() {});
                  } : null,
                  child: const Text('Cast'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
      const BottomNavigationBarItem(icon: Icon(Icons.business), label: "Buildings"),
      const BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Skills"),
      const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Spells"),
      const BottomNavigationBarItem(icon: Icon(Icons.stars), label: "Prestige"),
      const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Achievements"),
      const BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: "Conquest"), // Always shown
    ];

    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) {
        // 🔒 Intercept Conquest Tab (index 6)
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

        // 🔓 Intercept Heroes Tab (index 7)
        if (i == 7 && !gm.state.heroesUnlocked) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('🔒 Heroes Locked'),
              content: const Text(
                'Unlock the “Chosen Champions” achievement to access Heroes.',
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

// Add this after the class, at the bottom of the file
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}