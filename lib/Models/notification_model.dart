import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for notifications that can be acted upon (e.g., clicked to navigate)
abstract class LinkableNotification {
  String? get routePath;
  Map<String, dynamic>? get routeArgs;
}

/// Abstract base class for all application notifications
abstract class BaseNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? orderId;
  final String? productId;

  BaseNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.orderId,
    this.productId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': isRead,
    'type': type,
    if (orderId != null) 'orderId': orderId,
    if (productId != null) 'productId': productId,
  };

  factory BaseNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'system';
    
    switch (type) {
      case 'match':
        return MatchNotification.fromFirestore(doc);
      case 'activity':
        return ActivityNotification.fromFirestore(doc);
      default:
        return SystemNotification.fromFirestore(doc);
    }
  }
}

/// Specialized notification for product matches
class MatchNotification extends BaseNotification implements LinkableNotification {
  MatchNotification({
    required super.id,
    required super.title,
    required super.message,
    required super.timestamp,
    super.isRead,
    super.productId,
    super.orderId,
  }) : super(type: 'match');

  @override
  String? get routePath => '/product_details';

  @override
  Map<String, dynamic>? get routeArgs => {'productId': productId, 'orderId': orderId};

  factory MatchNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      productId: data['productId'],
      orderId: data['orderId'],
    );
  }
}

/// Specialized notification for user activities
class ActivityNotification extends BaseNotification {
  ActivityNotification({
    required super.id,
    required super.title,
    required super.message,
    required super.timestamp,
    super.isRead,
    super.orderId,
    super.productId,
  }) : super(type: 'activity');

  factory ActivityNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      orderId: data['orderId'],
      productId: data['productId'],
    );
  }
}

/// General system notification
class SystemNotification extends BaseNotification {
  SystemNotification({
    required super.id,
    required super.title,
    required super.message,
    required super.timestamp,
    super.isRead,
    super.orderId,
    super.productId,
  }) : super(type: 'system');

  factory SystemNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SystemNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      orderId: data['orderId'],
      productId: data['productId'],
    );
  }
}

// Keep the old name as an alias for backward compatibility if needed, 
// but it's better to update references.
typedef AppNotification = BaseNotification;

