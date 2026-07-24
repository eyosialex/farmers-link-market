import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String productId;
  final String productName;
  final String vendorId;
  final String vendorName;
  final String sellerId;
  final String sellerName;
  final int quantity;
  final double totalPrice;
  final String paymentMethod; // "COD" or "Bank Transfer"
  final String transactionStatus; // "Pending Payment", "Awaiting Verification", "Payment Verified", "Pending Delivery", "In Transit", "Delivered", "Cancelled"
  final bool isPaid;
  final String? paymentProofUrl;
  final bool deliveryAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pickupAddress;
  final String? dropoffAddress;
  final Map<String, double>? pickupLocation;
  final Map<String, double>? dropoffLocation;
  final String? driverId;
  final String? driverName;
  final String? paymentReferenceCode;
  final bool isSuspicious;
  final String? suspiciousReason;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String productUnit;
  final String? productImage;
  final String? productCategory;

  OrderModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.vendorId,
    required this.vendorName,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    required this.totalPrice,
    required this.paymentMethod,
    this.transactionStatus = "Pending Payment",
    this.isPaid = false,
    this.paymentProofUrl,
    this.deliveryAvailable = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLocation,
    this.dropoffLocation,
    this.driverId,
    this.driverName,
    this.paymentReferenceCode,
    this.isSuspicious = false,
    this.suspiciousReason,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.productUnit = 'kg',
    this.productImage,
    this.productCategory,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'productName': productName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'transactionStatus': transactionStatus,
      'isPaid': isPaid,
      'paymentProofUrl': paymentProofUrl,
      'deliveryAvailable': deliveryAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'driverId': driverId,
      'driverName': driverName,
      'paymentReferenceCode': paymentReferenceCode,
      'isSuspicious': isSuspicious,
      'suspiciousReason': suspiciousReason,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'productUnit': productUnit,
      'productImage': productImage,
      'productCategory': productCategory,
    };
  }

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'COD',
      transactionStatus: data['transactionStatus'] ?? 'Pending Payment',
      isPaid: data['isPaid'] ?? false,
      paymentProofUrl: data['paymentProofUrl'],
      deliveryAvailable: data['deliveryAvailable'] ?? false,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      pickupAddress: data['pickupAddress'],
      dropoffAddress: data['dropoffAddress'],
      pickupLocation: data['pickupLocation'] != null ? Map<String, double>.from(data['pickupLocation']) : null,
      dropoffLocation: data['dropoffLocation'] != null ? Map<String, double>.from(data['dropoffLocation']) : null,
      driverId: data['driverId'],
      driverName: data['driverName'],
      paymentReferenceCode: data['paymentReferenceCode'],
      isSuspicious: data['isSuspicious'] ?? false,
      suspiciousReason: data['suspiciousReason'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      accountName: data['accountName'],
      productCategory: data['productCategory'],
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
