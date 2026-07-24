import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for users that can be displayed in a profile
abstract class Profileable {
  String get displayName;
  String? get infoSummary;
  String? get avatarUrl;
}

/// Abstract base class for all application users
abstract class UserModel implements Profileable {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String userType;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final DateTime? lastseen;
  final String? photoUrl;
  final double rating;
  final int ratingCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.userType,
    this.profileCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.lastseen,
    this.photoUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  @override
  String get displayName => fullName;

  @override
  String? get avatarUrl => photoUrl;

  Map<String, dynamic> toMap();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final type = map['userType'] ?? '';
    switch (type) {
      case 'farmer':
        return FarmerUser.fromMap(map);
      case 'vendor':
        return VendorUser.fromMap(map);
      default:
        // Use generic user for advisor, delivery, shopper, etc.
        return GenericAppUser.fromMap(map);
    }
  }

  static DateTime _dateFromMap(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

/// Specialized model for users with generic metadata (e.g., Advisors, Shoppers)
class GenericAppUser extends UserModel {
  GenericAppUser({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    required super.userType,
    super.profileCompleted,
    required super.createdAt,
    required super.updatedAt,
    super.isOnline,
    super.lastseen,
    super.photoUrl,
    super.rating,
    super.ratingCount,
  });

  @override
  String? get infoSummary => "Role: ${userType.toUpperCase()}";

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'profileCompleted': profileCompleted,
      'isOnline': isOnline,
      'lastseen': lastseen != null ? Timestamp.fromDate(lastseen!) : null,
      'photoUrl': photoUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GenericAppUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? userType,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    DateTime? lastseen,
    String? photoUrl,
    double? rating,
    int? ratingCount,
  }) {
    return GenericAppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastseen: lastseen ?? this.lastseen,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  factory GenericAppUser.fromMap(Map<String, dynamic> map) {
    return GenericAppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      userType: map['userType'] ?? 'shopper',
      profileCompleted: map['profileCompleted'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastseen: map['lastseen'] != null ? (map['lastseen'] as Timestamp).toDate() : null,
      photoUrl: map['photoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: UserModel._dateFromMap(map['createdAt']),
      updatedAt: UserModel._dateFromMap(map['updatedAt']),
    );
  }
}


/// Specialized model for Farmer users
class FarmerUser extends UserModel {
  final String? farmName;
  final String? farmLocation;
  final String? farmSize;
  final String? crops;

  FarmerUser({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    this.farmName,
    this.farmLocation,
    this.farmSize,
    this.crops,
    super.profileCompleted,
    required super.createdAt,
    required super.updatedAt,
    super.isOnline,
    super.lastseen,
    super.photoUrl,
    super.rating,
    super.ratingCount,
  }) : super(userType: 'farmer');

  @override
  String? get infoSummary => farmName ?? 'No Farm Name';

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'farmName': farmName,
      'farmLocation': farmLocation,
      'farmSize': farmSize,
      'crops': crops,
      'profileCompleted': profileCompleted,
      'isOnline': isOnline,
      'lastseen': lastseen != null ? Timestamp.fromDate(lastseen!) : null,
      'photoUrl': photoUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FarmerUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? farmName,
    String? farmLocation,
    String? farmSize,
    String? crops,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    DateTime? lastseen,
    String? photoUrl,
    double? rating,
    int? ratingCount,
  }) {
    return FarmerUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      farmSize: farmSize ?? this.farmSize,
      crops: crops ?? this.crops,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastseen: lastseen ?? this.lastseen,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  factory FarmerUser.fromMap(Map<String, dynamic> map) {
    return FarmerUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      farmName: map['farmName'],
      farmLocation: map['farmLocation'],
      farmSize: map['farmSize'],
      crops: map['crops'],
      profileCompleted: map['profileCompleted'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastseen: map['lastseen'] != null ? (map['lastseen'] as Timestamp).toDate() : null,
      photoUrl: map['photoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: UserModel._dateFromMap(map['createdAt']),
      updatedAt: UserModel._dateFromMap(map['updatedAt']),
    );
  }
}

/// Specialized model for Vendor users
class VendorUser extends UserModel {
  final String? businessName;
  final String? businessType;
  final String? contactPerson;
  final String? businessAddress;
  final String? products;

  VendorUser({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    this.businessName,
    this.businessType,
    this.contactPerson,
    this.businessAddress,
    this.products,
    super.profileCompleted,
    required super.createdAt,
    required super.updatedAt,
    super.isOnline,
    super.lastseen,
    super.photoUrl,
    super.rating,
    super.ratingCount,
  }) : super(userType: 'vendor');

  @override
  String? get infoSummary => businessName ?? 'No Business Name';

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'businessName': businessName,
      'businessType': businessType,
      'contactPerson': contactPerson,
      'businessAddress': businessAddress,
      'products': products,
      'profileCompleted': profileCompleted,
      'isOnline': isOnline,
      'lastseen': lastseen != null ? Timestamp.fromDate(lastseen!) : null,
      'photoUrl': photoUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VendorUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? businessName,
    String? businessType,
    String? contactPerson,
    String? businessAddress,
    String? products,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    DateTime? lastseen,
    String? photoUrl,
    double? rating,
    int? ratingCount,
  }) {
    return VendorUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      contactPerson: contactPerson ?? this.contactPerson,
      businessAddress: businessAddress ?? this.businessAddress,
      products: products ?? this.products,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastseen: lastseen ?? this.lastseen,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  factory VendorUser.fromMap(Map<String, dynamic> map) {
    return VendorUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      businessName: map['businessName'],
      businessType: map['businessType'],
      contactPerson: map['contactPerson'],
      businessAddress: map['businessAddress'],
      products: map['products'],
      profileCompleted: map['profileCompleted'] ?? false,
      isOnline: map['isOnline'] ?? false,
      lastseen: map['lastseen'] != null ? (map['lastseen'] as Timestamp).toDate() : null,
      photoUrl: map['photoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      createdAt: UserModel._dateFromMap(map['createdAt']),
      updatedAt: UserModel._dateFromMap(map['updatedAt']),
    );
  }
}
