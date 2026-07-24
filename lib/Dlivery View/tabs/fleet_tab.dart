import 'package:flutter/material.dart';

class FleetTab extends StatelessWidget {
  const FleetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildVehicleCard(),
              const SizedBox(height: 32),
              const Text(
                "ASSET VAULT",
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildDocumentRow("Vehicle Insurance", "Valid through Dec 2024", Icons.verified_user_outlined, Colors.green),
              const SizedBox(height: 12),
              _buildDocumentRow("Delivery Permit", "Needs Renewal in 22 days", Icons.description_outlined, Colors.orange),
              const SizedBox(height: 12),
              _buildDocumentRow("Maintenance Log", "Last service 2 weeks ago", Icons.build_circle_outlined, Colors.blue),
              const SizedBox(height: 32),
              _buildStatsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FLEET", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Text("Vehicle Details", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E3A34))),
      ],
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A34),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A34).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.local_shipping_rounded, color: Color(0xFF00FF88), size: 64),
          const SizedBox(height: 20),
          const Text("Isuzu FSR-33", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Plate: AA-3-42910", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _specItem("PAYLOAD", "8.5 TONS"),
              _specItem("RANGE", "450 KM"),
              _specItem("STATUS", "EXCELLENT"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDocumentRow(String title, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
                Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _usageRow("Fuel Efficiency", "8.2 km/L", 0.75),
          const SizedBox(height: 20),
          _usageRow("Vehicle Health", "94%", 0.94),
        ],
      ),
    );
  }

  Widget _usageRow(String label, String val, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)),
            Text(val, style: const TextStyle(color: Color(0xFF1E3A34), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D5A42)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
