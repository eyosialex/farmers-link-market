import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'land_selection_screen.dart';
import 'farm_main_screen.dart';
import 'farm_theme.dart';

class GameDashboard extends StatelessWidget {
  const GameDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(context, l10n.virtualFarmSimulator),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(context, l10n),
                const SizedBox(height: 28),
                _buildFeatureGrid(context, l10n),
                const SizedBox(height: 28),
                _buildActionSection(context, l10n, gameState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero Banner ───────────────────────────────────────────────
  Widget _buildHeroBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FarmTheme.accent.withOpacity(0.15),
            FarmTheme.accent.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FarmTheme.radiusXl),
        border: Border.all(color: FarmTheme.accent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FarmTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
            ),
            child: const Icon(Icons.agriculture, color: FarmTheme.accent, size: 36),
          ),
          const SizedBox(height: 20),
          Text(l10n.welcomeVirtualFarm, style: FarmTheme.headingLg),
          const SizedBox(height: 10),
          Text(
            l10n.gameIntro,
            style: FarmTheme.body.copyWith(color: FarmTheme.textMuted),
          ),
          const SizedBox(height: 16),
          // Tag pills
          Wrap(spacing: 8, runSpacing: 8, children: [
            _tagPill(Icons.science_outlined, 'AI-Powered'),
            _tagPill(Icons.cloud, 'Weather Sim'),
            _tagPill(Icons.bar_chart, 'Analytics'),
          ]),
        ],
      ),
    );
  }

  Widget _tagPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: FarmTheme.pill,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: FarmTheme.accent, size: 12),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: FarmTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── Feature Grid ──────────────────────────────────────────────
  Widget _buildFeatureGrid(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FarmTheme.sectionHeader('WHAT YOU CAN DO'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _featureCard(Icons.water_drop_outlined,   'Soil Tracking',    'Monitor moisture & nutrients',  FarmTheme.accentBlue),
            _featureCard(Icons.pest_control,          'Risk Alerts',       'Pest, disease & weed alerts',  FarmTheme.accentRed),
            _featureCard(Icons.auto_awesome,          'AI Advisor',        'Gemini-powered farm advice',   FarmTheme.accentWarm),
            _featureCard(Icons.trending_up,           'Yield Reports',     'Track progress each day',      FarmTheme.accent),
          ],
        ),
      ],
    );
  }

  Widget _featureCard(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: FarmTheme.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(title, style: FarmTheme.headingMd.copyWith(fontSize: 13)),
        const SizedBox(height: 3),
        Text(sub, style: FarmTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ─── Action Section ────────────────────────────────────────────
  Widget _buildActionSection(BuildContext context, AppLocalizations l10n, GameState gameState) {
    final hasActiveGame = gameState.currentDay > 0 && !gameState.isGameOver;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FarmTheme.sectionHeader('YOUR FARM'),
        const SizedBox(height: 14),

        if (hasActiveGame) ...[
          // Active game status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: FarmTheme.cardHighlight,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: FarmTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.play_circle_filled, color: FarmTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Active Simulation', style: FarmTheme.headingMd),
                  Text(
                    gameState.currentLandName ?? 'My Plot',
                    style: FarmTheme.caption,
                  ),
                ]),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                FarmTheme.statChip(Icons.calendar_today, 'Day ${gameState.currentDay}', 'CURRENT', FarmTheme.accent),
                const SizedBox(width: 10),
                FarmTheme.statChip(Icons.trending_up, '${gameState.growthProgress.toInt()}%', 'GROWTH', FarmTheme.accentWarm),
                const SizedBox(width: 10),
                FarmTheme.statChip(Icons.favorite, '${(gameState.healthScore * 100).toInt()}%', 'HEALTH', FarmTheme.accentBlue),
              ]),
              const SizedBox(height: 16),
              FarmTheme.primaryButton(
                text: l10n.continueFarming(gameState.currentDay),
                icon: Icons.play_arrow,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmMainScreen())),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Center(
            child: FarmTheme.ghostButton(
              text: l10n.resetStartNew,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLandsScreen())),
            ),
          ),
        ] else ...[
          // No active game
          Container(
            padding: const EdgeInsets.all(24),
            decoration: FarmTheme.card,
            child: Column(children: [
              Icon(Icons.landscape_outlined, color: FarmTheme.textMuted, size: 48),
              const SizedBox(height: 14),
              Text(
                'No active simulation',
                style: FarmTheme.headingMd.copyWith(color: FarmTheme.textMuted),
              ),
              const SizedBox(height: 6),
              Text('Create a land plot and start your virtual farm journey.',
                style: FarmTheme.caption, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FarmTheme.primaryButton(
                text: l10n.startNewFarm,
                icon: Icons.add_location_alt,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLandsScreen())),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
