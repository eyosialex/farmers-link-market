import 'package:flutter/material.dart';
import 'package:linkedfarm/Services/farm_persistence_service.dart';
import 'package:linkedfarm/User Credential/usermodel.dart';

class TrustedFarmersScreen extends StatefulWidget {
  const TrustedFarmersScreen({super.key});

  @override
  State<TrustedFarmersScreen> createState() => _TrustedFarmersScreenState();
}

class _TrustedFarmersScreenState extends State<TrustedFarmersScreen> {
  final FarmPersistenceService _persistence = FarmPersistenceService();
  String _selectedCrop = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("TRUSTED FARMERS", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildCropFilter(),
          Expanded(child: _buildFarmersList()),
        ],
      ),
    );
  }

  Widget _buildCropFilter() {
    final crops = ["All", "Wheat", "Coffee", "Maize", "Teff", "Vegetables"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: crops.map((crop) {
          final isSelected = _selectedCrop == crop;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(crop),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCrop = crop),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: Colors.green[700],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFarmersList() {
    return FutureBuilder<List<UserModel>>(
      future: _persistence.getTrustedFarmers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final farmers = snapshot.data?.where((f) {
           String? farmerCrops;
           if (f is FarmerUser) {
             farmerCrops = f.crops;
           }
           
           if (_selectedCrop == "All") return true;
           return farmerCrops?.toLowerCase().contains(_selectedCrop.toLowerCase()) ?? false;
        }).toList() ?? [];

        if (farmers.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: farmers.length,
          itemBuilder: (context, index) => _buildFarmerCard(farmers[index]),
        );
      },
    );
  }

  Widget _buildFarmerCard(UserModel farmer) {
    String? farmerCrops;
    if (farmer is FarmerUser) {
      farmerCrops = farmer.crops;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: farmer.photoUrl != null ? NetworkImage(farmer.photoUrl!) : null,
            child: farmer.photoUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(farmerCrops ?? "Diversified Farming", style: const TextStyle(color: Colors.grey, fontSize: 12)),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(farmer.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text("(${farmer.ratingCount} reviews)", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {}, // Future: Link to Chat
            icon: Icon(Icons.chat_bubble_outline, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No highly rated farmers found for this crop.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
