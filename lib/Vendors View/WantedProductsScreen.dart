import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Services/farm_persistence_service.dart';
import '../../Services/notification_service.dart';
import '../../Models/notification_model.dart';
import 'WantedProductModel.dart';

class WantedProductsScreen extends StatefulWidget {
  const WantedProductsScreen({super.key});

  @override
  State<WantedProductsScreen> createState() => _WantedProductsScreenState();
}

class _WantedProductsScreenState extends State<WantedProductsScreen> {
  final FarmPersistenceService _persistence = FarmPersistenceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("WANTED PRODUCTS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<WantedProduct>>(
        stream: _persistence.streamWantedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          final myRequests = requests.where((r) => r.vendorId == _auth.currentUser?.uid).toList();
          final otherRequests = requests.where((r) => r.vendorId != _auth.currentUser?.uid).toList();

          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (myRequests.isNotEmpty) ...[
                _buildSectionHeader("MY REQUESTS"),
                ...myRequests.map((r) => _buildRequestCard(r, isOwner: true)),
                const SizedBox(height: 20),
              ],
              if (otherRequests.isNotEmpty) ...[
                _buildSectionHeader("MARKET DEMAND"),
                ...otherRequests.map((r) => _buildRequestCard(r, isOwner: false)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRequestDialog(context),
        label: const Text("POST WANTED PRODUCT", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("No requests found.", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Be the first to post what you need!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(WantedProduct request, {required bool isOwner}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: isOwner ? Colors.green[50] : Colors.orange[50], borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.inventory_2, color: isOwner ? Colors.green[800] : Colors.orange[800], size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.productName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Needs: ${request.quantityNeeded} | ${request.category}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 5),
                Text("Vendor: ${request.vendorName}", style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _persistence.deleteWantedProduct(request.id),
            )
          else
            const Icon(Icons.notifications_active, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  void _showAddRequestDialog(BuildContext context) {
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    String selectedCategory = "Cereals";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("POST YOUR REQUIREMENT", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: productController, decoration: const InputDecoration(labelText: "Product Name (e.g. White Maize)")),
              const SizedBox(height: 15),
              TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantity Needed (e.g. 10 Quintals)")),
              const SizedBox(height: 20),
              const Text("Category", style: TextStyle(color: Colors.grey, fontSize: 12)),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: ['Cereals', 'Pulses', 'Vegetables', 'Fruits', 'Spices', 'Others'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setModalState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (productController.text.isEmpty || quantityController.text.isEmpty) return;
                  
                  final newRequest = WantedProduct(
                    id: "", 
                    productName: productController.text,
                    category: selectedCategory,
                    quantityNeeded: quantityController.text,
                    vendorId: _auth.currentUser?.uid ?? '',
                    vendorName: _auth.currentUser?.displayName ?? 'Vendor',
                    createdAt: DateTime.now(),
                  );

                  await _persistence.saveWantedProduct(newRequest);
                  
                  // Create a notification for the user
                  final notification = SystemNotification(
                    id: "",
                    title: "Request Posted",
                    message: "You have successfully requested ${productController.text}.",
                    timestamp: DateTime.now(),
                    isRead: false,
                  );
                  await _persistence.saveNotification(notification);


                  NotificationService.playNotificationSound();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
