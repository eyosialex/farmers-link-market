import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import '../models/game_state.dart';
import 'farm_theme.dart';

class FarmingReportScreen extends StatelessWidget {
  const FarmingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final completed  = gameState.completedActivities;
    final total      = gameState.customActivities.length;
    final rate       = total == 0 ? 0.0 : (completed.length / total);
    final tonsEst    = (gameState.healthScore * gameState.landSize * 5)
        .toStringAsFixed(1);

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(context, 'SEASONAL REPORT'),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Activity completion ring ──
              _buildCompletionRing(rate, completed.length, total),
              const SizedBox(height: 16),

              // ── Score cards row ──
              _buildScoreCards(gameState),
              const SizedBox(height: 16),

              // ── Yield estimate ──
              _buildYieldBanner(tonsEst, gameState),
              const SizedBox(height: 16),

              // ── Activity log ──
              if (completed.isNotEmpty) ...[
                _buildActivityLog(completed),
                const SizedBox(height: 16),
              ],

              // ── Risk summary ──
              _buildRiskSummary(gameState),
              const SizedBox(height: 28),

              // ── Back button ──
              FarmTheme.primaryButton(
                text: 'Back to Farm',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Completion ring ──────────────────────────────────────────
  Widget _buildCompletionRing(double rate, int done, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: FarmTheme.card,
      child: Column(children: [
        FarmTheme.sectionHeader('ACTIVITY COMPLETION'),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: rate,
                strokeWidth: 9,
                backgroundColor: FarmTheme.border,
                valueColor: const AlwaysStoppedAnimation(FarmTheme.accent),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${(rate * 100).toInt()}%',
                  style: const TextStyle(
                      color: FarmTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Text('done', style: FarmTheme.caption),
              ]),
            ]),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$done out of $total tasks managed',
                    style: FarmTheme.body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rate >= 0.8
                        ? 'Excellent task management this cycle!'
                        : rate >= 0.5
                            ? 'Good effort — room to improve.'
                            : 'Many tasks remained incomplete.',
                    style: FarmTheme.caption,
                  ),
                ]),
          ),
        ]),
      ]),
    );
  }

  // ─── Score cards ──────────────────────────────────────────────
  Widget _buildScoreCards(GameState gs) {
    final scores = [
      ('Land Prep',     gs.landPrepScore,          FarmTheme.accent),
      ('Crop Select',   gs.cropSelectionScore,     FarmTheme.accentBlue),
      ('Timing',        gs.plantingTimeScore,      FarmTheme.accentWarm),
      ('Inputs',        gs.inputManagementScore,   FarmTheme.accentRed),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: scores.map((s) {
        final pct = (s.$2 / 5.0).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (s.$3).withOpacity(0.06),
            borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
            border: Border.all(color: (s.$3).withOpacity(0.18)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1,
                    style: FarmTheme.label.copyWith(color: s.$3, fontSize: 9)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    '${s.$2.toStringAsFixed(1)}/5',
                    style: TextStyle(
                        color: s.$3,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: FarmTheme.caption.copyWith(fontSize: 10),
                  ),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: FarmTheme.border,
                    valueColor: AlwaysStoppedAnimation(s.$3),
                    minHeight: 4,
                  ),
                ),
              ]),
        );
      }).toList(),
    );
  }

  // ─── Yield banner ─────────────────────────────────────────────
  Widget _buildYieldBanner(String tons, GameState gs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FarmTheme.accentWarm.withOpacity(0.12),
            FarmTheme.accentWarm.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
        border: Border.all(color: FarmTheme.accentWarm.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ESTIMATED YIELD',
                style: FarmTheme.label.copyWith(color: FarmTheme.accentWarm)),
            const SizedBox(height: 6),
            Text(
              '$tons Tons',
              style: const TextStyle(
                  color: FarmTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${gs.selectedCrop?.name ?? "–"}  ·  ${gs.landSize.toStringAsFixed(1)} ha',
              style: FarmTheme.caption,
            ),
          ]),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FarmTheme.accentWarm.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up,
                color: FarmTheme.accentWarm, size: 28),
          ),
        ],
      ),
    );
  }

  // ─── Activity log ─────────────────────────────────────────────
  Widget _buildActivityLog(List<Map<String, dynamic>> completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FarmTheme.sectionHeader('COMPLETED ACTIVITIES'),
        const SizedBox(height: 12),
        Container(
          decoration: FarmTheme.card,
          child: Column(
            children: completed.take(6).toList().asMap().entries.map((e) {
              final isLast = e.key == (completed.length > 6 ? 5 : completed.length - 1);
              final a = e.value;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: FarmTheme.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: FarmTheme.accent, size: 12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(a['title'], style: FarmTheme.body.copyWith(fontSize: 13))),
                    Text(
                      'Day ${a['day']}',
                      style: FarmTheme.caption.copyWith(fontSize: 10),
                    ),
                  ]),
                ),
                if (!isLast)
                  Container(height: 1, color: FarmTheme.border),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Risk summary ─────────────────────────────────────────────
  Widget _buildRiskSummary(GameState gs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FarmTheme.sectionHeader('END-OF-CYCLE RISKS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: FarmTheme.card,
          child: Column(children: [
            _riskRow('Pest Risk',    gs.pestRisk,     FarmTheme.accentRed),
            const SizedBox(height: 10),
            _riskRow('Fungal Risk',  gs.diseaseRisk,  FarmTheme.accentWarm),
            const SizedBox(height: 10),
            _riskRow('Weed Pressure', gs.weedPressure, FarmTheme.accent),
          ]),
        ),
      ],
    );
  }

  Widget _riskRow(String label, double value, Color color) {
    return Row(children: [
      SizedBox(
        width: 100,
        child: Text(label, style: FarmTheme.caption.copyWith(fontSize: 11)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: FarmTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '${(value * 100).toInt()}%',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    ]);
  }
}
