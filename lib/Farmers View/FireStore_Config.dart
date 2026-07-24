import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Models/order_model.dart';
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'agricultural_items';
  Future<String?> addAgriculturalItem(AgriculturalItem item) async {
    try {
      if (item.id != null) {
        // Use the existing ID to prevent duplicates
        await _firestore
            .collection(_collectionName)
            .doc(item.id)
            .set(item.toJson(), SetOptions(merge: true));
        return item.id;
      } else {
        // Create a new ID
        DocumentReference docRef = await _firestore
            .collection(_collectionName)
            .add(item.toJson());
        print('Item saved to Firestore with ID: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      print('Firestore error: $e');
      return null;
    }
  }

  Future<bool> updateAgriculturalItem(String docId, AgriculturalItem item) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(docId)
          .update(item.toJson());
      return true;
    } catch (e) {
      print('Firestore update error: $e');
      return false;
    }
  }

  Stream<List<AgriculturalItem>> getAgriculturalItems() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgriculturalItem.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<AgriculturalItem?> getAgriculturalItem(String docId) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection(_collectionName)
          .doc(docId)
          .get();
      
      if (snapshot.exists) {
        return AgriculturalItem.fromFirestore(
          snapshot.data() as Map<String, dynamic>,
          snapshot.id,
        );
      }
      return null;
    } catch (e) {
      print('Firestore get error: $e');
      return null;
    }
  }
  Future<void> deleteAgriculturalItem(String docId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(docId)
          .delete();
    } catch (e) {
      print('Firestore delete error: $e');
    }
  }

  // New specific methods
  Stream<List<AgriculturalItem>> getAgriculturalItemsBySeller(String sellerId) {
    return _firestore
        .collection(_collectionName)
        .where('sellerId', isEqualTo: sellerId)
        // Removed server-side orderBy to avoid creating a composite index
        // .orderBy('createdAt', descending: true) 
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AgriculturalItem.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort client-side instead
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> incrementProductView(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String userId = user.uid;

    try {
      DocumentReference docRef = _firestore.collection(_collectionName).doc(productId);
      
      // Use a transaction to check if user already viewed
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) return;
        
        List<dynamic> viewedBy = snapshot.get('viewedBy') ?? [];
        
        if (!viewedBy.contains(userId)) {
          transaction.update(docRef, {
            'viewedBy': FieldValue.arrayUnion([userId]),
            'views': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      print('Error incrementing view: $e');
    }
  }

  Future<void> toggleProductLike(String productId, String userId) async {
    try {
      DocumentReference docRef = _firestore.collection(_collectionName).doc(productId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) return;
        
        List<dynamic> likedBy = snapshot.get('likedBy') ?? [];
        
        if (likedBy.contains(userId)) {
          // Unlike
           transaction.update(docRef, {
            'likedBy': FieldValue.arrayRemove([userId]),
            'likes': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.update(docRef, {
            'likedBy': FieldValue.arrayUnion([userId]),
            'likes': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      print('Error updating like: $e');
    }
  }

  Future<bool> updateProductStock(String productId, int newQuantity) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(productId)
          .update({
            'quantity': newQuantity,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      print('Firestore stock update error: $e');
      return false;
    }
  }

  // --- ORDER MANAGEMENT METHODS ---

  Future<String?> createOrder(OrderModel order) async {
    try {
      return await _firestore.runTransaction<String?>((transaction) async {
        // 1. Get current product stock
        DocumentReference productRef = _firestore.collection(_collectionName).doc(order.productId);
        DocumentSnapshot productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw Exception("Product no longer available");
        }

        int currentStock = (productSnap.get('quantity') ?? 0).toInt();
        if (currentStock < order.quantity) {
          throw Exception("Insufficient stock (Available: $currentStock)");
        }

        // 2. Create Order document
        DocumentReference orderRef = _firestore.collection('orders').doc();
        
        final String refCode = _generateReferenceCode();
        
        Map<String, dynamic> orderData = order.toJson();
        orderData['id'] = orderRef.id;
        orderData['paymentReferenceCode'] = refCode;
        
        // Snap bank info from product if available
        if (productSnap.data() != null) {
          final pData = productSnap.data() as Map<String, dynamic>;
          orderData['bankName'] = pData['bankName'];
          orderData['accountNumber'] = pData['accountNumber'];
          orderData['accountName'] = pData['accountName'];
        }
        
        transaction.set(orderRef, orderData);

        // 3. Decrement Product stock
        transaction.update(productRef, {
          'quantity': currentStock - order.quantity,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return orderRef.id;
      }).then((orderId) async {
        if (orderId != null) {
          // 4. Send notification (outside transaction is fine)
          await _sendNotification(
            userId: order.sellerId,
            title: "New Order Received! 📦",
            message: "Vendor ${order.vendorName} committed to buy ${order.productName}.",
            type: "system",
            orderId: orderId,
            productId: order.productId,
          );
        }
        return orderId;
      });
    } catch (e) {
      print('Firestore createOrder Transaction error: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus, {bool isPaid = false, String? paymentProofUrl}) async {
    try {
      Map<String, dynamic> updates = {
        'transactionStatus': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (isPaid) updates['isPaid'] = true;
      if (paymentProofUrl != null) updates['paymentProofUrl'] = paymentProofUrl;

      await _firestore.collection('orders').doc(orderId).update(updates);

      // --- NOTIFICATIONS ---
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return true;

      String vendorId = orderDoc.get('vendorId');
      String prodName = orderDoc.get('productName');
      String? ref = (orderDoc.data() as Map<String, dynamic>?)?['paymentReferenceCode'];

      if (newStatus == "Payment Verified") {
        await _sendNotification(
          userId: vendorId,
          title: "Payment Verified! ✅",
          message: "The farmer has verified your payment for $prodName. Arrangement for delivery is underway.",
          type: "system",
          orderId: orderId,
        );
      } else if (newStatus == "Ready for Pickup") {
        await _sendNotification(
          userId: vendorId,
          title: "Order Ready! 📦",
          message: "Great news! Your order of $prodName is packed and ready for the driver.",
          type: "system",
          orderId: orderId,
        );
      } else if (newStatus == "Verification Issue") {
        await _sendNotification(
          userId: vendorId,
          title: "Payment Issue ⚠️",
          message: "The farmer reported an issue verifying your payment for $prodName (Ref: $ref). Please check your proof or chat with the farmer.",
          type: "security",
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      print('Firestore updateOrderStatus error: $e');
      return false;
    }
  }

  Stream<List<OrderModel>> getOrdersByVendor(String vendorId) {
    return _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<OrderModel>> getOrdersBySeller(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<OrderModel>> getAvailableDeliveryOrders({String? currentDriverId}) {
    return _firestore
        .collection('orders')
        .where('transactionStatus', isEqualTo: 'Ready for Pickup') 
        .snapshots()
        .map((snapshot) {
          final allReady = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
          
          // Filter on client side to show:
          // 1. Orders with no driver assigned (Public)
          // 2. Orders specifically assigned to THIS driver (Private)
          return allReady.where((order) {
            return order.driverId == null || order.driverId == currentDriverId;
          }).toList();
        });
  }

  Stream<List<OrderModel>> getOrdersByDriver(String driverId, {String? status}) {
    Query query = _firestore.collection('orders').where('driverId', isEqualTo: driverId);
    if (status != null) {
      query = query.where('transactionStatus', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // --- NEW: DRIVER ASSIGNMENT ---

  Future<bool> acceptOrderDelivery(String orderId, String driverId, String driverName) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'driverId': driverId,
        'driverName': driverName,
        'transactionStatus': 'In Transit',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Notify vendor and farmer
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        String vendorId = orderDoc.get('vendorId');
        String sellerId = orderDoc.get('sellerId');
        String prodName = orderDoc.get('productName');

        String msg = "Driver $driverName has accepted the delivery of $prodName and is in transit.";
        
        await _sendNotification(userId: vendorId, title: "Order Shipped! 🚚", message: msg, type: "system", orderId: orderId);
        await _sendNotification(userId: sellerId, title: "Driver Assigned 🚜", message: msg, type: "system", orderId: orderId);
      }

      return true;
    } catch (e) {
      print('Firestore acceptOrderDelivery error: $e');
      return false;
    }
  }

  Future<bool> markOrderAsSuspicious(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'transactionStatus': 'Verification Issue',
        'isSuspicious': true,
        'suspiciousReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      return updateOrderStatus(orderId, 'Verification Issue');
    } catch (e) {
      print('Error marking order suspicious: $e');
      return false;
    }
  }

  String _generateReferenceCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars 1, I, 0, O
    final random = DateTime.now().microsecondsSinceEpoch;
    String res = 'LF-';
    for (int i = 0; i < 4; i++) {
      res += chars[(random >> (i * 5)) % chars.length];
    }
    return res;
  }

  Future<bool> completeOrderDelivery(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'transactionStatus': 'Delivered',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Notify vendor and farmer
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        String vendorId = orderDoc.get('vendorId');
        String sellerId = orderDoc.get('sellerId');
        String prodName = orderDoc.get('productName');

        await _sendNotification(
          userId: vendorId,
          title: "Order Delivered! 🎁",
          message: "Your order for $prodName has been successfully delivered.",
          type: "system",
          orderId: orderId,
        );
        await _sendNotification(
          userId: sellerId,
          title: "Sale Completed! 💰",
          message: "The delivery for $prodName is complete. The transaction is closed.",
          type: "system",
          orderId: orderId,
        );
      }

      return true;
    } catch (e) {
      print('Firestore completeOrderDelivery error: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
        DocumentSnapshot orderSnap = await transaction.get(orderRef);

        if (!orderSnap.exists) return false;
        
        String status = orderSnap.get('transactionStatus');
        if (status != 'Pending Payment' && status != 'Awaiting Verification') {
          // Cannot cancel if already verified or in transit
          return false;
        }

        int qty = (orderSnap.get('quantity') ?? 0).toInt();
        String productId = orderSnap.get('productId');
        String sellerId = orderSnap.get('sellerId');

        // 1. Mark order as Cancelled
        transaction.update(orderRef, {
          'transactionStatus': 'Cancelled',
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // 2. Return stock to product
        DocumentReference productRef = _firestore.collection(_collectionName).doc(productId);
        transaction.update(productRef, {
          'quantity': FieldValue.increment(qty),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      }).then((success) async {
        if (success) {
          // Notify farmer
          DocumentSnapshot orderSnap = await _firestore.collection('orders').doc(orderId).get();
          String sellerId = orderSnap.get('sellerId');
          String prodName = orderSnap.get('productName');
          await _sendNotification(
            userId: sellerId,
            title: "Order Cancelled 🛑",
            message: "The vendor has cancelled their order for $prodName. Stock has been returned.",
            type: "system",
            orderId: orderId,
          );
        }
        return success;
      });
    } catch (e) {
      print('Firestore cancelOrder error: $e');
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
        DocumentSnapshot orderSnap = await transaction.get(orderRef);

        if (!orderSnap.exists) return false;

        int qty = (orderSnap.get('quantity') ?? 0).toInt();
        String productId = orderSnap.get('productId');
        String vendorId = orderSnap.get('vendorId');

        // 1. Mark order as Rejected
        transaction.update(orderRef, {
          'transactionStatus': 'Rejected',
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // 2. Return stock to product
        DocumentReference productRef = _firestore.collection(_collectionName).doc(productId);
        transaction.update(productRef, {
          'quantity': FieldValue.increment(qty),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return true;
      }).then((success) async {
        if (success) {
          // Notify vendor
          DocumentSnapshot orderSnap = await _firestore.collection('orders').doc(orderId).get();
          String vendorId = orderSnap.get('vendorId');
          String prodName = orderSnap.get('productName');
          await _sendNotification(
            userId: vendorId,
            title: "Purchase Rejected ⚠️",
            message: "The farmer could not fulfill your order for $prodName. Any manual payments should be discussed with the farmer.",
            type: "system",
            orderId: orderId,
          );
        }
        return success;
      });
    } catch (e) {
      print('Firestore rejectOrder error: $e');
      return false;
    }
  }

  // --- HELPER: SEND NOTIFICATION ---

  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? orderId,
    String? productId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': type,
            if (orderId != null) 'orderId': orderId,
            if (productId != null) 'productId': productId,
          });
    } catch (e) {
      print('Error sending notification to $userId: $e');
    }
  }
}
