import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:linkedfarm/Dlivery%20View/delivery_location_tracker.dart';
import 'package:intl/intl.dart';
import 'package:linkedfarm/Farmers%20View/OrderSuccessScreen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("ORDER MANAGEMENT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getOrdersBySeller(_auth.currentUser?.uid ?? ''),
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
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
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
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("No orders received yet.", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Orders from vendors will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final bool needsVerification = order.transactionStatus == "Awaiting Verification";
    bool canMarkAsReady = order.transactionStatus == "Payment Verified";
    bool isCompleted = order.transactionStatus == "Completed";
    
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    image: order.productImage != null 
                        ? DecorationImage(image: NetworkImage(order.productImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: order.productImage == null ? Icon(Icons.shopping_bag, color: Colors.green[800]) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("Buyer: ${order.vendorName}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statusChip(order.transactionStatus),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("ETB ${order.totalPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D5A42))),
                              Text("${order.quantity} ${order.productUnit}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (order.transactionStatus == "In Transit") ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 20, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text("Driver: ${order.driverName ?? 'Assigned'}", style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton.icon(
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
                    label: const Text("Track Order"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (needsVerification) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(Icons.image_outlined, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text("Payment Proof Uploaded", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _verifyPayment(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5A42),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("VERIFY & AUTHORIZE PICKUP"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (canMarkAsReady) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                    onPressed: () async {
                        await _firestoreService.updateOrderStatus(order.id!, "Ready for Pickup");
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrderSuccessScreen(
                                title: "Order Ready!",
                                message: "The order is now available for drivers to accept. Please keep the package safe.",
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("MARK AS READY FOR PICKUP"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
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

    if (status == "Payment Verified" || status == "Pending Delivery" || status == "Ready for Pickup" || status == "Completed") {
      chipColor = Colors.green[50]!;
      textColor = Colors.green[800]!;
    } else if (status == "Awaiting Verification") {
      chipColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
    } else if (status == "Verification Issue") {
      chipColor = Colors.red[50]!;
      textColor = Colors.red[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  void _verifyPayment(OrderModel order) async {
    bool amountMatches = false;
    bool refMatches = false;
    bool looksAuthentic = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Verification Checklist"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _infoRow(Icons.inventory_2_outlined, "Product: ${order.productName}"),
                        _infoRow(Icons.scale_outlined, "Quantity: ${order.quantity} ${order.productUnit}"),
                        const Divider(height: 16),
                        _infoRow(Icons.payments_outlined, "Target Amount: ETB ${order.totalPrice}"),
                        _infoRow(Icons.tag, "Ref Code: ${order.paymentReferenceCode ?? 'N/A'}"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Examine the receipt below carefully:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  if (order.paymentProofUrl != null)
                    _buildProofThumbnail(order.paymentProofUrl!)
                  else
                    const Text("No screenshot uploaded"),
                  const Divider(height: 32),
                  CheckboxListTile(
                    title: const Text("Amount matches bank statement", style: TextStyle(fontSize: 13)),
                    value: amountMatches,
                    onChanged: (val) => setModalState(() => amountMatches = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text("Reference code matches Bank Note", style: TextStyle(fontSize: 13)),
                    value: refMatches,
                    onChanged: (val) => setModalState(() => refMatches = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text("Screenshot looks authentic", style: TextStyle(fontSize: 13)),
                    value: looksAuthentic,
                    onChanged: (val) => setModalState(() => looksAuthentic = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
               TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reportIssue(order);
                },
                child: const Text("Report Issue", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: (amountMatches && refMatches && looksAuthentic) 
                  ? () async {
                      Navigator.pop(context);
                      await _firestoreService.updateOrderStatus(order.id!, "Payment Verified");
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderSuccessScreen(
                              title: "Payment Verified!",
                              message: "Success! You have verified the payment. Now you can pack the item and mark it as ready.",
                            ),
                          ),
                        );
                      }
                    }
                  : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Approve Payment"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[900])),
      ],
    );
  }

  Widget _buildProofThumbnail(String url) {
    return GestureDetector(
      onTap: () => _showFullscreenImage(url),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(child: Icon(Icons.zoom_in, color: Colors.white70)),
      ),
    );
  }

  void _reportIssue(OrderModel order) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark as Suspicious"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Reason for issue", hintText: "e.g. Reference code missing"),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.markOrderAsSuspicious(order.id!, reasonController.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order flagged. Customer notified.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirm Report"),
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
