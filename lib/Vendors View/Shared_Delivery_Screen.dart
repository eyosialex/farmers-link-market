import 'package:flutter/material.dart';
import 'package:linkedfarm/Services/farm_persistence_service.dart';
import 'package:linkedfarm/User Credential/usermodel.dart';

class SharedDeliveryScreen extends StatefulWidget {
  const SharedDeliveryScreen({super.key});

  @override
  State<SharedDeliveryScreen> createState() => _SharedDeliveryScreenState();
}

class _SharedDeliveryScreenState extends State<SharedDeliveryScreen> {
  final FarmPersistenceService _persistence = FarmPersistenceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("DELIVERY POOLING", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: _buildNearbyVendorsList(),
    );
  }

  Widget _buildNearbyVendorsList() {
    return FutureBuilder<List<UserModel>>(
      future: _persistence.getNearbyVendors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vendors = snapshot.data ?? [];

        if (vendors.isEmpty) {
          return const Center(child: Text("No nearby vendors found.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: vendors.length,
          itemBuilder: (context, index) => _buildVendorPoolingCard(vendors[index]),
        );
      },
    );
  }

  Widget _buildVendorPoolingCard(UserModel vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!.withOpacity(0.05), Colors.orange[700]!.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.orange[700]),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor is VendorUser ? (vendor as VendorUser).businessName ?? vendor.fullName : vendor.fullName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(vendor is VendorUser ? (vendor as VendorUser).businessAddress ?? "Address not specified" : "Address not specified", 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],

                ),
              ),
              Chip(
                label: Text("POOLING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Potential Saving:", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Text("~40% Cost Reduction", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("PROPOSE POOLING"),
            ),
          ),
        ],
      ),
    );
  }
}
