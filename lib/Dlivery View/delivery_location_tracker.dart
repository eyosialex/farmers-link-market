import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveLocationPage extends StatefulWidget {
  final String driverId;

  const LiveLocationPage({super.key, required this.driverId});

  @override
  _LiveLocationPageState createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPos;
  LatLng? _previousPos;
  Map<String, dynamic>? _driverDetails;
  bool _isLoading = true;
  double? _speed;
  double? _heading;
  double? _accuracy;
  DateTime? _lastUpdated;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kOrange = Color(0xFFF57C00);
  static const Color kBg = Color(0xFF0F172A);
  static const Color kCard = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    _loadDriverDetails();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadDriverDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Usersstore")
          .doc(widget.driverId)
          .get();
      if (doc.exists && mounted) {
        setState(() => _driverDetails = doc.data()!);
      }
    } catch (e) {
      debugPrint("Error loading driver details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToDriverLocation() {
    FirebaseFirestore.instance
        .collection("delivery_locations")
        .doc(widget.driverId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data() as Map<String, dynamic>;
      if (data["latitude"] == null || data["longitude"] == null) return;

      final newPos = LatLng(
        (data["latitude"] as num).toDouble(),
        (data["longitude"] as num).toDouble(),
      );

      setState(() {
        _previousPos = _currentPos;
        _currentPos = newPos;
        _speed = (data["speed"] as num?)?.toDouble();
        _heading = (data["heading"] as num?)?.toDouble();
        _accuracy = (data["accuracy"] as num?)?.toDouble();
        _lastUpdated = data["updatedAt"] != null
            ? (data["updatedAt"] as Timestamp).toDate()
            : DateTime.now();
        _isLoading = false;
      });

      try {
        _mapController.move(newPos, _mapController.camera.zoom);
      } catch (_) {}
    }, onError: (e) {
      debugPrint("Location stream error: $e");
      if (mounted) setState(() => _isLoading = false);
    });
  }

  double _calcDistance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(a.latitude)) *
            cos(_toRad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  double _toRad(double deg) => deg * pi / 180;

  String _formatLastUpdated() {
    if (_lastUpdated == null) return "–";
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    return "${diff.inMinutes}m ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _driverDetails?["fullName"] ?? "Driver Location",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Opacity(
                    opacity: _currentPos != null ? _pulseAnimation.value : 0.3,
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: _currentPos != null ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Text(
                  _currentPos != null ? "Live Tracking" : "Waiting for signal...",
                  style: TextStyle(
                    fontSize: 11,
                    color: _currentPos != null ? Colors.greenAccent : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text("Getting driver location...", style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : Stack(
              children: [
                // ── MAP ──
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPos ?? const LatLng(9.03, 38.74),
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.linkedfarm.app',
                    ),
                    // Accuracy circle
                    if (_currentPos != null && _accuracy != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _currentPos!,
                            radius: _accuracy!,
                            useRadiusInMeter: true,
                            color: kGreen.withOpacity(0.12),
                            borderColor: kGreen.withOpacity(0.35),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    // Trail polyline
                    if (_previousPos != null && _currentPos != null)
                      PolylineLayer(
                        polylines: <Polyline>[
                          Polyline(
                            points: [_previousPos!, _currentPos!],
                            color: kGreen.withOpacity(0.6),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    // Driver marker
                    if (_currentPos != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPos!,
                            width: 56,
                            height: 56,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (_, __) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 56 * _pulseAnimation.value,
                                    height: 56 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kGreen.withOpacity(0.2),
                                    ),
                                  ),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: kGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kGreen.withOpacity(0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping_rounded,
                                        color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Driver Info Card (top) ──
                if (_driverDetails != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kCard.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: kGreen.withOpacity(0.2),
                            child: const Icon(Icons.person_rounded, color: Color(0xFF2E7D32), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driverDetails!["fullName"] ?? "Driver",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _driverDetails!["cartype"] ?? "Vehicle",
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          _statPill(
                            Icons.update_rounded,
                            _formatLastUpdated(),
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Stats Row (bottom) ──
                if (_currentPos != null)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: kCard.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black38, blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metricTile(
                            Icons.speed_rounded,
                            _speed != null
                                ? "${(_speed! * 3.6).toStringAsFixed(0)} km/h"
                                : "– km/h",
                            "Speed",
                            kGreen,
                          ),
                          _divider(),
                          _metricTile(
                            Icons.my_location_rounded,
                            _accuracy != null
                                ? "±${_accuracy!.toStringAsFixed(0)}m"
                                : "–",
                            "Accuracy",
                            Colors.blue,
                          ),
                          _divider(),
                          _metricTile(
                            Icons.explore_rounded,
                            _currentPos != null
                                ? "${_currentPos!.latitude.toStringAsFixed(4)},\n${_currentPos!.longitude.toStringAsFixed(4)}"
                                : "–",
                            "Coordinates",
                            kOrange,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── No location yet ──
                if (_currentPos == null && !_isLoading)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.signal_wifi_off_rounded,
                              size: 60, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text("No Location Signal",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            "Driver may have location sharing off.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      // Center on driver FAB
      floatingActionButton: _currentPos != null
          ? FloatingActionButton.small(
              backgroundColor: kGreen,
              onPressed: () => _mapController.move(_currentPos!, 16),
              child: const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _metricTile(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _divider() => Container(
        height: 36,
        width: 1,
        color: Colors.white10,
      );

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
