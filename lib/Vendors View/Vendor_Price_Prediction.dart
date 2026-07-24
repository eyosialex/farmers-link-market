import 'package:flutter/material.dart';
import 'dart:math';
import 'package:linkedfarm/Services/gemini_service.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'dart:ui' as ui;

class VendorPricePredictionScreen extends StatefulWidget {
  const VendorPricePredictionScreen({super.key});

  @override
  State<VendorPricePredictionScreen> createState() => _VendorPricePredictionScreenState();
}

class _VendorPricePredictionScreenState extends State<VendorPricePredictionScreen> {
  String _aiAdvice = "Analyzing market trends...";
  bool _isLoading = true;
  String _selectedCrop = "Wheat";

  final Map<String, List<double>> _marketData = {
    "Wheat": [6200, 6500, 6800, 7000, 7200, 7500, 7800],
    "Maize": [4500, 4300, 4600, 4800, 5000, 5200, 5100],
    "Coffee": [12000, 12500, 11800, 13000, 13500, 14000, 14500],
    "Teff": [8000, 8200, 8500, 8800, 9000, 9500, 9800],
  };

  @override
  void initState() {
    super.initState();
    _fetchAIAnalysis();
  }

  Future<void> _fetchAIAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final prompt = "Act as an agricultural economist. Given current price of $_selectedCrop is ${_marketData[_selectedCrop]!.last} Birr/quintal and it has been rising steadily for 6 weeks, predict next week's price and give inventory advice for a vendor.";
      final response = await GeminiService.getChatResponse(prompt);
      setState(() {
        _aiAdvice = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiAdvice = "Unable to fetch AI prediction at this time.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      appBar: AppBar(
        title: const Text("MARKET TRENDS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCropSelector(),
            const SizedBox(height: 30),
            _buildPriceGraph(),
            const SizedBox(height: 30),
            _buildPredictionStats(),
            const SizedBox(height: 30),
            _buildAIAdviceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _marketData.keys.map((crop) {
          final isSelected = _selectedCrop == crop;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(crop.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCrop = crop);
                  _fetchAIAnalysis();
                }
              },
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: Colors.green[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceGraph() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("WEEKLY TREND", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${_marketData[_selectedCrop]!.last} Birr", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: PriceChartPainter(data: _marketData[_selectedCrop]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionStats() {
    final lastPrice = _marketData[_selectedCrop]!.last;
    final predictedPrice = lastPrice * 1.12; // Example logic

    return Row(
      children: [
        Expanded(
          child: _buildStatCard("CURRENT", "$lastPrice", Colors.greenAccent),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard("PREDICTED", "${predictedPrice.toInt()}", Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Birr/Q", style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAIAdviceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!.withOpacity(0.1), Colors.orange[700]!.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.orange[400]),
              const SizedBox(width: 12),
              const Text("AI MARKET ADVISOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _aiAdvice,
            style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class PriceChartPainter extends CustomPainter {
  final List<double> data;
  PriceChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [Colors.greenAccent.withOpacity(0.3), Colors.transparent],
      );

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce(max);
    final double minVal = data.reduce(min);
    final double range = (maxVal - minVal).clamp(1, double.infinity);

    double getY(double val) => size.height - ((val - minVal) / range * size.height * 0.8) - (size.height * 0.1);

    path.moveTo(0, getY(data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      final x1 = (i - 1) * stepX;
      final y1 = getY(data[i - 1]);
      final x2 = i * stepX;
      final y2 = getY(data[i]);

      path.cubicTo(
        x1 + stepX / 2, y1,
        x1 + stepX / 2, y2,
        x2, y2,
      );
      
      fillPath.cubicTo(
        x1 + stepX / 2, y1,
        x1 + stepX / 2, y2,
        x2, y2,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < data.length; i++) {
      canvas.drawCircle(Offset(i * stepX, getY(data[i])), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
