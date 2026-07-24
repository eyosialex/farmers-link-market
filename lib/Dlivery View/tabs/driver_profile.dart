import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Models/order_model.dart';

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String name = user?.displayName ?? "Delivery Partner";
    final String email = user?.email ?? "partner@linkedfarm.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(name, email),
              const SizedBox(height: 32),
              _buildStatsGrid(user?.uid ?? ''),
              const SizedBox(height: 32),
              _buildMenuSection(),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Column(
      children: [
        const Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF2D5A42),
              child: Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3A34))),
        Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green[200]!)),
          child: const Text("VERIFIED DRIVER", style: TextStyle(color: Color(0xFF2D5A42), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(String uid) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<OrderModel>>(
      stream: firestoreService.getOrdersByDriver(uid, status: 'Delivered'),
      builder: (context, snapshot) {
        int totalDeliveries = 0;
        double totalEarnings = 0;

        if (snapshot.hasData) {
          totalDeliveries = snapshot.data!.length;
          for (var order in snapshot.data!) {
            totalEarnings += order.totalPrice;
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _statBox("Lifetime Earnings", "ETB ${totalEarnings.toStringAsFixed(0)}", Icons.payments_outlined, Colors.green),
            _statBox("Total Deliveries", totalDeliveries.toString(), Icons.local_shipping_outlined, Colors.blue),
            _statBox("Driver Rating", "5.0 / 5.0", Icons.star_border_rounded, Colors.orange),
            _statBox("Account Status", "Active", Icons.verified_user_outlined, Colors.purple),
          ],
        );
      }
    );
  }

  Widget _statBox(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _menuItem(Icons.person_outline, "Personal Information"),
          _divider(),
          _menuItem(Icons.account_balance_outlined, "Payout Settings"),
          _divider(),
          _menuItem(Icons.notifications_none_rounded, "Notification Preferences"),
          _divider(),
          _menuItem(Icons.security_rounded, "Security & Privacy"),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A34)),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: () {},
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100], indent: 56);

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => FirebaseAuth.instance.signOut(),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text("Log Out"),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red[700],
        side: BorderSide(color: Colors.red[100]!),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
