import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Game/models/game_state.dart';
import 'package:linkedfarm/Services/weather_service.dart';

class FarmingPulseTab extends StatelessWidget {
  const FarmingPulseTab({super.key});

  @override
  Widget build(BuildContext context) {
    // We try to get game state if it exists, otherwise we'll show localized weather
    final gameState = Provider.of<GameState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPredictiveCard(context, gameState, l10n),
          const SizedBox(height: 25),
          Text(l10n.weatherOutlook, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildWeatherForecast(),
          const SizedBox(height: 25),
          Text(l10n.soilVitality, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildSoilStats(gameState, l10n),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildPredictiveCard(BuildContext context, GameState state, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Text(l10n.predictiveAiTitle, style: TextStyle(color: Colors.blue[100], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.expectedYield,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yieldAvg,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 15),
          Text(
            "Based on your soil pH (v${state.selectedSoil?.phLevel ?? 6.5}) and the upcoming 10-day precipitation window, we recommend starting land preparation for ${state.selectedCrop?.name ?? 'your next crop'} in 3 days.",
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherForecast() {
    // Current simulation of forecast
    return FutureBuilder<List<WeatherData>>(
      future: WeatherService.fetch5DayForecast(9.02, 38.75), // Default to Addis Ababa for demo
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final list = snapshot.data!;
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final w = list[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Day ${index + 1}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Icon(_getWeatherIcon(w.condition), color: Colors.blue, size: 24),
                    const SizedBox(height: 8),
                    Text("${w.temp.toStringAsFixed(0)}°C", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSoilStats(GameState state, AppLocalizations l10n) {
    return Row(
      children: [
        _buildStatBox(l10n.pHLevel, state.selectedSoil?.phLevel.toString() ?? "6.5", Icons.science, Colors.purple),
        const SizedBox(width: 12),
        _buildStatBox(l10n.moisture, "${(state.soilMoisture * 100).toInt()}%", Icons.water_drop, Colors.blue),
        const SizedBox(width: 12),
        _buildStatBox(l10n.nitrogen, "Good", Icons.grass, Colors.green),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.contains("Rain")) return Icons.umbrella;
    if (condition.contains("Cloud")) return Icons.cloud;
    return Icons.wb_sunny;
  }
}
