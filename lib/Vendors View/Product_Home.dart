
import 'package:linkedfarm/Farmers%20View/Enter_Sell_Item.dart';
import 'package:linkedfarm/Vendors%20View/WantedProductsScreen.dart';
import 'package:linkedfarm/Vendors%20View/product.dart';
import 'package:linkedfarm/Chat/chat_list.dart';
import 'package:linkedfarm/Farmers%20View/advice_feed.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/User%20Credential/log_in_page.dart';

import 'package:linkedfarm/Vendors%20View/NotificationCenterScreen.dart';
import 'package:linkedfarm/Services/farm_persistence_service.dart';
import 'package:linkedfarm/Models/notification_model.dart';
import 'package:linkedfarm/Vendors%20View/Vendor_Price_Prediction.dart';
import 'package:linkedfarm/Vendors%20View/Trusted_Farmers_Screen.dart';
import 'package:linkedfarm/Vendors View/Shared_Delivery_Screen.dart';
import 'package:linkedfarm/Vendors%20View/Vendor_Advisory_Screen.dart';
import 'package:linkedfarm/Vendors%20View/MyPurchasesScreen.dart';
import 'package:linkedfarm/Main%20Office/main_office_page.dart';
import 'package:linkedfarm/Vendors%20View/DeliveryTrackingHub.dart';

import 'package:linkedfarm/Services/notification_service.dart';
import 'dart:async';

class vendors_page extends StatefulWidget {
  const vendors_page({super.key});

  @override
  State<vendors_page> createState() => _vendors_pageState();
}

class _vendors_pageState extends State<vendors_page> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FarmPersistenceService _persistence = FarmPersistenceService();
  StreamSubscription? _notificationSubscription;
  int _lastUnreadCount = 0;
  bool _isFirstLoad = true;
  DateTime _lastNotificationTime = DateTime.now();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Browse Crops',
      'icon': Icons.search,
      'image': 'assets/product.png',
      'page': const ProductListScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Requests',
      'icon': Icons.shopping_cart,
      'image': 'assets/delivery.jpg',
      'page': const WantedProductsScreen(), // View market demand
      'gradient': const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'My Purchases',
      'icon': Icons.assignment_turned_in,
      'image': 'assets/product.png',
      'page': const MyPurchasesScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF2D5A42), Color(0xFF1E3A34)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Market Trends',
      'icon': Icons.trending_up,
      'image': 'assets/price.jpg',
      'page': const VendorPricePredictionScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Trusted Farmers',
      'icon': Icons.verified_user,
      'image': 'assets/profile.jpg',
      'page': const TrustedFarmersScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF009688), Color(0xFF00796B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Track Shipments',
      'icon': Icons.gps_fixed,
      'image': 'assets/delivery_realistic.jpg',
      'page': const DeliveryTrackingHub(),
      'gradient': const LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFE65100)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Delivery Pool',
      'icon': Icons.local_shipping,
      'image': 'assets/delivery.jpg',
      'page': const SharedDeliveryScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF607D8B), Color(0xFF455A64)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Vendor Advisor',
      'icon': Icons.psychology,
      'image': 'assets/advice.jpg',
      'page': const VendorAdvisoryScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF795548), Color(0xFF5D4037)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Messages',
      'icon': Icons.chat_bubble,
      'image': 'assets/chat.jpg',
      'page': const ChatListScreen(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Main Office',
      'icon': Icons.business_rounded,
      'image': 'assets/hq_realistic.jpg',
      'page': const MainOfficePage(),
      'gradient': const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF1B5E20)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _startNotificationListener() {
    _notificationSubscription = _persistence.streamNotifications().listen((notifications) {
      final unreadCount = notifications.where((n) => !n.isRead).length;

      if (_isFirstLoad) {
        _lastUnreadCount = unreadCount;
        _isFirstLoad = false;
        return;
      }

      if (unreadCount > _lastUnreadCount) {
        final now = DateTime.now();
        // Prevent sounds from firing too rapidly (at least 2 seconds apart)
        if (now.difference(_lastNotificationTime) > const Duration(seconds: 2)) {
          NotificationService.playNotificationSound();
          _lastNotificationTime = now;
        }
      }
      _lastUnreadCount = unreadCount;
    });
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background Texture/Image for the section
          Positioned.fill(
            child: Opacity(
              opacity: 0.2, // Increased visibility
              child: Image.asset(
                'assets/vendors_header.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
              ),
            ),
          ),
          CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green[800],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/vendors_header.jpg', // Reuse or add vendor specific image
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.green[900]);
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                "LinkedFarm",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              StreamBuilder<List<AppNotification>>(
                stream: _persistence.streamNotifications(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),

          // Welcome Message
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vendor Portal",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Connect with farmers and manage your inventory.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid Menu
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildMenuCard(_menuItems[index], context);
                },
                childCount: _menuItems.length,
              ),
            ),
          ),
        ]),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (item['page'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['page']),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${item['title']} coming soon!")),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image not found
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: item['gradient'],
                      ),
                    );
                  },
                ),
              ),
              // Dark overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'], size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
