import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

/// Publishes the delivery driver's live location to Firestore.
/// Writes: latitude, longitude, speed, heading, accuracy, isOnline, updatedAt.
class DeliveryLocationUpdater {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<LocationData>? _locationSub;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Starts streaming location updates to Firestore.
  Future<void> startSendingLocation() async {
    if (_isTracking) return; // prevent double-start

    try {
      // ── 1. GPS service ──
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          debugPrint("❌ Location service disabled");
          return;
        }
      }

      // ── 2. Permission ──
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          debugPrint("❌ Location permission denied");
          return;
        }
      }

      // ── 3. High-accuracy settings ──
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 3000,   // ms between updates
        distanceFilter: 5, // metres before a new update
      );

      debugPrint("✅ Location tracking started");
      _isTracking = true;

      // ── 4. Mark as online immediately ──
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection("delivery_locations").doc(uid).set(
        {"isOnline": true, "updatedAt": FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      // ── 5. Listen to location changes ──
      _locationSub = _location.onLocationChanged.listen(
        (loc) async {
          if (loc.latitude == null || loc.longitude == null) return;

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;

          try {
            await _firestore
                .collection("delivery_locations")
                .doc(uid)
                .set({
              "latitude": loc.latitude,
              "longitude": loc.longitude,
              "speed": loc.speed ?? 0.0,          // m/s
              "heading": loc.heading ?? 0.0,       // degrees
              "accuracy": loc.accuracy ?? 0.0,     // metres
              "altitude": loc.altitude ?? 0.0,
              "isOnline": true,
              "updatedAt": FieldValue.serverTimestamp(),
            });
            debugPrint(
                "📍 ${loc.latitude!.toStringAsFixed(5)}, ${loc.longitude!.toStringAsFixed(5)}"
                " | ${((loc.speed ?? 0) * 3.6).toStringAsFixed(1)} km/h");
          } catch (e) {
            debugPrint("❌ Firestore write error: $e");
          }
        },
        onError: (e) => debugPrint("❌ Location stream error: $e"),
      );
    } catch (e) {
      debugPrint("❌ startSendingLocation error: $e");
      _isTracking = false;
    }
  }

  /// Stops tracking and marks driver offline in Firestore.
  Future<void> stopLocationTracking() async {
    _isTracking = false;
    await _locationSub?.cancel();
    _locationSub = null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection("delivery_locations").doc(uid).set({
        "isOnline": false,
        "speed": 0.0,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("🛑 Location tracking stopped");
    } catch (e) {
      debugPrint("❌ Error stopping tracking: $e");
    }
  }
}
