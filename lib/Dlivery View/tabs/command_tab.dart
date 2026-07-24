import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Dlivery%20View/osrm_delivery_page.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Dlivery%20View/livelocationtrack.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';
class CommandTab extends StatefulWidget {
  const CommandTab({super.key});

  @override
  State<CommandTab> createState() => _CommandTabState();
}

class _CommandTabState extends State<CommandTab>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOnline = false;
  late AnimationController _pulseController;
  final DeliveryLocationUpdater _locationUpdater = DeliveryLocationUpdater();

  // Dynamic values from backend
  double _todayEarningsValue = 0.0;
  int _activeRequestsCountValue = 0;
  final String _distanceKm = "142.8"; // Still mock for now as we don't track distance yet

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkOnlineStatus();
    _startStatsListeners();
  }

  void _startStatsListeners() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Listen for today's earnings (Delivered orders)
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _firestore
        .collection('orders')
        .where('driverId', isEqualTo: uid)
        .where('transactionStatus', isEqualTo: 'Delivered')
        .snapshots()
        .listen((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final updatedAt = DateTime.parse(data['updatedAt']);
        if (updatedAt.isAfter(startOfToday)) {
          total += (data['totalPrice'] ?? 0).toDouble();
        }
      }
      if (mounted) {
        setState(() {
          _todayEarningsValue = total;
        });
      }
    });

    // Listen for active jobs (In Transit)
    _firestore
        .collection('orders')
        .where('driverId', isEqualTo: uid)
        .where('transactionStatus', isEqualTo: 'In Transit')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeRequestsCountValue = snapshot.docs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkOnlineStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore
        .collection("delivery_locations")
        .doc(uid)
        .get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _isOnline = doc.data()?['isOnline'] ?? false;
        });
      }
    }
  }

  void _toggleOnline() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isOnline = !_isOnline);

    if (_isOnline) {
      await _locationUpdater.startSendingLocation();
    } else {
      await _locationUpdater.stopLocationTracking();
    }

    await _firestore.collection("delivery_locations").doc(uid).set({
      "isOnline": _isOnline,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatCards(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Active Jobs", "In Transit"),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('orders')
                        .where('driverId', isEqualTo: _auth.currentUser?.uid)
                        .where('transactionStatus', isEqualTo: 'In Transit')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              "No active jobs. Go to Requests to find work.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      final orderDocs = snapshot.data!.docs;
                      return Column(
                        children: orderDocs.map((doc) {
                          final order = OrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildJobCard(
                              orderId: order.id!,
                              pickup: order.sellerName,
                              pickupLoc: order.pickupAddress ?? "Farm Location",
                              dropoff: order.vendorName,
                              dropoffLoc: order.dropoffAddress ?? "Market Hub",
                              payload: "${order.productName} (${order.quantity} units)",
                              earnings: "ETB ${order.totalPrice.toStringAsFixed(0)}",
                              isExpress: true,
                              sellerId: order.sellerId,
                              vendorId: order.vendorId,
                              pickupLatLng: order.pickupLocation != null ? LatLng(order.pickupLocation!['lat']!, order.pickupLocation!['lng']!) : null,
                              dropoffLatLng: order.dropoffLocation != null ? LatLng(order.dropoffLocation!['lat']!, order.dropoffLocation!['lng']!) : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Recommended", "Based on location"),
                  _buildSectionHeader("Live Route", "4.2km away"),
                  const SizedBox(height: 16),
                  _buildLiveRouteMap(),
                  const SizedBox(height: 16),
                  _buildHelpCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            const SizedBox(width: 12),
            const Text(
              "LINKEDFARM",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A34),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnline ? Colors.green[200]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  if (_isOnline)
                    FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  if (_isOnline) const SizedBox(width: 4),
                  Text(
                    _isOnline ? "LIVE" : "OFFLINE",
                    style: TextStyle(
                      color: _isOnline ? Colors.green[700] : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _toggleOnline,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isOnline
                ? Colors.red[800]
                : const Color(0xFF2D5A42),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isOnline ? "OFFLINE" : "ONLINE",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        _statCard(
          "TODAY'S EARNINGS",
          "ETB ${_todayEarningsValue.toStringAsFixed(0)}",
          Icons.account_balance_wallet_outlined,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _statCard(
          "DISTANCE (KM)",
          _distanceKm,
          Icons.route_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _statCard(
          "ACTIVE JOBS (TRANSIT)",
          _activeRequestsCountValue.toString(),
          Icons.assignment_outlined,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildJobCard({
    required String orderId,
    required String pickup,
    required String pickupLoc,
    required String dropoff,
    required String dropoffLoc,
    required String payload,
    required String earnings,
    bool isExpress = false,
    bool isPerishable = false,
    String? sellerId,
    String? vendorId,
    LatLng? pickupLatLng,
    LatLng? dropoffLatLng,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isExpress) _badge("EXPRESS", Colors.orange),
                        if (isExpress && isPerishable) const SizedBox(width: 8),
                        if (isPerishable) _badge("PERISHABLE", Colors.blue),
                      ],
                    ),
                    Text(
                      earnings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D5A42),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _locationRow(Icons.location_on, pickup, pickupLoc, Colors.green),
                const SizedBox(height: 12),
                _locationRow(Icons.flag_rounded, dropoff, dropoffLoc, Colors.orange),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      payload,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OSRDeliveryPage(
                            jobTitle: payload,
                            farmerName: pickup,
                            initialEnd: pickupLatLng,
                            initialDropoff: dropoffLatLng,
                          ),
                        ),
                      );
                    },
                    child: const Text("View Route"),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (sellerId != null) {
                      final doc = await FirebaseFirestore.instance.collection('Usersstore').doc(sellerId).get();
                      final email = doc.data()?['email'] ?? 'Farmer';
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(receiverUserEmail: email, receiverUserID: sellerId!)));
                      }
                    }
                  },
                  icon: const Icon(Icons.forum_outlined, size: 18, color: Colors.green),
                  tooltip: "Chat with Farmer",
                ),
                IconButton(
                  onPressed: () {
                    if (vendorId != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverUserEmail: dropoff,
                            receiverUserID: vendorId!,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.forum_outlined, size: 18, color: Colors.blue),
                  tooltip: "Chat with Vendor",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCompleteDialog(orderId, payload),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5A42),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Delivered"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(String orderId, String payload) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delivery"),
        content: Text("Have you successfully delivered $payload to the vendor?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final firestoreService = FirestoreService();
              final success = await firestoreService.completeOrderDelivery(orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Delivery Completed! System updated.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A42)),
            child: const Text("Yes, Delivered"),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _locationRow(IconData icon, String name, String loc, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                loc,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title.replaceAll(" ", "\n"),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A34),
            height: 0.9,
          ),
        ),
        Text(
          action,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange[900],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRouteMap() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(9.035, 38.75),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.linkedfarm.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: const [
                      LatLng(9.03, 38.74),
                      LatLng(9.035, 38.75),
                      LatLng(9.04, 38.76),
                    ],
                    color: const Color(0xFF00FF88),
                    strokeWidth: 6,
                    //isDotted: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(9.04, 38.76),
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B4513),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Navigation Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation, color: Color(0xFF1E3A34)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Head North toward Farm A",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.gps_fixed, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A34),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NEXT DESTINATION",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Abebe's\nCollection Point",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "REPORT DELAY",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  "ESTIMATED",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "15M",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00FF88),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD1BD),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need Dispatcher Help?",
                  style: TextStyle(
                    color: Color(0xFF4A2C21),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "One-tap contact for support",
                  style: TextStyle(color: Color(0xFF7A594D), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.phone, color: Color(0xFF4A2C21), size: 20),
          ),
        ],
      ),
    );
  }
}
