import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'farm_main_screen.dart';
import 'farm_main_screen.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key});

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _tractorController;
  bool isPlowing = false;

  @override
  void initState() {
    super.initState();
    _tractorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _tractorController.dispose();
    super.dispose();
  }

  void _runTractor(VoidCallback onComplete) {
    setState(() => isPlowing = true);
    _tractorController.forward(from: 0).then((_) {
      onComplete();
      setState(() => isPlowing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prepare Your Land"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          const SizedBox(width: 8),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStats(gameState),
          const SizedBox(height: 20),
          Expanded(child: _buildFieldView(gameState)),
          _buildControls(gameState),
        ],
      ),
    );
  }

  Widget _buildStats(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.brown[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statIcon(Icons.flash_on, "Energy", "${gameState.energy.toInt()}%", Colors.orange),
          _statIcon(Icons.check_circle, "Readiness", "${(gameState.soilReadiness * 100).toInt()}%", Colors.green),
        ],
      ),
    );
  }

  Widget _statIcon(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildFieldView(GameState gameState) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.brown[200], Colors.brown[800], gameState.soilReadiness),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: FieldGridPainter(progress: gameState.soilReadiness),
            ),
          ),
          
          // Tractor Animation
          if (isPlowing)
            AnimatedBuilder(
              animation: _tractorController,
              builder: (context, child) {
                return Positioned(
                  left: 20 + (MediaQuery.of(context).size.width - 100) * _tractorController.value,
                  top: 50,
                  child: const Icon(Icons.agriculture, size: 40, color: Colors.red),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControls(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Required Readiness: 100%", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionCard(
                "Plow", 
                Icons.line_weight, 
                "Cost: 10 Energy", 
                () => _runTractor(gameState.plow)
              ),
              _actionCard(
                "Level", 
                Icons.horizontal_rule, 
                "Cost: 10 Energy", 
                () => _runTractor(gameState.levelSoil)
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: gameState.soilReadiness >= 0.9 
              ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FarmMainScreen()))
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("START PLANTING"),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: isPlowing ? null : onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.brown),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class FieldGridPainter extends CustomPainter {
  final double progress;
  FieldGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
