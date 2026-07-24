import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../User Credential/usermodel.dart';
import '../Vendors View/WantedProductModel.dart';
import '../Models/notification_model.dart';
import '../Farmers View/Sell_Item_Model.dart';

class UserLand {
  final String id;
  final String name;
  final double size; // hectares
  final String soilType;
  final String? activeCrop;
  final int currentDay;
  final double growthProgress;
  final double moisture;
  final double nutrients;
  final double health;
  final List<Map<String, dynamic>> customActivities;
  final DateTime updatedAt;

  UserLand({
    required this.id,
    required this.name,
    required this.size,
    required this.soilType,
    this.activeCrop,
    this.currentDay = 1,
    this.growthProgress = 0.0,
    this.moisture = 0.5,
    this.nutrients = 0.5,
    this.health = 1.0,
    this.customActivities = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'soilType': soilType,
    'activeCrop': activeCrop,
    'currentDay': currentDay,
    'growthProgress': growthProgress,
    'moisture': moisture,
    'nutrients': nutrients,
    'health': health,
    'customActivities': customActivities,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserLand.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserLand(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Plot',
      size: (data['size'] ?? 1.0).toDouble(),
      soilType: data['soilType'] ?? 'Loamy',
      activeCrop: data['activeCrop'],
      currentDay: data['currentDay'] ?? 1,
      growthProgress: (data['growthProgress'] ?? 0.0).toDouble(),
      moisture: (data['moisture'] ?? 0.5).toDouble(),
      nutrients: (data['nutrients'] ?? 0.5).toDouble(),
      health: (data['health'] ?? 1.0).toDouble(),
      customActivities: List<Map<String, dynamic>>.from(
        (data['customActivities'] ?? []).map((v) {
          final map = Map<String, dynamic>.from(v);
          map['isCompleted'] ??= false;
          return map;
        }),
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FarmPersistenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _landsCollection => 
    _firestore.collection('users').doc(_userId).collection('user_lands');

  Future<void> saveLand(UserLand land) async {
    if (_userId == null) return;
    await _landsCollection.doc(land.id.isEmpty ? null : land.id).set(land.toJson(), SetOptions(merge: true));
  }

  Stream<List<UserLand>> streamUserLands() {
    if (_userId == null) return Stream.value([]);
    return _landsCollection.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => UserLand.fromFirestore(doc)).toList()
    );
  }

  Future<void> deleteLand(String landId) async {
    if (_userId == null) return;
    await _landsCollection.doc(landId).delete();
  }

  // --- Wanted Products (Vendor Requests) ---
  
  CollectionReference get _wantedProductsCollection => 
    _firestore.collection('wanted_products');

  Future<void> saveWantedProduct(WantedProduct request) async {
    final docId = request.id.isEmpty ? _firestore.collection('wanted_products').doc().id : request.id;
    final finalRequest = WantedProduct(
      id: docId,
      productName: request.productName,
      category: request.category,
      quantityNeeded: request.quantityNeeded,
      vendorId: request.vendorId,
      vendorName: request.vendorName,
      location: request.location,
      createdAt: request.createdAt,
      isMet: request.isMet,
    );
    await _firestore.collection('wanted_products').doc(docId).set(finalRequest.toJson());
    await checkAndNotifyFarmers(finalRequest);
  }

  Stream<List<WantedProduct>> streamWantedProducts() {
    return _firestore.collection('wanted_products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => WantedProduct.fromFirestore(doc)).toList()
      );
  }

  Future<void> deleteWantedProduct(String id) async {
    await _firestore.collection('wanted_products').doc(id).delete();
  }

  // --- Notifications ---

  CollectionReference get _notificationsCollection => 
    _firestore.collection('users').doc(_userId).collection('notifications');

  Future<void> saveNotification(AppNotification notification) async {
    if (_userId == null) return;
    await _notificationsCollection.doc(notification.id.isEmpty ? null : notification.id).set(notification.toJson());
  }

  Stream<List<AppNotification>> streamNotifications() {
    if (_userId == null) return Stream.value([]);
    return _notificationsCollection
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => 
        snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList()
      );
  }

  Future<void> markNotificationAsRead(String id) async {
    if (_userId == null) return;
    await _notificationsCollection.doc(id).update({'isRead': true});
  }

  Future<void> deleteNotification(String id) async {
    if (_userId == null) return;
    await _notificationsCollection.doc(id).delete();
  }

  // --- Matching Logic ---

  Future<void> checkAndNotifyMatches(AgriculturalItem listedItem) async {
    try {
      final snapshot = await _firestore.collection('wanted_products').get();
      final wantedProducts = snapshot.docs.map((doc) => WantedProduct.fromFirestore(doc)).toList();

      for (var wanted in wantedProducts) {
        bool nameMatch = listedItem.name.toLowerCase().contains(wanted.productName.toLowerCase()) || 
                         wanted.productName.toLowerCase().contains(listedItem.name.toLowerCase());
        
        bool categoryMatch = listedItem.category.toLowerCase() == wanted.category.toLowerCase();

        if (nameMatch || categoryMatch) {
          final notification = MatchNotification(
            id: "",
            title: "Product Match Found! 🌾",
            message: "A farmer just listed ${listedItem.name}, which matches your request!",
            timestamp: DateTime.now(),
            isRead: false,
          );

          await _firestore
              .collection('users')
              .doc(wanted.vendorId)
              .collection('notifications')
              .add(notification.toJson());
        }
      }
    } catch (e) {
      print("❌ Error in checkAndNotifyMatches: $e");
    }
  }

  Future<void> checkAndNotifyFarmers(WantedProduct wanted) async {
    try {
      final snapshot = await _firestore.collection('agricultural_items').get();
      final items = snapshot.docs.map((doc) => AgriculturalItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

      for (var item in items) {
        bool nameMatch = item.name.toLowerCase().contains(wanted.productName.toLowerCase()) || 
                         wanted.productName.toLowerCase().contains(item.name.toLowerCase());
        
        bool categoryMatch = item.category.toLowerCase() == wanted.category.toLowerCase();

        if (nameMatch || categoryMatch) {
          final notification = MatchNotification(
            id: "",
            title: "High Demand Alert! 💰",
            message: "A vendor is looking for ${wanted.productName}. This is a great chance for profit!",
            timestamp: DateTime.now(),
            isRead: false,
          );

          await _firestore
              .collection('users')
              .doc(item.sellerId)
              .collection('notifications')
              .add(notification.toJson());
        }
      }
    } catch (e) {
      print("❌ Error in checkAndNotifyFarmers: $e");
    }
  }

  // --- Trusted Farmers & Nearby Vendors ---

  Future<List<UserModel>> getTrustedFarmers() async {
    try {
      final snapshot = await _firestore
          .collection('Usersstore')
          .where('userType', isEqualTo: 'farmer')
          .get();

      final farmers = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data == null) continue;
          final map = Map<String, dynamic>.from(data);
          final user = UserModel.fromMap(map);
          if (user.rating >= 4.0) farmers.add(user);
        } catch (_) {
          // Skip docs that don't match UserModel shape (e.g. missing dates)
        }
      }
      farmers.sort((a, b) => b.rating.compareTo(a.rating));
      return farmers;
    } catch (e) {
      print("❌ Error fetching trusted farmers: $e");
      return [];
    }
  }

  Future<List<UserModel>> getNearbyVendors() async {
    try {
      final snapshot = await _firestore
          .collection('Usersstore')
          .where('userType', isEqualTo: 'vendor')
          .get();

      final list = <UserModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data == null) continue;
          list.add(UserModel.fromMap(Map<String, dynamic>.from(data)));
        } catch (_) {
          // Skip docs that don't match UserModel shape
        }
      }
      return list;
    } catch (e) {
      print("❌ Error fetching nearby vendors: $e");
      return [];
    }
  }
}
