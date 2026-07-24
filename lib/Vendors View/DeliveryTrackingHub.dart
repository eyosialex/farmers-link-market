import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Dlivery%20View/delivery_location_tracker.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';

class DeliveryTrackingHub extends StatefulWidget {
  const DeliveryTrackingHub({super.key});

  @override
  State<DeliveryTrackingHub> createState() => _DeliveryTrackingHubState();
}

class _DeliveryTrackingHubState extends State<DeliveryTrackingHub> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("DELIVERY TRACKING",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getOrdersByVendor(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data ?? [];
          // Filter for logic: Only show those needing/in delivery
          final deliveryOrders = allOrders.where((o) =>
              o.transactionStatus == "Ready for Pickup" ||
              o.transactionStatus == "In Transit").toList();

          if (deliveryOrders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: deliveryOrders.length,
            itemBuilder: (context, index) {
              return _buildDeliveryCard(deliveryOrders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(OrderModel order) {
    bool isInTransit = order.transactionStatus == "In Transit";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInTransit ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        order.transactionStatus.toUpperCase(),
                        style: TextStyle(
                            color: isInTransit
                                ? Colors.green[800]
                                : Colors.blue[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "ID: #${order.id?.substring(0, 5).toUpperCase()}",
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  order.productName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Farmer: ${order.sellerName}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                if (order.driverName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text("Driver: ${order.driverName}",
                          style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                if (isInTransit && order.driverId != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LiveLocationPage(driverId: order.driverId!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text("Track Live"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5A42),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text("Waiting for Driver",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () async {
                    if (order.driverId != null) {
                       final doc = await FirebaseFirestore.instance.collection('Usersstore').doc(order.driverId).get();
                        final email = doc.data()?['email'] ?? 'Driver';
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverUserEmail: email,
                              receiverUserID: order.driverId!,
                            ),
                          ),
                        );
                      }
                    } else {
                        final doc = await FirebaseFirestore.instance.collection('Usersstore').doc(order.sellerId).get();
                        final email = doc.data()?['email'] ?? 'Farmer';
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverUserEmail: email,
                              receiverUserID: order.sellerId,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 20, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No active deliveries",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text("Once a farmer marks an order as ready,\nit will appear here for tracking.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
