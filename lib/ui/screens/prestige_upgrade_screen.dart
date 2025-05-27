import 'package:flutter/material.dart';
import '../../core/game_manager.dart';
import '/features/prestige/prestige_service.dart';
import '../../main.dart'; // formatNumber with AA-ZZ suffixes

class PrestigeUpgradeScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback? onDone;

  const PrestigeUpgradeScreen({
    super.key,
    required this.gameManager,
    this.onDone,
  });

  @override
  State<PrestigeUpgradeScreen> createState() => _PrestigeUpgradeScreenState();
}

class _PrestigeUpgradeScreenState extends State<PrestigeUpgradeScreen> {
  late PrestigeService prestige;

  @override
  void initState() {
    super.initState();
    prestige = widget.gameManager.prestigeService;
  }

  @override
  Widget build(BuildContext context) {
    final availablePoints = prestige.availablePrestigePoints.toDouble();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎓 Prestige Upgrades'),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Available Prestige Points: ${formatNumber(availablePoints)}',
                style: const TextStyle(color: Colors.amber, fontSize: 18),
              ),
              const SizedBox(height: 24),
              _buildUpgradeTile(
                title: '🪄 Extra Spell Slot',
                current: prestige.spellUpgradeLevel,
                max: PrestigeService.maxSpellSlotLimit - 1,
                cost: prestige.costForNextSpellSlot().toDouble(),
                onBuy: prestige.buySpellSlot,
              ),
              const SizedBox(height: 16),
              _buildUpgradeTile(
                title: '🛡️ Extra Faction Slot',
                current: prestige.factionUpgradeLevel,
                max: PrestigeService.maxFactionSlotLimit - 1,
                cost: prestige.costForNextFactionSlot().toDouble(),
                onBuy: prestige.buyFactionSlot,
              ),
              const SizedBox(height: 16),
              _buildUpgradeTile(
                title: '🧠 Extra Skill Point',
                current: prestige.extraSkillPointsBought,
                max: PrestigeService.maxTotalSkillPoints -
                    prestige.totalSkillPoints +
                    prestige.extraSkillPointsBought,
                cost: prestige.costForNextSkillPoint().toDouble(),
                onBuy: prestige.buyExtraSkillPoint,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onDone ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeTile({
    required String title,
    required int current,
    required int max,
    required double cost,
    required bool Function() onBuy,
  }) {
    final reachedMax = current >= max;
    final canAfford = prestige.availablePrestigePoints.toDouble() >= cost;

    return ListTile(
      tileColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        reachedMax ? 'Max level reached' : 'Level: $current / $max',
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: ElevatedButton(
        onPressed: (!reachedMax && canAfford)
            ? () {
          final success = onBuy();
          if (success) setState(() {});
        }
            : null,
        child: Text(reachedMax ? 'Maxed' : 'Cost: ${formatNumber(cost)}'),
      ),
    );
  }
}
