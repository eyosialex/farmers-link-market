import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'farm_theme.dart';
import 'game_dashboard.dart';

class YieldResultsScreen extends StatefulWidget {
  const YieldResultsScreen({super.key});

  @override
  State<YieldResultsScreen> createState() => _YieldResultsScreenState();
}

class _YieldResultsScreenState extends State<YieldResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String _getAnalysis(double health) {
    if (health > 0.8) {
      return 'Excellent predictive management. Soil moisture and nutrient levels were maintained at optimal thresholds despite weather volatility.';
    } else if (health > 0.5) {
      return 'Moderate success. Some stress factors were detected, likely due to wind conditions or moisture fluctuations. Adjust planting timing next cycle.';
    } else {
      return 'Sub-optimal yield profile. High risk factors (Pest/Fungal) significantly impacted development. Review soil preparation steps.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final health = gameState.healthScore;
    final efficiency = (gameState.landPrepScore / 5.0).clamp(0.5, 1.0);
    final yieldPct = (health * efficiency * 100).toInt();

    final yieldColor = yieldPct >= 75
        ? FarmTheme.accent
        : (yieldPct >= 50 ? FarmTheme.accentWarm : FarmTheme.accentRed);

    final grade = yieldPct >= 80
        ? 'A'
        : (yieldPct >= 65 ? 'B' : (yieldPct >= 50 ? 'C' : 'D'));

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── Header ──
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FarmTheme.accentWarm.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined,
                        color: FarmTheme.accentWarm, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PREDICTIVE ANALYSIS',
                    style: FarmTheme.label.copyWith(letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 6),
                  Text('Simulation Complete', style: FarmTheme.headingLg),
                  const SizedBox(height: 28),

                  // ── Yield score card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: FarmTheme.cardHighlight,
                    child: Column(children: [
                      Text('ESTIMATED HARVEST YIELD',
                          style: FarmTheme.label.copyWith(letterSpacing: 2)),
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Text(
                          '$yieldPct%',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: yieldColor,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: yieldColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: yieldColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          'GRADE  $grade',
                          style: TextStyle(
                            color: yieldColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: FarmTheme.border),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.agriculture,
                              color: FarmTheme.textMuted, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${gameState.selectedCrop?.name ?? "–"}  ·  Plot: ${gameState.currentLandName ?? "Standard"}',
                            style: FarmTheme.caption,
                          ),
                        ],
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Stat summary row ──
                  Row(children: [
                    Expanded(
                        child: _statCard(
                      'Health',
                      '${(health * 100).toInt()}%',
                      Icons.favorite_rounded,
                      FarmTheme.accentRed,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(
                      'Growth',
                      '${gameState.growthProgress.toInt()}%',
                      Icons.trending_up,
                      FarmTheme.accent,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(
                      'Days Run',
                      '${gameState.currentDay}',
                      Icons.calendar_today,
                      FarmTheme.accentWarm,
                    )),
                  ]),

                  const SizedBox(height: 20),

                  // ── AI report card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: FarmTheme.card,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: FarmTheme.accentWarm, size: 16),
                            const SizedBox(width: 8),
                            Text('AI LOCAL REPORT',
                                style: FarmTheme.label
                                    .copyWith(color: FarmTheme.accentWarm)),
                          ]),
                          const SizedBox(height: 12),
                          Text(_getAnalysis(health), style: FarmTheme.body),
                        ]),
                  ),

                  const SizedBox(height: 28),

                  // ── Return button ──
                  FarmTheme.primaryButton(
                    text: 'Finalize & Return to Profile',
                    icon: Icons.home_rounded,
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: FarmTheme.caption.copyWith(fontSize: 10)),
      ]),
    );
  }
}
