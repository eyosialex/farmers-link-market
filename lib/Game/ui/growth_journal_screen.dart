import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'farm_theme.dart';

class GrowthJournalScreen extends StatelessWidget {
  const GrowthJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final history   = gameState.history;

    return Scaffold(
      backgroundColor: FarmTheme.bg,
      appBar: FarmTheme.appBar(context, 'GROWTH JOURNAL'),
      body: Container(
        decoration: const BoxDecoration(gradient: FarmTheme.bgGradient),
        child: history.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  // Latest days first
                  final reversed = history.length - 1 - index;
                  return _buildDayCard(history[reversed]);
                },
              ),
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.menu_book_outlined, size: 52, color: FarmTheme.border),
        const SizedBox(height: 14),
        Text('No journal entries yet.',
            style: FarmTheme.headingMd.copyWith(color: FarmTheme.textMuted)),
        const SizedBox(height: 6),
        Text('Advance days in the simulation to build your history.',
            style: FarmTheme.caption, textAlign: TextAlign.center),
      ]),
    );
  }

  // ─── Day card ────────────────────────────────────────────────
  Widget _buildDayCard(Map<String, dynamic> data) {
    final int    day       = data['day'];
    final double growth    = (data['growth'] as num).toDouble();
    final double moisture  = (data['moisture'] as num).toDouble();
    final double nutrients = (data['nutrients'] as num).toDouble();
    final double health    = (data['health'] as num).toDouble();
    final String weather   = data['weather'] ?? 'Sunny';
    final double pestRisk  = ((data['pestRisk'] ?? 0.0) as num).toDouble();

    final isRainy  = weather == 'Rainy';
    final healthColor = health > 0.7
        ? FarmTheme.accent
        : (health > 0.4 ? FarmTheme.accentWarm : FarmTheme.accentRed);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: FarmTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FarmTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: FarmTheme.accent.withOpacity(0.25)),
                ),
                child: Text(
                  'DAY $day',
                  style: const TextStyle(
                      color: FarmTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
              const Spacer(),
              // Weather badge
              Row(children: [
                Icon(
                  isRainy ? Icons.grain : Icons.wb_sunny_rounded,
                  color: isRainy ? FarmTheme.accentBlue : FarmTheme.accentWarm,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  weather,
                  style: FarmTheme.caption.copyWith(
                      color: isRainy ? FarmTheme.accentBlue : FarmTheme.accentWarm),
                ),
              ]),
              const SizedBox(width: 12),
              // Growth reached
              Text(
                '${growth.toStringAsFixed(1)}% growth',
                style: FarmTheme.caption,
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 1, color: FarmTheme.border),
          ),
          const SizedBox(height: 12),

          // ── Stat bars ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _statBar('Moisture',  moisture,  FarmTheme.accentBlue),
              const SizedBox(height: 8),
              _statBar('Nutrients', nutrients, FarmTheme.accent),
              const SizedBox(height: 8),
              _statBar('Health',    health,    healthColor),
            ]),
          ),

          // ── Pest risk chip (only if elevated) ──
          if (pestRisk > 0.3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                const Icon(Icons.pest_control, color: FarmTheme.accentRed, size: 13),
                const SizedBox(width: 5),
                Text(
                  'Pest risk: ${(pestRisk * 100).toInt()}%',
                  style: const TextStyle(
                      color: FarmTheme.accentRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _statBar(String label, double value, Color color) {
    final pct = value.clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(label, style: FarmTheme.caption.copyWith(fontSize: 11)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: FarmTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '${(pct * 100).toInt()}%',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    ]);
  }
}
