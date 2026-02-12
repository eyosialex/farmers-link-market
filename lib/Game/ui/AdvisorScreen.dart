import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.smartAdvisory),
          centerTitle: true,
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            const SizedBox(width: 8),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: l10n.aiAgronomist),
              Tab(text: l10n.expertPanel),
            ],
          ),
        ),
        backgroundColor: Colors.green[50], // Premium background tone
        body: const TabBarView(
          children: [
            AiAdvisorTab(),
            ExpertAdvisorTab(),
          ],
        ),
      ),
    );
  }
}

class AiAdvisorTab extends StatelessWidget {
  const AiAdvisorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final l10n = AppLocalizations.of(context)!;
    final lastLog = gameState.dailyLogs.isNotEmpty ? gameState.dailyLogs.last : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Section: Crop Analysis
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                if (lastLog?.photoUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: getImageFromFile(lastLog!.photoUrl!),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.green[800],
                    child: const Icon(Icons.image_not_supported, size: 60, color: Colors.white54),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        l10n.cropHealthAnalysis,
                        style: TextStyle(color: Colors.green[100], fontSize: 14, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gameState.healthScore > 0.8 ? l10n.excellentCondition : l10n.attentionNeeded,
                        style: TextStyle(
                          color: gameState.healthScore > 0.8 ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.cropHealthSummary(
                          gameState.selectedCrop?.name ?? l10n.crop,
                          gameState.healthScore > 0.8 ? l10n.optimally : l10n.slowerThanExpected
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          Text(l10n.aiRecommendations, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
          const SizedBox(height: 15),

          // 2. Dynamic Advice Cards
          _buildAdviceCard(
            context, 
            icon: Icons.water_drop, 
            title: l10n.irrigation, 
            advice: gameState.soilMoisture < 0.4 
                ? l10n.moistureLow((gameState.soilMoisture * 100).toInt())
                : l10n.moistureOptimal,
            isCritical: gameState.soilMoisture < 0.4,
          ),
          _buildAdviceCard(
            context,
            icon: Icons.science,
            title: l10n.nutrients,
            advice: gameState.soilNutrients < 0.3
                ? l10n.nutrientsLow
                : l10n.nutrientsStable,
            isCritical: gameState.soilNutrients < 0.3,
          ),
          _buildAdviceCard(
            context,
            icon: Icons.pest_control,
            title: l10n.pestDisease,
            advice: gameState.pestRisk > 0.3
                ? l10n.pestHighRisk
                : l10n.pestLowRisk,
            isCritical: gameState.pestRisk > 0.3,
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(BuildContext context, {required IconData icon, required String title, required String advice, bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCritical ? Colors.redAccent.withOpacity(0.5) : Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red[50] : Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isCritical ? Colors.red : Colors.orange[700], size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isCritical) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.urgent, 
                              style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(advice, style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpertAdvisorTab extends StatelessWidget {
  const ExpertAdvisorTab({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
         Text(l10n.connectWithExperts, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
         const SizedBox(height: 4),
         Text(l10n.getProfessionalGuidance, style: const TextStyle(color: Colors.grey)),
         const SizedBox(height: 20),
         
         _buildExpertProfile(
            context,
            name: "Dr. Almaz Kebede",
            role: "Senior Agronomist",
            specialty: "Crop Disease Specialist",
            rating: 4.9,
            status: l10n.online,
            color: Colors.green,
          ),
          _buildExpertProfile(
            context,
            name: "Samuel Tadesse",
            role: "Soil Scientist",
            specialty: "Fertilizer Management",
            rating: 4.7,
            status: l10n.away,
            color: Colors.orange,
          ),
          _buildExpertProfile(
            context,
            name: "Sarah Bekele",
            role: "Extension Worker",
            specialty: "Sustainable Farming",
            rating: 4.8,
            status: l10n.online,
            color: Colors.green,
          ),
      ],
    );
  }

  Widget _buildExpertProfile(BuildContext context, {required String name, required String role, required String specialty, required double rating, required String status, required Color color}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                child: Text(name[0], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == l10n.online ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status == l10n.online ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: status == l10n.online ? Colors.green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: status == l10n.online ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Chip(label: Text(specialty), backgroundColor: Colors.grey[100], side: BorderSide.none),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.green[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.requestConsultation, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
