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

class GameScreen extends StatefulWidget {
  final GameManager gameManager;

  const GameScreen({super.key, required this.gameManager});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameManager gm;
  late Timer _updateTimer;
  int _selectedTab = 0;
  bool _wasConquestUnlocked = false;

  @override
  void initState() {
    super.initState();
    gm = widget.gameManager;
    _wasConquestUnlocked = gm.conquestManager.conquestUnlocked;

    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      gm.tickResources(0.5);

      // ✅ catch conquest unlock at runtime (via achievement, etc)
      final conquestNow = gm.conquestManager.conquestUnlocked;
      if (conquestNow && !_wasConquestUnlocked) {
        _wasConquestUnlocked = true;

        if (!gm.state.conquestIntroShown) {
          gm.state.conquestIntroShown = true;
          _showConquestIntro();
        }

        setState(() {}); // rebuild navbar
      }

      setState(() {}); // standard UI tick
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!gm.hasSelectedFaction) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FactionScreen(manager: gm.factionManager),
          ),
        );
        return;
      }

      // ✅ keep this block if required by navigation timing or transition
      Future.delayed(const Duration(milliseconds: 600), () {
        final conquestNow = gm.conquestManager.conquestUnlocked;

        if (mounted &&
            conquestNow &&
            !_wasConquestUnlocked &&
            !gm.state.conquestIntroShown) {
          _wasConquestUnlocked = true;
          gm.state.conquestIntroShown = true;
          _showConquestIntro();
          setState(() {}); // rebuild navbar
        }
      });
    });
  }

  void _showConquestIntro() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '⚔️ Conquest Unlocked!',
          style: TextStyle(color: Colors.amber),
        ),
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
  String formatEngineering(double number) {
    if (number == 0) return '0';
    const suffixes = {
      0: '',
      3: 'K',
      6: 'M',
      9: 'B',
      12: 'T',
      15: 'Qa',
      18: 'Qi',
      21: 'Sx',
      24: 'Sp',
      27: 'Oc',
      30: 'No',
      33: 'Dc',
    };
    int exponent = (number == 0)
        ? 0
        : (log(number.abs()) / log(10)).floor() ~/ 3 * 3;
    double scaled = number / pow(10, exponent);
    String suffix = suffixes[exponent] ?? 'e$exponent';
    return '${scaled.toStringAsFixed(3)}$suffix';
  }

  Widget _buildTopBar() {
    final rows = <Widget>[];
    final resources = gm.state.resourceAmounts;
    final modifiers = gm.state.resourceModifiers;

    resources.forEach((id, value) {
      final income = modifiers['${id}_per_sec'] ?? 0.0;
      final emoji = _resourceEmoji(id);
      rows.add(
        Text(
          '$emoji ${id[0].toUpperCase()}${id.substring(1)}: ${formatEngineering(value)}  '
              '+${formatEngineering(income)}/s',
          style: const TextStyle(color: Colors.white),
        ),
      );
    });
    if (gm.goldBoostSecondsLeft > 0) {
      rows.add(Text(
        '⏱️ 2× Gold Boost Active!',
        style: const TextStyle(color: Colors.lightGreenAccent),
      ));
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

  /// Maps resource keys to emoji for quick visual identification
  String _resourceEmoji(String key) {
    switch (key) {
      case 'gold':
        return '💰';
      case 'mana':
        return '💧';
      case 'ore':
        return '⛏️';
      case 'population':
        return '🧟';
      case 'essence':
        return '✨';
      case 'crystals':
        return '🔮';
      default:
        return '';
    }
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildMainContent();
      case 1:
        return BuildingScreen(gameManager: gm);
      case 2:
        return SkillScreen(
          manager: gm.skillManager,
          state: gm.state,
          selectedFactions: gm.factionManager.selected.map((f) => f.id).toList(),
        );
      case 3:
        return EquipSpellsScreen(gameManager: gm);
      case 4:
        return PrestigeScreen(gameManager: gm);
      case 5:
        return AchievementScreen(
          achievementService: gm.achievementService,
          gameState: gm.state, // ✅ FIXED: provide required gameState
        );
      case 6:
        return gm.conquestManager.conquestUnlocked
            ? ConquestScreen(gameManager: gm)
            : const SizedBox.shrink();
      case 7:
        return gm.state.heroesUnlocked
            ? HeroScreen(heroService: gm.heroService)
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
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
          const Text(
            '💥 Tap anywhere to gain gold 💰',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white30),
          const SizedBox(height: 12),
          Text('🎯 Equipped Spells (Max $maxSpells)', style: const TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 12),
          ...gm.spellService.equippedSpells
              .take(maxSpells)
              .map((spell) {
            final isReady = spell.canCast(gm.state);
            final costString = spell.costs.entries
                .map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}')
                .join(', ');
            final progress = spell.cooldownProgress;

            return Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  spell.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${costString.isNotEmpty ? 'Cost: $costString\n' : ''}'
                      '${isReady ? '' : '- Cooldown: ${(100 * (1 - progress)).toStringAsFixed(0)}%'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: ElevatedButton(
                  onPressed: isReady
                      ? () {
                    gm.castSpell(spell);
                    setState(() {});
                  }
                      : null,
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
    final conquestUnlocked = gm.conquestManager.conquestUnlocked;
    final heroesUnlocked = gm.state.heroesUnlocked;
    final canConquer = gm.conquestManager.conquerableFactions.isNotEmpty;

    final tabs = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Main"),
      const BottomNavigationBarItem(icon: Icon(Icons.business), label: "Buildings"),
      const BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Skills"),
      const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Spells"),
      const BottomNavigationBarItem(icon: Icon(Icons.stars), label: "Prestige"),
      const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Achievements"),
    ];

    if (conquestUnlocked) {
      tabs.add(
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.military_tech),
              if (canConquer)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  ),
                ),
            ],
          ),
          label: "Conquest",
        ),
      );
    }

    if (heroesUnlocked) {
      tabs.add(const BottomNavigationBarItem(
        icon: Icon(Icons.supervisor_account),
        label: "Heroes",
      ));
    }

    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) => setState(() => _selectedTab = i),
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFFB0C4DE),
      type: BottomNavigationBarType.fixed,
      items: tabs,
    );
  }
}
