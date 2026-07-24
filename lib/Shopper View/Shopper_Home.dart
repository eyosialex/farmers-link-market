import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/User%20Credential/log_in_page.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Shopper%20View/Sell_Input_Item.dart';
import 'package:linkedfarm/Main%20Office/main_office_page.dart';
import 'package:linkedfarm/Vendors%20View/NotificationCenterScreen.dart';
import 'dart:ui';

class ShopperHomePage extends StatefulWidget {
  const ShopperHomePage({super.key});

  @override
  State<ShopperHomePage> createState() => _ShopperHomePageState();
}

class _ShopperHomePageState extends State<ShopperHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Design Tokens
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LogInPage(onTap: null)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background Glow
          _buildBackgroundDecoration(),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(l10n),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWelcomeHeader(l10n),
                      const SizedBox(height: 24),
                      _buildStatGrid(l10n),
                      const SizedBox(height: 32),
                      _buildSectionHeader(l10n.sellInputs, Icons.bolt_rounded),
                      const SizedBox(height: 16),
                      _buildStoreControls(context, l10n),
                      const SizedBox(height: 32),
                      _buildSectionHeader("Active Inventory", Icons.inventory_2_outlined),
                      const SizedBox(height: 16),
                      _buildRecentActivity(l10n),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryGreen.withOpacity(0.15),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      backgroundColor: bgDark,
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      title: const Text(
        "LinkedFarm Marketplace",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationCenterScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: const Text(
                "INPUT SUPPLIER",
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Good Morning,",
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
        const Text(
          "Supplier Central",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Total Sales",
            "124.5k",
            Icons.account_balance_wallet_outlined,
            primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Active Items",
            "18",
            Icons.inventory_2_outlined,
            accentOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "New Orders",
            "4",
            Icons.shopping_bag_outlined,
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreControls(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _largeActionCard(
          "Add New Input",
          "List Fertilizers, Pesticides, or Seeds",
          Icons.add_shopping_cart_rounded,
          primaryGreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellInputItem()),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _smallActionCard(
                "Inventory",
                Icons.list_alt_rounded,
                accentOrange,
                () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _smallActionCard(
                "HQ Office",
                Icons.business_rounded,
                Colors.deepPurpleAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MainOfficePage())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _largeActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _activityItem("Urea Fertilizer", "3 hours ago", "+ 500 ETB", primaryGreen),
          const Divider(color: Colors.white10, indent: 60),
          _activityItem("Organic Seeds", "Yesterday", "+ 1,200 ETB", primaryGreen),
          const Divider(color: Colors.white10, indent: 60),
          _activityItem("New Message", "2 days ago", "From Farmer Abebe", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time, String status, Color statusColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.history_rounded, color: Colors.white60, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        time,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: Text(
        status,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
