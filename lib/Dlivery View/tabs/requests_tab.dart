import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:linkedfarm/Dlivery%20View/osrm_delivery_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  int _selectedFilter = 0; // 0: Available, 1: Active, 2: History

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSegmentedControl(),
            Expanded(
              child: _buildRequestList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("REQUESTS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text("Task Feed", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E3A34))),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.sort_rounded, color: Color(0xFF1E3A34)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            _filterButton("Available", 0),
            _filterButton("Active", 1),
            _filterButton("History", 2),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, int index) {
    bool isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E3A34) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final FirestoreService firestoreService = FirestoreService();

    String status = 'Ready for Pickup';
    if (_selectedFilter == 1) status = 'In Transit';
    if (_selectedFilter == 2) status = 'Delivered';

    Stream<List<OrderModel>> stream;
    if (_selectedFilter == 0) {
      stream = firestoreService.getAvailableDeliveryOrders(currentDriverId: uid);
    } else {
      stream = firestoreService.getOrdersByDriver(uid, status: status);
    }

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error loading orders: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          String title = "No orders ready";
          String sub = "Wait for farmers to mark orders ready for pickup.";
          if (_selectedFilter == 1) {
            title = "No active jobs";
            sub = "Accept a job from the available feed.";
          } else if (_selectedFilter == 2) {
            title = "No history yet";
            sub = "Your completed deliveries will appear here.";
          }
          return _buildEmptyState(title, sub);
        }

        final orders = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _jobItem(
                id: "#${order.id?.substring(0, 4).toUpperCase() ?? 'ORDER'}",
                orderId: order.id ?? '',
                pickup: order.sellerName,
                dropoff: order.dropoffAddress ?? order.vendorName,
                cargo: "${order.productName} (${order.quantity} ${order.productUnit})",
                price: "ETB ${order.totalPrice.toStringAsFixed(0)}",
                distance: "Calculated at pickup",
                time: "ASAP",
                location: order.pickupLocation != null ? LatLng(order.pickupLocation!['lat']!, order.pickupLocation!['lng']!) : null,
                dropoffLocation: order.dropoffLocation != null ? LatLng(order.dropoffLocation!['lat']!, order.dropoffLocation!['lng']!) : null,
                showAcceptButton: _selectedFilter == 0,
                status: order.transactionStatus,
              ),
            );
          },
        );
      },
    );
  }

  Widget _jobItem({
    required String id,
    required String orderId,
    required String pickup,
    required String dropoff,
    required String cargo,
    required String price,
    required String distance,
    required String time,
    LatLng? location, // Pickup
    LatLng? dropoffLocation,
    bool isUrgent = false,
    bool isFragile = false,
    bool showAcceptButton = true,
    String status = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                  child: Text("URGENT", style: TextStyle(color: Colors.orange[900], fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(cargo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _locationIndicator(Icons.location_on, pickup, Colors.green),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            child: Container(width: 1, height: 16, color: Colors.grey[200]),
          ),
          _locationIndicator(Icons.flag_rounded, dropoff, Colors.orange),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _jobStat(Icons.route_outlined, distance),
                _jobStat(Icons.timer_outlined, time),
                Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2D5A42))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OSRDeliveryPage(
                          jobTitle: cargo,
                          farmerName: pickup,
                          initialEnd: location,
                          initialDropoff: dropoffLocation,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("View Map", style: TextStyle(color: Color(0xFF1E3A34), fontWeight: FontWeight.bold)),
                ),
              ),
              if (showAcceptButton) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmAcceptJob(orderId, cargo, pickup, location),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmAcceptJob(String orderId, String cargo, String pickup, LatLng? location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Accept Delivery"),
        content: Text("Are you sure you want to accept the delivery for $cargo? This will assign the order to you."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final firestoreService = FirestoreService();
              final success = await firestoreService.acceptOrderDelivery(orderId, user.uid, user.displayName ?? "Driver");

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Accepted! Check Command tab for details.")));
                // We don't navigate automatically, the stream will update the UI
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A42)),
            child: const Text("Yes, Accept"),
          ),
        ],
      ),
    );
  }

  Widget _locationIndicator(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _jobStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A34))),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: Icon(Icons.check, color: Colors.green[700], size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Completed Delivery #428${9-index}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Oct ${09-index}, 2024", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Text("ETB 1,400", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
