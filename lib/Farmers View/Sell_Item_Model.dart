import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

part 'Sell_Item_Model.g.dart';

@HiveType(typeId: 0)
class AgriculturalItem extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? subcategory;

  @HiveField(4)
  String description;

  @HiveField(5)
  double price;

  @HiveField(6)
  int quantity;

  @HiveField(7)
  String unit;

  @HiveField(8)
  String condition;

  @HiveField(9)
  List<String>? imageUrls;

  @HiveField(10)
  Map<String, double>? location;

  @HiveField(11)
  String? address;

  @HiveField(12)
  String sellerName;

  @HiveField(13)
  String sellerId;

  @HiveField(14)
  String contactInfo;

  @HiveField(15)
  DateTime? availableFrom;

  @HiveField(16)
  bool deliveryAvailable;

  @HiveField(17)
  List<String>? tags;

  @HiveField(18)
  DateTime createdAt;

  @HiveField(19)
  DateTime updatedAt;

  @HiveField(20)
  int likes;

  @HiveField(21)
  int views;

  @HiveField(22)
  List<String> likedBy;

  @HiveField(23)
  List<String> viewedBy;

  @HiveField(24)
  bool isSynced;

  @HiveField(25)
  List<String>? localImagePaths;

  @HiveField(26)
  String? bankName;

  @HiveField(27)
  String? accountNumber;

  @HiveField(28)
  String? accountName;

  AgriculturalItem({
    this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.description,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.condition,
    this.imageUrls,
    this.localImagePaths,
    required this.location,
    this.address,
    required this.sellerName,
    required this.sellerId,
    required this.contactInfo,
    this.availableFrom,
    this.deliveryAvailable = false,
    this.tags,
    this.likes = 0,
    this.views = 0,
    this.likedBy = const [],
    this.viewedBy = const [],
    this.isSynced = false,
    this.bankName,
    this.accountNumber,
    this.accountName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'condition': condition,
      'imageUrls': imageUrls,
      'localImagePaths': localImagePaths,
      'location': location,
      'address': address,
      'sellerName': sellerName,
      'sellerId': sellerId,
      'contactInfo': contactInfo,
      'availableFrom': availableFrom?.toIso8601String(),
      'deliveryAvailable': deliveryAvailable,
      'tags': tags,
      'likes': likes,
      'views': views,
      'likedBy': likedBy,
      'viewedBy': viewedBy,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
  }

  factory AgriculturalItem.fromFirestore(Map<String, dynamic> data, String documentId) {
    Map<String, dynamic> locData = data['location'] ?? {'lat': 0.0, 'lng': 0.0};

    return AgriculturalItem(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      unit: data['unit'] ?? 'kg',
      condition: data['condition'] ?? 'Fresh',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      localImagePaths: data['localImagePaths'] != null ? List<String>.from(data['localImagePaths']) : null,
      location: {
        'lat': (locData['lat'] ?? 0.0).toDouble(),
        'lng': (locData['lng'] ?? 0.0).toDouble(),
      },
      address: data['address'],
      sellerName: data['sellerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      availableFrom: data['availableFrom'] != null
          ? DateTime.parse(data['availableFrom'])
          : null,
      deliveryAvailable: data['deliveryAvailable'] ?? false,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      likes: (data['likes'] ?? 0).toInt(),
      views: (data['views'] ?? 0).toInt(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      isSynced: data['isSynced'] ?? true,
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      accountName: data['accountName'],
    );
  }

  AgriculturalItem copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? description,
    double? price,
    int? quantity,
    String? unit,
    String? condition,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    Map<String, double>? location,
    String? address,
    String? sellerName,
    String? sellerId,
    String? contactInfo,
    DateTime? availableFrom,
    bool? deliveryAvailable,
    List<String>? tags,
    int? likes,
    int? views,
    List<String>? likedBy,
    List<String>? viewedBy,
    bool? isSynced,
    String? bankName,
    String? accountNumber,
    String? accountName,
  }) {
    return AgriculturalItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      location: location ?? this.location,
      address: address ?? this.address,
      sellerName: sellerName ?? this.sellerName,
      sellerId: sellerId ?? this.sellerId,
      contactInfo: contactInfo ?? this.contactInfo,
      availableFrom: availableFrom ?? this.availableFrom,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      likedBy: likedBy ?? this.likedBy,
      viewedBy: viewedBy ?? this.viewedBy,
      isSynced: isSynced ?? this.isSynced,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isAvailable {
    if (availableFrom == null) return true;
    return DateTime.now().isAfter(availableFrom!);
  }

  bool get isOutOfStock => quantity == 0;
  
  bool get isLowStock => quantity > 0 && quantity <= 5;

  String get formattedPrice {
    return 'ETB $price per $unit';
  }

  String get locationString {
    if (location == null) return 'Location not specified';
    return 'Lat: ${location!['lat']?.toStringAsFixed(4)}, Lng: ${location!['lng']?.toStringAsFixed(4)}';
  }

  bool get isCurrentUserSeller {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == sellerId;
  }
}
