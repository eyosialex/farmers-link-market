import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'farm_theme.dart';

class RatingReportScreen extends StatelessWidget {
  const RatingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final stars = (gameState.healthScore * 5).clamp(0.0, 5.0).round();
    final tons  = (gameState.healthScore * gameState.landSize * 5)
        .toStringAsFixed(1);
    final insight = gameState.healthScore < 0.6
        ? 'Significant moisture stress was detected. Consider better irrigation for this crop type next cycle.'
        : 'Land preparation was solid. To improve yield further, align planting dates more closely with local rain patterns.';

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(context, 'SEASONAL RATING'),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Yield + stars card ──
              _buildYieldCard(tons, stars, gameState),
              const SizedBox(height: 20),

              // ── Metric tiles ──
              FarmTheme.sectionHeader('PERFORMANCE SCORES'),
              const SizedBox(height: 12),
              _metricTile('Land Preparation', gameState.landPrepScore,
                  Icons.landscape_outlined, FarmTheme.accent),
              _metricTile('Crop Selection', gameState.cropSelectionScore,
                  Icons.psychology_outlined, FarmTheme.accentBlue),
              _metricTile('Input Management', gameState.inputManagementScore,
                  Icons.science_outlined, FarmTheme.accentWarm),
              _metricTile('Planting Precision', gameState.plantingTimeScore,
                  Icons.timer_outlined, FarmTheme.accentRed),

              const SizedBox(height: 20),

              // ── AI insight ──
              FarmTheme.sectionHeader('AI INSIGHT'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FarmTheme.accentWarm.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
                  border: Border.all(
                      color: FarmTheme.accentWarm.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: FarmTheme.accentWarm, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(insight, style: FarmTheme.body),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              FarmTheme.primaryButton(
                text: 'Close Report',
                icon: Icons.close_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYieldCard(String tons, int stars, GameState gs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FarmTheme.cardHighlight,
      child: Column(children: [
        Text('FINAL ESTIMATED YIELD', style: FarmTheme.label.copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(
          '$tons Tons',
          style: const TextStyle(
              color: FarmTheme.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? FarmTheme.accentWarm : FarmTheme.border,
              size: 28,
            ),
          )),
        ),
        const SizedBox(height: 10),
        Text(
          '${gs.selectedCrop?.name ?? "–"}  ·  ${gs.landSize.toStringAsFixed(1)} ha',
          style: FarmTheme.caption,
        ),
      ]),
    );
  }

  Widget _metricTile(String title, double score, IconData icon, Color color) {
    final pct = (score / 5.0).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: FarmTheme.card,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: FarmTheme.label),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: FarmTheme.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 14),
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('/5', style: FarmTheme.caption),
      ]),
    );
  }
}
