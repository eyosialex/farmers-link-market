import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linkedfarm/Dlivery%20View/delivery_location_tracker.dart';

class availabledriverylist extends StatelessWidget {
  const availabledriverylist({super.key});

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kBg = Color(0xFF0F172A);
  static const Color kCard = Color(0xFF1E293B);
  static const Color kOrange = Color(0xFFF57C00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Available Drivers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Live indicator
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _PulseDot(color: kGreen),
                const SizedBox(width: 6),
                const Text("Live",
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream all drivers
        stream: FirebaseFirestore.instance
            .collection("Usersstore")
            .where("userType", isEqualTo: "delivery")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty(context);
          }

          final drivers = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final driver = drivers[index];
              final driverData = driver.data() as Map<String, dynamic>;
              return _LiveDriverCard(
                driverId: driver.id,
                driverData: driverData,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_shipping_rounded),
        label: const Text("Become a Driver"),
        onPressed: () => _showBecomeDriverDialog(context),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 72, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 20),
            const Text("No Drivers Available",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Drivers will appear here once they register and go online.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showBecomeDriverDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text("Become a Driver"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBecomeDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Become a Delivery Driver",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("To start earning as a delivery driver:",
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            _BulletItem("Valid driver's licence"),
            _BulletItem("Reliable vehicle"),
            _BulletItem("Smartphone with GPS"),
            SizedBox(height: 12),
            Text("Contact support to complete your registration.",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _showContactDialog(context);
            },
            child: const Text("Contact Support"),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Contact Support",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ContactRow(Icons.email_rounded, "support@linkedfarm.com"),
            SizedBox(height: 8),
            _ContactRow(Icons.phone_rounded, "+251-911-123456"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK",
                  style: TextStyle(color: Color(0xFF2E7D32)))),
        ],
      ),
    );
  }
}

// ── Live driver card with Firestore real-time updates ──────────────────────
class _LiveDriverCard extends StatelessWidget {
  final String driverId;
  final Map<String, dynamic> driverData;

  const _LiveDriverCard(
      {required this.driverId, required this.driverData});

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kCard = Color(0xFF1E293B);
  static const Color kOrange = Color(0xFFF57C00);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("delivery_locations")
          .doc(driverId)
          .snapshots(),
      builder: (context, locSnap) {
        final locData = locSnap.data?.data() as Map<String, dynamic>?;
        final isOnline = locData?['isOnline'] == true;
        final hasLocation =
            locData?['latitude'] != null && locData?['longitude'] != null;
        final speedKmh =
            ((locData?['speed'] as num?)?.toDouble() ?? 0) * 3.6;

        return GestureDetector(
          onTap: isOnline && hasLocation
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LiveLocationPage(driverId: driverId),
                    ),
                  )
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOnline
                    ? kGreen.withOpacity(0.4)
                    : Colors.white.withOpacity(0.04),
              ),
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                          color: kGreen.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Avatar + online status
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isOnline
                          ? kGreen.withOpacity(0.2)
                          : Colors.white10,
                      child: Icon(
                        Icons.person_rounded,
                        color: isOnline ? kGreen : Colors.white38,
                        size: 28,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? kGreen : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: kCard, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverData["fullName"] ?? "Unknown Driver",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        driverData["cartype"] ?? "Vehicle unknown",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Online badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? kGreen.withOpacity(0.15)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (isOnline) _PulseDot(color: kGreen, size: 6),
                                if (isOnline) const SizedBox(width: 4),
                                Text(
                                  isOnline ? "Online" : "Offline",
                                  style: TextStyle(
                                      color: isOnline ? kGreen : Colors.white38,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          // Speed badge (online only)
                          if (isOnline && speedKmh > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: kOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${speedKmh.toStringAsFixed(0)} km/h",
                                style: const TextStyle(
                                    color: Color(0xFFF57C00),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Track button / offline icon
                if (isOnline && hasLocation)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF2E7D32), size: 22),
                  )
                else
                  const Icon(Icons.location_off_rounded,
                      color: Colors.white12, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({required this.color, this.size = 8});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_anim.value),
          ),
        ),
      );
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2E7D32), size: 14),
            const SizedBox(width: 8),
            Text(text,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}
