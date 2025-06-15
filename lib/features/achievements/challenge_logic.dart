import '../../core/game_state.dart';

class ChallengeLogic {
  static bool evaluate({
    required String id,
    required GameState state,
    required double lifetimeGold,
    required int buildingsOwned,
    required int tapCount,
  }) {
    final now = DateTime.now();

    switch (id) {
    // === GLOBAL TIME WINDOW ===

      case 'tap_300_in_60s':
        final elapsed = state.currentRunTime;
        return elapsed < Duration(seconds: 60) && state.currentRunTaps >= 300;

      case 'cast_5_spells_in_60s':
        final recentCasts = state.recentSpellCastTimestamps
            .where((t) => now.difference(t).inSeconds <= 60)
            .length;
        return recentCasts >= 5;

      case 'gain_1000_gold_in_30s':
        final runStart = state.currentRunStart;
        final timeSinceRun = now.difference(runStart);
        return timeSinceRun < Duration(seconds: 30) &&
            (state.lifetimeResources['gold'] ?? 0.0) >= 1000.0;

      case 'conquer_2_factions_in_120s':
        final conquestStart = DateTime.tryParse(state.metaValues['conquest_start'] ?? '');
        if (conquestStart == null) return false;
        final elapsed = now.difference(conquestStart);
        return elapsed <= Duration(seconds: 120) &&
            state.conqueredFactions.length >= 2;

    // === TRIGGERED TIME WINDOW ===

      case 'cast_3_spells_within_60s_of_first_cast':
        final firstCastStr = state.metaValues['first_spell_cast_time'] as String?;
        if (firstCastStr == null) return false;

        final firstCast = DateTime.tryParse(firstCastStr);
        if (firstCast == null) return false;

        final spellWindow = now.difference(firstCast);
        if (spellWindow > Duration(seconds: 60)) return false;

        final recent = state.recentSpellCastTimestamps
            .where((t) => t.isAfter(firstCast))
            .length;
        return recent >= 3;

      case 'tap_200_within_30s_of_first_tap':
        final firstTapStr = state.metaValues['first_tap_time'] as String?;
        if (firstTapStr == null) return false;

        final firstTap = DateTime.tryParse(firstTapStr);
        if (firstTap == null) return false;

        final tapWindow = now.difference(firstTap);
        if (tapWindow > Duration(seconds: 30)) return false;

        final count = (state.metaValues['taps_after_first'] ?? 0).toInt();
        return count >= 200;
      case 'defeat_undead_within_60s_of_prestige':
        final lastPrestige = state.lastPrestigeTime;
        final now = DateTime.now();
        final elapsed = now.difference(lastPrestige);

        final defeatedUndead = state.conqueredFactions.contains('undead') ||
            state.destroyedFactions.contains('undead');

        return elapsed <= Duration(seconds: 60) && defeatedUndead;

      default:
        if (id.startsWith('mana_regen_')) {
          final value = double.tryParse(id.split('_').last) ?? 0.0;
          return state.getManaRegenPerSecond() >= value;
        }
        return false;
    }
  }
}