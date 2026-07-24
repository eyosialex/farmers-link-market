import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:location/location.dart';

class MapTestScreen extends StatefulWidget {
  final Function(String, String, String) onLocationSelected;

  const MapTestScreen({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  _MapTestScreenState createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(9.03, 38.74);
  String? _selectedAddress;
  bool _isLoading = false;
  bool _isSatellite = false;
  List<Map<String, dynamic>> _searchResults = [];

  static const Color kGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_center);
  }

  // ── Nominatim reverse-geocode ─────────────────────────────────────────────
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&format=json&addressdetails=1',
      );
      final res = await http.get(url,
          headers: {'User-Agent': 'LinkedFarm/1.0 (linkedfarm.app)'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final parts = <String>[];
          for (final key in [
            'village',
            'suburb',
            'town',
            'city',
            'county',
            'state'
          ]) {
            if (address[key] != null) parts.add(address[key]);
          }
          setState(() {
            _selectedAddress = parts.isNotEmpty
                ? parts.join(', ')
                : 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _selectedAddress =
            'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Nominatim forward-geocode search ──────────────────────────────────────
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final res = await http.get(url,
          headers: {'User-Agent': 'LinkedFarm/1.0 (linkedfarm.app)'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        if (data.isEmpty) {
          _showSnackBar(
              AppLocalizations.of(context)?.locationNotFound ??
                  'Location not found');
        } else {
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
      }
    } catch (e) {
      _showSnackBar(
          AppLocalizations.of(context)?.networkError ?? 'Network error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final pos = LatLng(result['lat'], result['lon']);
    _mapController.move(pos, 16);
    setState(() {
      _center = pos;
      _searchResults = [];
      _selectedAddress = result['name'];
    });
    _searchController.clear();
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
      final pos = LatLng(data.latitude!, data.longitude!);
      _mapController.move(pos, 17);
      setState(() => _center = pos);
      _reverseGeocode(pos);
    }
  }

  void _confirmLocation() {
    widget.onLocationSelected(
      _center.latitude.toStringAsFixed(6),
      _center.longitude.toStringAsFixed(6),
      _selectedAddress ??
          AppLocalizations.of(context)?.unknownLocation ??
          'Unknown location',
    );
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/Services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  setState(() => _center = pos.center!);
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.linkedfarm.app',
              ),
            ],
          ),

          // ── Centre cross-hair pin ────────────────────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 48, color: Colors.red),
                SizedBox(height: 48), // offset for pin tip
              ],
            ),
          ),

          // ── Search bar + results ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                    ?.searchLocationHint ??
                                'Search location...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: _searchLocation,
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () =>
                              _searchLocation(_searchController.text),
                        ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: _searchResults.map((r) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_rounded,
                              color: Color(0xFF2E7D32), size: 18),
                          title: Text(
                            r['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _selectSearchResult(r),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // ── Layer & location buttons ─────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'layerToggle',
                  backgroundColor: Colors.white,
                  onPressed: () => setState(() => _isSatellite = !_isSatellite),
                  child: Icon(
                    _isSatellite
                        ? Icons.map_rounded
                        : Icons.satellite_alt_rounded,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'myLoc',
                  backgroundColor: Colors.white,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location_rounded,
                      color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),

          // ── Bottom confirm sheet ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 16)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.selectLocationTitle ??
                        'Selected Location',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          color: Colors.red, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoading
                            ? const Text('Fetching address...',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey))
                            : Text(
                                _selectedAddress ??
                                    (AppLocalizations.of(context)
                                            ?.fetchingStatus ??
                                        'Fetching...'),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _confirmLocation,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        AppLocalizations.of(context)
                                ?.confirmLocationButton ??
                            'Confirm Location',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
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
}
