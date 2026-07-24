import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:linkedfarm/Dlivery%20View/delivery_location_tracker.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("MY PURCHASES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getOrdersByVendor(_auth.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildPurchaseCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("No purchases yet.", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Your orders will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(OrderModel order) {
    bool canCancel = order.transactionStatus == "Pending Payment" || order.transactionStatus == "Awaiting Verification";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.inventory_2, color: Colors.green[800]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("Seller: ${order.sellerName}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statusChip(order.transactionStatus),
                          const Spacer(),
                          Text("ETB ${order.totalPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D5A42))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (order.paymentProofUrl != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showFullscreenImage(order.paymentProofUrl!),
                    child: Text(
                      "View Uploaded Receipt",
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canCancel) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmCancel(order.id!),
                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                    label: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
          if (order.transactionStatus == "In Transit") ...[
             const Divider(height: 1),
             Padding(
               padding: const EdgeInsets.all(16),
               child: Row(
                 children: [
                    Icon(Icons.local_shipping, size: 20, color: Colors.blue[800]),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Driver ${order.driverName ?? ''} is on the way!", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (order.driverId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveLocationPage(driverId: order.driverId!),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text("Track"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        if (order.driverId != null) {
                          // Fetch driver email from Firestore
                          final driverDoc = await FirebaseFirestore.instance.collection('Usersstore').doc(order.driverId).get();
                          final driverEmail = driverDoc.data()?['email'] ?? 'Driver';
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  receiverUserEmail: driverEmail,
                                  receiverUserID: order.driverId!,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.chat_bubble_outline, color: Colors.blue[800], size: 20),
                      tooltip: "Chat with Driver",
                    ),
                  ],
                ),
              ),
           ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color chipColor = Colors.grey[100]!;
    Color textColor = Colors.grey[700]!;

    switch (status) {
      case "Delivered":
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case "In Transit":
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case "Payment Verified":
        chipColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        break;
      case "Awaiting Verification":
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case "Cancelled":
      case "Rejected":
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  void _confirmCancel(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order? Stock will be returned to the farmer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No, Keep It")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _firestoreService.cancelOrder(orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Cancelled.")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
