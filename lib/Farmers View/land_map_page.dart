import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LandMapPage extends StatefulWidget {
  const LandMapPage({Key? key}) : super(key: key);

  @override
  _LandMapPageState createState() => _LandMapPageState();
}

class _LandMapPageState extends State<LandMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<LatLng> _polygonPoints = [];
  bool _isDrawing = true;
  bool _isSatellite = false;
  bool _isSaving = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kBg = Color(0xFF0F172A);
  static const Color kCard = Color(0xFF1E293B);

  // ── Area calculation (Shoelace + WGS-84 metres) ──────────────────────────
  /// Returns area in square metres using the spherical excess formula.
  double _calculateAreaM2() {
    if (_polygonPoints.length < 3) return 0;

    // Convert to radians
    final pts = _polygonPoints
        .map((p) => [p.latitude * pi / 180, p.longitude * pi / 180])
        .toList();

    // Spherical polygon area (WGS-84 R ≈ 6,378,137 m)
    const R = 6378137.0;
    double area = 0;
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += (pts[j][1] - pts[i][1]) * (2 + sin(pts[i][0]) + sin(pts[j][0]));
    }
    return (area * R * R / 2).abs();
  }

  double get _areaHectares => _calculateAreaM2() / 10000;
  double get _areaAcres => _calculateAreaM2() / 4046.856;

  void _clearPoints() => setState(() => _polygonPoints = []);
  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() => _polygonPoints.removeLast());
    }
  }

  // ── OSM Nominatim search ───────────────────────────────────────────────────
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&limit=5&countrycodes=et');
      final res = await http.get(url,
          headers: {'User-Agent': 'LinkedFarm/1.0 (linkedfarm.app)'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _searchResults = data
              .map((e) => {
                    'name': e['display_name'] as String,
                    'lat': double.parse(e['lat'].toString()),
                    'lon': double.parse(e['lon'].toString()),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _goToSearchResult(Map<String, dynamic> result) {
    final pos = LatLng(result['lat'], result['lon']);
    _mapController.move(pos, 16);
    setState(() => _searchResults = []);
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  // ── Go to my current location ─────────────────────────────────────────────
  Future<void> _goToMyLocation() async {
    final loc = Location();
    bool svc = await loc.serviceEnabled();
    if (!svc) svc = await loc.requestService();
    if (!svc) return;

    PermissionStatus perm = await loc.hasPermission();
    if (perm == PermissionStatus.denied) {
      perm = await loc.requestPermission();
      if (perm != PermissionStatus.granted) return;
    }

    final data = await loc.getLocation();
    if (data.latitude != null && data.longitude != null) {
      _mapController.move(LatLng(data.latitude!, data.longitude!), 17);
    }
  }

  // ── Save to Firestore ─────────────────────────────────────────────────────
  Future<void> _saveLandBoundary() async {
    if (_polygonPoints.length < 3) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Not logged in");

      await FirebaseFirestore.instance
          .collection("land_boundaries")
          .doc(uid)
          .set({
        "points": _polygonPoints
            .map((p) => {"lat": p.latitude, "lng": p.longitude})
            .toList(),
        "areaM2": _calculateAreaM2(),
        "areaHectares": _areaHectares,
        "areaAcres": _areaAcres,
        "updatedAt": FieldValue.serverTimestamp(),
        "userId": uid,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: kGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text("Land boundary saved!",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tileUrl = _isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/Services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Land Boundary Mapper",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _isSatellite ? "Street View" : "Satellite View",
            icon: Icon(
              _isSatellite
                  ? Icons.map_rounded
                  : Icons.satellite_alt_rounded,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
          IconButton(
            tooltip: "Undo last point",
            icon: const Icon(Icons.undo_rounded, color: Colors.white70),
            onPressed: _undoLastPoint,
          ),
          IconButton(
            tooltip: "Clear all points",
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: kCard,
                title: const Text("Clear boundary?",
                    style: TextStyle(color: Colors.white)),
                content: const Text("All points will be removed.",
                    style: TextStyle(color: Colors.white54)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearPoints();
                      Navigator.pop(context);
                    },
                    child: const Text("Clear",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(9.03, 38.74),
              initialZoom: 15.0,
              onTap: (_, latLng) {
                if (_isDrawing) {
                  setState(() => _polygonPoints.add(latLng));
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.linkedfarm.app',
              ),

              // Filled polygon
              if (_polygonPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _polygonPoints,
                      color: kGreen.withOpacity(0.25),
                      borderColor: kGreen,
                      borderStrokeWidth: 3,
                      isFilled: true,
                    ),
                  ],
                ),

              // Draft line while drawing
              if (_polygonPoints.length >= 2 && _polygonPoints.length < 3)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: _polygonPoints,
                      color: kGreen,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),

              // Vertex markers
              MarkerLayer(
                markers: _polygonPoints.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  return Marker(
                    point: pt,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: idx == 0 ? kGreen : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: kGreen,
                            width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: idx == 0
                          ? const Icon(Icons.flag_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Search bar ───────────────────────────────────────────────────
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kCard.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search_rounded, color: Colors.white54),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Search village or location...",
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                          onSubmitted: _searchLocation,
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white54, strokeWidth: 2)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.search_rounded,
                              color: Color(0xFF2E7D32)),
                          onPressed: () =>
                              _searchLocation(_searchController.text),
                        ),
                    ],
                  ),
                ),

                // Search results dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: _searchResults.map((r) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_rounded,
                              color: Color(0xFF2E7D32), size: 18),
                          title: Text(
                            r['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          onTap: () => _goToSearchResult(r),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom info / action card ─────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _polygonPoints.length < 3
                  ? _buildInstructionCard()
                  : _buildAreaCard(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "myLoc",
            backgroundColor: kCard,
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location_rounded, color: Colors.white70),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      key: const ValueKey('instruction'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: kCard.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.touch_app_rounded, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tap to mark boundary",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  "${_polygonPoints.length} point${_polygonPoints.length == 1 ? '' : 's'} placed · Need at least 3",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_polygonPoints.isNotEmpty)
            Text(
              "${_polygonPoints.length}",
              style: TextStyle(
                  color: kGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return Container(
      key: const ValueKey('area'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // Area stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _areaTile("Hectares", _areaHectares.toStringAsFixed(4), "ha"),
              Container(width: 1, height: 40, color: Colors.white10),
              _areaTile("Acres", _areaAcres.toStringAsFixed(4), "ac"),
              Container(width: 1, height: 40, color: Colors.white10),
              _areaTile("Points", "${_polygonPoints.length}", "pts"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _undoLastPoint,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text("Undo"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveLandBoundary,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isSaving ? "Saving..." : "Confirm & Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _areaTile(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text("$label ($unit)",
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
