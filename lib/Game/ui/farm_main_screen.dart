import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Services/gemini_service.dart';
import '../../Services/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../models/game_state.dart';
import 'AdvisorScreen.dart';
import 'DailyTrackerScreen.dart';
import 'PlannerScreen.dart';
import 'farm_theme.dart';
import 'farming_report_screen.dart';
import 'growth_journal_screen.dart';
import 'yield_results_screen.dart';

class FarmMainScreen extends StatelessWidget {
  const FarmMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    // Navigate to results when game ends
    if (gameState.isGameOver) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const YieldResultsScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      body: Stack(
        children: [
          // ── Background gradient
          Container(
            decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
          ),

          // ── Rain overlay
          if (gameState.currentWeather == 'Rainy') _buildRainOverlay(),

          // ── Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, gameState),
                _buildRiskRow(context, gameState),
                Expanded(child: _buildFieldArea(context, gameState)),
                _buildMoistureBar(context, gameState),
                _buildBottomDock(context, gameState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TOP BAR — Weather + Day + Energy
  // ═══════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context)!;
    final isRainy = gameState.currentWeather == 'Rainy';

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: FarmTheme.surface.withOpacity(0.7),
            border: const Border(bottom: BorderSide(color: FarmTheme.border)),
          ),
          child: Row(
            children: [
              // Weather icon + info
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (isRainy ? FarmTheme.accentBlue : FarmTheme.accentWarm)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                ),
                child: Icon(
                  isRainy ? Icons.grain : Icons.wb_sunny_rounded,
                  color: isRainy ? FarmTheme.accentBlue : FarmTheme.accentWarm,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${gameState.currentTemp.toStringAsFixed(1)}°C',
                    style: FarmTheme.headingMd,
                  ),
                  Text(
                    isRainy ? l10n.predictedRain : l10n.clearSkies,
                    style: FarmTheme.caption,
                  ),
                ],
              ),
              const Spacer(),
              // Day pill
              _pill(
                l10n.dayLabel(gameState.currentDay),
                FarmTheme.accent,
                Icons.calendar_today,
              ),
              const SizedBox(width: 8),
              // Energy pill
              _pill(
                '${gameState.energy.toInt()}%',
                FarmTheme.accentWarm,
                Icons.flash_on_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  //  RISK ROW — Pest / Disease / Weeds
  // ═══════════════════════════════════════════════════
  Widget _buildRiskRow(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: FarmTheme.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _riskGauge(l10n.pest,   gameState.pestRisk,    FarmTheme.accentRed),
          _verticalDivider(),
          _riskGauge(l10n.fungal, gameState.diseaseRisk, FarmTheme.accentWarm),
          _verticalDivider(),
          _riskGauge(l10n.weeds,  gameState.weedPressure, FarmTheme.accent),
        ],
      ),
    );
  }

  Widget _riskGauge(String label, double value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: FarmTheme.label),
        const SizedBox(height: 8),
        SizedBox(
          width: 42,
          height: 42,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: FarmTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Text(
              '${(value * 100).toInt()}',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Text('%', style: FarmTheme.caption),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 48,
      color: FarmTheme.border,
    );
  }

  // ═══════════════════════════════════════════════════
  //  FIELD AREA — Isometric field + growth stage banner
  // ═══════════════════════════════════════════════════
  Widget _buildFieldArea(BuildContext context, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Growth stage label
        _growthStageBanner(gameState),
        const SizedBox(height: 16),
        // Isometric field
        _buildIsometricField(gameState),
      ],
    );
  }

  Widget _growthStageBanner(GameState gameState) {
    final stages = ['Seedling', 'Vegetative', 'Flowering', 'Mature'];
    final stage = (gameState.visualStage - 1).clamp(0, 3).toInt();
    final stageColors = [FarmTheme.accentBlue, FarmTheme.accent, FarmTheme.accentWarm, FarmTheme.accentRed];
    final color = stageColors[stage];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(gameState.plantIcon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          stages[stage].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${gameState.growthProgress.toInt()}%',
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
        ),
      ]),
    );
  }

  Widget _buildIsometricField(GameState gameState) {
    final soilColor = Color.lerp(
      const Color(0xFF2D1B07),
      const Color(0xFF1A3A1A),
      gameState.soilMoisture.clamp(0.0, 1.0),
    );

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.45)
        ..rotateZ(0.08),
      alignment: FractionalOffset.center,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: soilColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FarmTheme.accent.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: FarmTheme.accent.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(18, 18),
            ),
          ],
        ),
        child: GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(18),
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(16, (index) {
            final growth = gameState.growthProgress / 100.0;
            return Center(
              child: AnimatedScale(
                scale: 0.15 + (0.85 * growth),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                child: Icon(
                  gameState.plantIcon,
                  size: 36,
                  color: gameState.plantColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SOIL MOISTURE BAR
  // ═══════════════════════════════════════════════════
  Widget _buildMoistureBar(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context)!;
    final pct = gameState.soilMoisture.clamp(0.0, 1.0);
    final color = pct < 0.3
        ? FarmTheme.accentRed
        : (pct < 0.6 ? FarmTheme.accentWarm : FarmTheme.accent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.water_drop_outlined, color: color, size: 14),
                const SizedBox(width: 6),
                Text(l10n.soilMoistureProfile, style: FarmTheme.label),
              ]),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: FarmTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  BOTTOM DOCK
  // ═══════════════════════════════════════════════════
  Widget _buildBottomDock(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: FarmTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(FarmTheme.radiusXl)),
        border: const Border(top: BorderSide(color: FarmTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: FarmTheme.border,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 16),

          // ── Dock header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    l10n.dayLabel(gameState.currentDay),
                    style: FarmTheme.headingLg,
                  ),
                  Text(
                    l10n.vegetativeCycle,
                    style: FarmTheme.caption.copyWith(
                        color: FarmTheme.accent, fontWeight: FontWeight.bold),
                  ),
                ]),
                Row(children: [
                  _iconBtn(
                    icon: Icons.bar_chart_rounded,
                    color: FarmTheme.accentWarm,
                    tooltip: 'Farming Report',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FarmingReportScreen())),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(
                    icon: Icons.map_outlined,
                    color: FarmTheme.accent,
                    tooltip: 'Seasonal Roadmap',
                    onTap: () => _showSeasonalRoadmap(context, gameState),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── AI Advisor banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAIBanner(context, gameState, l10n),
          ),
          const SizedBox(height: 16),

          // ── Tool buttons ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _toolBtn(
                    context,
                    label: l10n.dailyLogBtn,
                    icon: Icons.camera_alt_outlined,
                    color: FarmTheme.accent,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DailyTrackerScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _toolBtn(
                    context,
                    label: l10n.plannerBtn,
                    icon: Icons.calendar_month_outlined,
                    color: FarmTheme.accentWarm,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PlannerScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _toolBtn(
                    context,
                    label: l10n.advisorBtn,
                    icon: Icons.psychology_outlined,
                    color: FarmTheme.accentBlue,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdvisorScreen())),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(children: [
              // Fertilize
              _actionBtn(
                label: l10n.fertilizeBtn,
                icon: Icons.science_outlined,
                color: FarmTheme.accentWarm,
                onTap: gameState.fertilize,
              ),
              const SizedBox(width: 12),
              // Next Day (primary)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: gameState.nextDay,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    l10n.proceedNextDay,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmTheme.accent,
                    foregroundColor: FarmTheme.bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── AI Advisor banner ──
  Widget _buildAIBanner(BuildContext context, GameState gameState, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showGeminiAnalysis(context, gameState),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FarmTheme.accentWarm.withOpacity(0.12),
              FarmTheme.accentWarm.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          border: Border.all(color: FarmTheme.accentWarm.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              color: FarmTheme.accentWarm, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedAdvice(context, gameState),
                  style: FarmTheme.body.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.tapDeepAnalysis,
                  style: const TextStyle(
                    color: FarmTheme.accentWarm,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: FarmTheme.accentWarm, size: 18),
        ]),
      ),
    );
  }

  // ── Small icon button ──
  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  // ── Tool button ──
  Widget _toolBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FarmTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Secondary action button ──
  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  RAIN OVERLAY
  // ═══════════════════════════════════════════════════
  Widget _buildRainOverlay() {
    final random = Random();
    return IgnorePointer(
      child: Stack(
        children: List.generate(25, (_) {
          return Positioned(
            top: random.nextDouble() * 900,
            left: random.nextDouble() * 450,
            child: Container(
              width: 1.5,
              height: random.nextDouble() * 20 + 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FarmTheme.accentBlue.withOpacity(0.0),
                    FarmTheme.accentBlue.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  AI ANALYSIS DIALOG
  // ═══════════════════════════════════════════════════
  void _showGeminiAnalysis(BuildContext context, GameState gameState) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: FarmTheme.accentWarm),
      ),
    );

    final advice = await GeminiService.getFarmingAdvice(
      soilType: gameState.selectedSoil?.name ?? 'Unknown',
      cropName: gameState.selectedCrop?.name ?? 'Unknown',
      day: gameState.currentDay,
      moisture: gameState.soilMoisture,
      nutrients: gameState.soilNutrients,
      health: gameState.healthScore,
    );

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: FarmTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FarmTheme.radiusLg),
            side: const BorderSide(color: FarmTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FarmTheme.accentWarm.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(FarmTheme.radiusSm),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: FarmTheme.accentWarm, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.aiDeepAnalysisTitle, style: FarmTheme.headingMd),
                  ),
                ]),
                const SizedBox(height: 6),
                Container(height: 1, color: FarmTheme.border),
                const SizedBox(height: 16),
                Text(advice, style: FarmTheme.body),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FarmTheme.accent,
                      foregroundColor: FarmTheme.bg,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FarmTheme.radiusMd)),
                      elevation: 0,
                    ),
                    child: Text(l10n.gotIt,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════
  //  SEASONAL ROADMAP BOTTOM SHEET
  // ═══════════════════════════════════════════════════
  void _showSeasonalRoadmap(BuildContext context, GameState gameState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FarmTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(FarmTheme.radiusXl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          final l10n = AppLocalizations.of(context)!;
          return Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Column(children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: FarmTheme.border,
                            borderRadius: BorderRadius.circular(4))),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l10n.myCustomLandPlan, style: FarmTheme.headingMd),
                        Text(l10n.plannerDetail, style: FarmTheme.caption),
                      ]),
                      IconButton(
                        onPressed: () =>
                            _showAddActivityDialog(context, gameState),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: FarmTheme.accent.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(FarmTheme.radiusSm),
                            border: Border.all(
                                color: FarmTheme.accent.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.add,
                              color: FarmTheme.accent, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: FarmTheme.border),
                ]),
              ),

              // Activity list
              Expanded(
                child: gameState.customActivities.isEmpty
                    ? _buildEmptyPlanner(context)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: gameState.customActivities.length,
                        itemBuilder: (_, i) => _buildActivityCard(
                            context, gameState, gameState.customActivities[i], i),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    GameState gameState,
    Map<String, dynamic> activity,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final type = activity['type'] as String;
    final isDone = activity['isCompleted'] ?? false;
    final typeColor = type == 'daily'
        ? FarmTheme.accent
        : (type == 'weekly' ? FarmTheme.accentWarm : FarmTheme.accentBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: isDone
          ? FarmTheme.card
          : BoxDecoration(
              gradient: FarmTheme.cardGradient,
              borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
              border: Border.all(color: typeColor.withOpacity(0.25)),
            ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Type badge
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: typeColor.withOpacity(0.2)),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                      color: typeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
              if (isDone) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: FarmTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    l10n.completed,
                    style: const TextStyle(
                        color: FarmTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ]),
            // Controls
            Row(children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: isDone,
                  activeColor: FarmTheme.accent,
                  checkColor: FarmTheme.bg,
                  side: const BorderSide(color: FarmTheme.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  onChanged: (_) =>
                      gameState.toggleActivityCompletion(index),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: FarmTheme.accentRed),
                onPressed: () =>
                    gameState.removeCustomActivity(index),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          activity['title'],
          style: FarmTheme.headingMd.copyWith(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? FarmTheme.textMuted : FarmTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activity['description'],
          style: FarmTheme.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.dayLabel(activity['day']),
          style: FarmTheme.caption.copyWith(fontSize: 10),
        ),
      ]),
    );
  }

  Widget _buildEmptyPlanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.edit_note_rounded, size: 52, color: FarmTheme.border),
        const SizedBox(height: 14),
        Text(l10n.emptyPlanner, style: FarmTheme.headingMd.copyWith(color: FarmTheme.textMuted)),
        const SizedBox(height: 6),
        Text(l10n.emptyPlannerDetail, style: FarmTheme.caption, textAlign: TextAlign.center),
      ]),
    );
  }

  void _showAddActivityDialog(BuildContext context, GameState gameState) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'daily';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          return Dialog(
            backgroundColor: FarmTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FarmTheme.radiusLg),
              side: const BorderSide(color: FarmTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.entryManualPlanTitle, style: FarmTheme.headingMd),
                const SizedBox(height: 20),

                // Type dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: FarmTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
                    border: Border.all(color: FarmTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: FarmTheme.surfaceAlt,
                      value: selectedType,
                      style: FarmTheme.body,
                      items: ['daily', 'weekly', 'monthly'].map((t) {
                        final label = t == 'daily'
                            ? l10n.daily
                            : (t == 'weekly' ? l10n.weekly : l10n.monthly);
                        return DropdownMenuItem(
                            value: t, child: Text(label));
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedType = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _dialogField(l10n.taskTitle, titleCtrl),
                const SizedBox(height: 12),
                _dialogField(l10n.activityDetail, descCtrl),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: FarmTheme.ghostButton(
                      text: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isEmpty) return;
                        gameState.addCustomActivity(
                            selectedType, titleCtrl.text, descCtrl.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FarmTheme.accent,
                        foregroundColor: FarmTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(FarmTheme.radiusMd)),
                        elevation: 0,
                      ),
                      child: Text(l10n.savePlan,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: FarmTheme.body,
      cursorColor: FarmTheme.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FarmTheme.textMuted, fontSize: 13),
        filled: true,
        fillColor: FarmTheme.surfaceAlt,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide: const BorderSide(color: FarmTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FarmTheme.radiusMd),
          borderSide: const BorderSide(color: FarmTheme.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  AI ADVICE HELPERS
  // ═══════════════════════════════════════════════════
  String _getLocalizedAdvice(BuildContext context, GameState gameState) {
    final l10n = AppLocalizations.of(context)!;
    final key = _getAdviceKey(gameState);
    switch (key) {
      case 'advicePest':
        return l10n.advicePest;
      case 'adviceMoistureLow':
        return l10n.adviceMoistureLow;
      case 'adviceRainy':
        return l10n.adviceRainy;
      default:
        return l10n.adviceStable;
    }
  }

  String _getAdviceKey(GameState gameState) {
    if (gameState.pestRisk > 0.4) return 'advicePest';
    if (gameState.soilMoisture < 0.4) return 'adviceMoistureLow';
    if (gameState.currentWeather == 'Rainy') return 'adviceRainy';
    return 'adviceStable';
  }
}
