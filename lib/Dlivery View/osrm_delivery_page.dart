import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class OSRDeliveryPage extends StatefulWidget {
  final LatLng? initialStart;
  final LatLng? initialEnd; // Pickup
  final LatLng? initialDropoff; // Dropoff
  final String? jobTitle;
  final String? farmerName;

  const OSRDeliveryPage({
    Key? key,
    this.initialStart,
    this.initialEnd,
    this.initialDropoff,
    this.jobTitle,
    this.farmerName,
  }) : super(key: key);

  @override
  _OSRDeliveryPageState createState() => _OSRDeliveryPageState();
}

class _OSRDeliveryPageState extends State<OSRDeliveryPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Location _locationService = Location();

  List<LatLng> _routePoints = [];
  List<LatLng> _pickupToDropoffPoints = [];
  LatLng? _startPoint;   // driver's live position
  LatLng? _endPoint;     // Pickup (farmer)
  LatLng? _dropoffPoint; // Dropoff (vendor)
  LatLng? _myLivePos;

  String _distance = "–";
  String _duration = "–";
  String _eta = "–";
  bool _isLoading = false;
  bool _mapLayerSatellite = false;

  StreamSubscription<LocationData>? _locationSub;
  Timer? _refreshTimer;

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kOrange = Color(0xFFF57C00);
  static const Color kBg = Color(0xFF0F172A);
  static const Color kCard = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _startPoint = widget.initialStart;
    _endPoint = widget.initialEnd;
    _dropoffPoint = widget.initialDropoff;
    _startLiveTracking();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Live GPS tracking ──────────────────────────────────────────────────────
  Future<void> _startLiveTracking() async {
    bool svc = await _locationService.serviceEnabled();
    if (!svc) svc = await _locationService.requestService();
    if (!svc) return;

    PermissionStatus perm = await _locationService.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await _locationService.requestPermission();
      if (perm != PermissionStatus.granted) return;
    }

    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 4000,
      distanceFilter: 8,
    );

    _locationSub = _locationService.onLocationChanged.listen((loc) async {
      if (loc.latitude == null || loc.longitude == null) return;
      final pos = LatLng(loc.latitude!, loc.longitude!);

      // Upload my position to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance
            .collection("delivery_locations")
            .doc(uid)
            .set({
          "latitude": loc.latitude,
          "longitude": loc.longitude,
          "speed": loc.speed ?? 0.0,
          "heading": loc.heading ?? 0.0,
          "accuracy": loc.accuracy ?? 0.0,
          "isOnline": true,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() {
        _myLivePos = pos;
        if (_startPoint == null || widget.initialStart == null) {
          _startPoint = pos;
        }
      });

      // Auto re-route if start changed significantly
      if (_endPoint != null) {
        _getRoute(silent: true);
      }
    });

    // Route auto-refresh every 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_endPoint != null) _getRoute(silent: true);
    });

    // Initial route
    if (_startPoint != null && _endPoint != null) _getRoute();
  }

  // ── OSRM Route Fetch ───────────────────────────────────────────────────────
  Future<void> _getRoute({bool silent = false}) async {
    if (_startPoint == null || _endPoint == null) return;
    if (!silent) setState(() => _isLoading = true);

    String coords = '${_startPoint!.longitude},${_startPoint!.latitude};${_endPoint!.longitude},${_endPoint!.latitude}';
    if (_dropoffPoint != null) {
      coords += ';${_dropoffPoint!.longitude},${_dropoffPoint!.latitude}';
    }

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry =
            data['routes'][0]['geometry']['coordinates'] as List;
        final distM = (data['routes'][0]['distance'] as num).toDouble();
        final durS = (data['routes'][0]['duration'] as num).toDouble();

        final etaTime = DateTime.now().add(Duration(seconds: durS.toInt()));

        if (mounted) {
          final allPoints = geometry
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          setState(() {
            if (_dropoffPoint != null) {
              // Try to find the waypoint for the pickup to split the path
              // For simplicity in OSRM without steps, we'll just show the whole line
              // but we can try to find the closest point to _endPoint to split it.
              _routePoints = allPoints;
              _pickupToDropoffPoints = []; // We'll just use one line for now or split by distance
            } else {
              _routePoints = allPoints;
              _pickupToDropoffPoints = [];
            }
            
            _distance = "${(distM / 1000).toStringAsFixed(1)} km";
            _duration = "${(durS / 60).toStringAsFixed(0)} min";
            _eta =
                "${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}";
          });

          if (_routePoints.isNotEmpty && !silent) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(_routePoints),
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        }
      }
    } on TimeoutException {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Route request timed out. Retrying...")),
        );
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calcDist(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final x = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(x), sqrt(1 - x));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tileUrl = _mapLayerSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/Services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

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
              widget.jobTitle ?? "Delivery Navigation",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (widget.farmerName != null)
              Text(
                "To: ${widget.farmerName}",
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          // Layer toggle
          IconButton(
            tooltip: _mapLayerSatellite ? "Street View" : "Satellite View",
            icon: Icon(
              _mapLayerSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _mapLayerSatellite = !_mapLayerSatellite),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: _getRoute,
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _startPoint ?? const LatLng(9.03, 38.74),
              initialZoom: 13.0,
              onTap: (tapPos, latLng) {
                // First tap = start (if no GPS), second tap = destination
                if (_startPoint != null && _endPoint == null) {
                  setState(() => _endPoint = latLng);
                  _getRoute();
                } else if (_endPoint != null) {
                  setState(() {
                    _endPoint = latLng;
                    _routePoints = [];
                  });
                  _getRoute();
                } else {
                  setState(() => _startPoint = latLng);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.linkedfarm.app',
                subdomains: _mapLayerSatellite ? const [] : const ['a', 'b', 'c'],
              ),

              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // shadow
                    Polyline(
                      points: _routePoints,
                      color: Colors.black38,
                      strokeWidth: 9,
                    ),
                    // main
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF1565C0),
                      strokeWidth: 5,
                    ),
                    // progress glow
                    Polyline(
                      points: _routePoints.take((_routePoints.length * 0.3).toInt()).toList(),
                      color: Colors.lightBlueAccent.withOpacity(0.6),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Live position (me / driver)
                  if (_myLivePos != null)
                    Marker(
                      point: _myLivePos!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: kGreen.withOpacity(0.5), blurRadius: 12)
                          ],
                        ),
                        child: const Icon(Icons.local_shipping_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),

                  // Destination (Farmer/Pickup)
                  if (_endPoint != null)
                    Marker(
                      point: _endPoint!,
                      width: 44,
                      height: 44,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.home_work_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),

                  // Dropoff (Vendor)
                  if (_dropoffPoint != null)
                    Marker(
                      point: _dropoffPoint!,
                      width: 48,
                      height: 48,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: kOrange.withOpacity(0.5),
                                    blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.flag_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top instruction chip ──
          if (_endPoint == null)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: kCard.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.touch_app_rounded,
                          size: 16, color: Colors.white54),
                      SizedBox(width: 8),
                      Text("Tap on map to set destination",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Info Card ──
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: kCard.withOpacity(0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black45,
                      blurRadius: 24,
                      offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoTile(Icons.straighten_rounded, _distance, "Distance", kGreen),
                      _vDivider(),
                      _infoTile(Icons.timer_rounded, _duration, "Duration", Colors.blue),
                      _vDivider(),
                      _infoTile(Icons.schedule_rounded, _eta, "ETA", kOrange),
                    ],
                  ),
                  if (_endPoint != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getRoute,
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text("Recalculate Route"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      // Center on my location FAB
      floatingActionButton: _myLivePos != null
          ? FloatingActionButton.small(
              backgroundColor: kGreen,
              onPressed: () => _mapController.move(_myLivePos!, 16),
              child:
                  const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _infoTile(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.white10);
}
