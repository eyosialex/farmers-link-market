import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Vendors%20View/Map_Location_Calculatore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkedfarm/Chat/chat_screen.dart';
import 'package:linkedfarm/Models/order_model.dart';
import 'package:location/location.dart';
import 'package:linkedfarm/Services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'package:linkedfarm/Farmers%20View/Position_Sell_Item.dart';

// Product List Screen - Shows all products
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<AgriculturalItem>> _productsStream;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'Cereals',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Spices',
    'Coffee',
    'Oil Seeds',
    'Tubers',
    'Livestock',
    'Fertilizers',
    'Pesticides',
    'Herbicides',
    'Fungicides',
    'Machinery',
    'Others'
  ];
  
  String _selectedCategory = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initCombinedStream();
  }

  void _initCombinedStream() {
    // We combine the Firestore stream with a local Hive check
    _productsStream = _firestoreService.getAgriculturalItems().map((firestoreItems) {
      final localStorage = Provider.of<LocalStorageService>(context, listen: false);
      final localItems = localStorage.getAllProducts();
      
      // Merge: Prioritize Firestore items, but add unique local items (received via P2P or pending sync)
      final merged = [...firestoreItems];
      final firestoreIds = firestoreItems.map((e) => e.id).toSet();
      
      for (var localItem in localItems) {
        if (!firestoreIds.contains(localItem.id)) {
          merged.add(localItem);
        }
      }
      
      // Sort by creation date
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    });
  }

  // Filter products based on search and category
  List<AgriculturalItem> _filterProducts(List<AgriculturalItem> products) {
    return products.where((product) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      // Category filter
      final matchesCategory = _selectedCategory.isEmpty || 
          product.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Navigate to chat with seller
  void _navigateToChat(AgriculturalItem product, BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Check if user is logged in
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to chat with seller'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Check if user is trying to chat with themselves
    if (currentUser.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Navigate to chat screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChattMessage(
    //       receiverEmail: product.sellerName,
    //       receiverId: product.sellerId,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.orange[700],
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : '';
                      });
                    },
                  ),
                );
              },
            ),
          ),
          if (_selectedCategory.isNotEmpty || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Filters: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedCategory.isNotEmpty)
                    Chip(
                      label: Text('Category: $_selectedCategory'),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = '';
                        });
                      },
                    ),
                  if (_searchQuery.isNotEmpty)
                    Chip(
                      label: Text('Search: "$_searchQuery"'),
                      onDeleted: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = '';
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<AgriculturalItem>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No products available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                final allProducts = snapshot.data!;
                final filteredProducts = _filterProducts(allProducts);

                // Show message if no products match filters
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = '';
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 0.6,
                  ),
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(AgriculturalItem product, BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSeller = currentUser?.uid == product.sellerId;
    final isLiked = currentUser != null && product.likedBy.contains(currentUser.uid);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Colors.grey[100],
                    ),
                    child: (product.localImagePaths != null && product.localImagePaths!.isNotEmpty) ||
                            (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: (product.localImagePaths != null && product.localImagePaths!.isNotEmpty)
                                ? getImageFromFile(product.localImagePaths!.first)
                                : Image.network(
                                    product.imageUrls!.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
                                  ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                  // Favorite Button
                    Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                           if (currentUser != null) {
                             _firestoreService.toggleProductLike(product.id!, currentUser.uid);
                           } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Please login to like items")),
                             );
                           }
                        },
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey, 
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                      ),
                    ),
                  ),
                  // Stock Status Badge
                  if (product.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.outOfStock.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (product.isLowStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.lowStock,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Product Info Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Category and Price Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.price} ETB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: isSeller 
                              ? null 
                              : () => _navigateToChat(product, context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSeller ? Colors.grey[300] : Colors.green[50],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSeller ? Colors.grey[400]! : Colors.green[100]!
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: isSeller ? Colors.grey[600] : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating and Location Row
                    Row(
                      children: [
                        // Stars
                        Row(
                          children: List.generate(
                            4,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        // Location
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                size: 14,
                                color: isSeller ? Colors.grey : Colors.green[600],
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${product.views} views',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSeller ? Colors.grey : Colors.black,
                                    fontWeight: isSeller ? FontWeight.normal : FontWeight.bold
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Additional Info Row
                    Row(
                      children: [
                        _buildInfoItem(Icons.inventory_2, '${product.quantity} ${product.unit}'),
                        const SizedBox(width: 12),
                        _buildInfoItem(Icons.verified, product.condition),
                      ],
                    ),
                    if (product.isOutOfStock)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Wait for restock',
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Product Detail Screen - Shows single product details
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AgriculturalItem? _item;
  bool _isLoading = true;
  String _errorMessage = '';
  LatLng? productLocation;
  
  // Delivery drivers data
  List<Map<String, dynamic>> _nearbyDrivers = [];
  bool _loadingDrivers = false;

  // Delivery logistics
  Map<String, double>? _dropoffLocation;
  String? _dropoffAddress;
  String? _selectedDriverId;
  String? _selectedDriverName;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final item = await _firestoreService.getAgriculturalItem(widget.productId);
      if (item != null) {
        // Increment view count since we successfully loaded it
        // Firestore service now safely checks for duplicates using arrayUnion
        await _firestoreService.incrementProductView(widget.productId);
        
        setState(() {
          _item = item;
          // Parse location from the map
          if (item.location != null && 
              item.location!['lat'] != null && 
              item.location!['lng'] != null) {
            productLocation = LatLng(
              item.location!['lat']!,
              item.location!['lng']!,
            );
            // Load nearby drivers when product location is available
            _loadNearbyDrivers(item.location!['lat']!, item.location!['lng']!);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading product: $e';
        _isLoading = false;
      });
    }
  }

  // Load nearby delivery drivers
  Future<void> _loadNearbyDrivers(double productLat, double productLng) async {
    setState(() {
      _loadingDrivers = true;
    });

    try {
      final driversSnapshot = await _firestore
          .collection("delivery_locations")
          .where("isOnline", isEqualTo: true)
          .get();

      List<Map<String, dynamic>> nearbyDrivers = [];

      for (var driverDoc in driversSnapshot.docs) {
        final driverData = driverDoc.data();
        final driverLat = driverData['latitude']?.toDouble();
        final driverLng = driverData['longitude']?.toDouble();

        if (driverLat != null && driverLng != null) {
          // Calculate distance from driver to product
          final distance = LocationUtils.calculateDistance(
            productLat, productLng, driverLat, driverLng
          );

          // Only show drivers within 50km radius
          if (distance <= 5000000000000) {
            // Get driver details from users collection
            final userDoc = await _firestore
                .collection("Usersstore")
                .doc(driverDoc.id)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data()!;
              nearbyDrivers.add({
                'id': driverDoc.id,
                'name': userData['fullName'] ?? 'Unknown Driver',
                'distance': distance,
                'latitude': driverLat,
                'longitude': driverLng,
                'vehicleType': userData['cartype'] ?? 'Unknown Vehicle',
                'rating': userData['rating']?.toDouble() ?? 0.0,
                'lastUpdate': driverData['updatedAt'],
              });
            }
          }
        }
      }

      // Sort by distance (nearest first)
      nearbyDrivers.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _nearbyDrivers = nearbyDrivers;
        _loadingDrivers = false;
      });

    } catch (e) {
      print('Error loading nearby drivers: $e');
      setState(() {
        _loadingDrivers = false;
      });
    }
  }

  void _showLocationOnMap() {
    if (productLocation != null && _item != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedProductLocationMapScreen(
            productLat: productLocation!.latitude,
            productLng: productLocation!.longitude,
            productName: _item!.name,
            drivers: _nearbyDrivers,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location data not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Navigate to chat with seller
  void _navigateToChat() {
    if (_item == null) return;
    
    final currentUser = _auth.currentUser;
    
    // Check if user is logged in
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to chat with seller'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Check if user is trying to chat with themselves
    if (currentUser.uid == _item!.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Navigate to chat screen
    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          receiverUserEmail: _item!.sellerName, // We use name as email label for now
          receiverUserID: _item!.sellerId,
        ),
      ),
    );
  }

  void _shareProduct() {
    if (_item == null) return;
    
    // Implement share functionality
    final shareText = 'Check out ${_item!.name} - ${_item!.price} ETB';
    // You can use packages like share_plus for sharing
  }

  void _showOrderDialog(AgriculturalItem item) {
    int quantity = 1;
    String paymentMethod = 'Bank Transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PLACE YOUR ORDER", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A34))),
              const SizedBox(height: 8),
              Text("Product: ${item.name}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 24),
              const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text("$quantity ${item.unit}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: quantity < item.quantity ? () => setModalState(() => quantity++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _paymentOptionTile("Manual Bank Transfer", "Upload screenshot of bank transfer", Icons.account_balance_outlined, "Bank Transfer", paymentMethod, (val) => setModalState(() => paymentMethod = val)),
              
              if (item.deliveryAvailable) ...[
                const SizedBox(height: 24),
                const Text("Select Delivery Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapTestScreen(
                          onLocationSelected: (lat, lng, address) {
                            setModalState(() {
                              _dropoffLocation = {'lat': double.parse(lat), 'lng': double.parse(lng)};
                              _dropoffAddress = address;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_dropoffAddress ?? "Tap to pin dropoff location",
                              style: TextStyle(color: _dropoffAddress == null ? Colors.grey : Colors.black, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_nearbyDrivers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text("Select Preffered Driver (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearbyDrivers.length,
                      itemBuilder: (context, idx) {
                        final driver = _nearbyDrivers[idx];
                        bool isSelected = _selectedDriverId == driver['id'];
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            if (isSelected) {
                              _selectedDriverId = null;
                              _selectedDriverName = null;
                            } else {
                              _selectedDriverId = driver['id'];
                              _selectedDriverName = driver['name'];
                            }
                          }),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFF2D5A42) : Colors.grey[200]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFF2D5A42),
                                  child: const Icon(Icons.person, size: 15, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(driver['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text("${(driver['distance'] / 1000).toStringAsFixed(1)}km", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showManualPaymentDialog(item, quantity);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A42),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("CONTINUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOptionTile(String title, String sub, IconData icon, String value, String current, Function(String) onChanged) {
    bool isSelected = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2D5A42) : Colors.grey[200]!, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2D5A42) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF1E3A34) : Colors.black87)),
                  Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2D5A42)),
          ],
        ),
      ),
    );
  }

  void _showManualPaymentDialog(AgriculturalItem item, int quantity) {
    File? selectedImage;
    bool isUploading = false;
    final CloudinaryService cloudinaryService = CloudinaryService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Bank Transfer Details"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Please transfer total amount to:"),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Transfer to Farmer:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue[900])),
                      const SizedBox(height: 8),
                      _bankRow(Icons.account_balance, "Bank: ${item.bankName ?? 'Contact Farmer'}"),
                      _bankRow(Icons.numbers, "A/C: ${item.accountNumber ?? 'Contact Farmer'}"),
                      _bankRow(Icons.person, "Name: ${item.accountName ?? 'Contact Farmer'}"),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount:", style: TextStyle(fontSize: 12)),
                          Text("ETB ${item.price * quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Upload Screenshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                if (selectedImage != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: isUploading ? null : () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => selectedImage = File(pickedFile.path));
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(selectedImage == null ? "Select Screenshot" : "Change Screenshot"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: isUploading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: (selectedImage == null || isUploading) ? null : () async {
                  setState(() => isUploading = true);
                  
                  String? uploadedUrl = await cloudinaryService.uploadImage(selectedImage!, folder: 'payment_proofs');
                  
                  if (uploadedUrl != null) {
                    Navigator.pop(context);
                    _confirmPurchase(item, quantity, "Bank Transfer", proofUrl: uploadedUrl);
                  } else {
                    setState(() => isUploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to upload screenshot. Please try again.")),
                    );
                  }
                },
                child: const Text("Confirm Transfer"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmPurchase(AgriculturalItem item, int quantity, String method, {String? proofUrl}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final order = OrderModel(
      productId: item.id!,
      productName: item.name,
      vendorId: user.uid,
      vendorName: user.displayName ?? "Vendor",
      sellerId: item.sellerId,
      sellerName: item.sellerName,
      quantity: quantity,
      totalPrice: item.price * quantity,
      paymentMethod: method,
      transactionStatus: "Awaiting Verification",
      isPaid: false,
      paymentProofUrl: proofUrl,
      deliveryAvailable: item.deliveryAvailable,
      pickupAddress: item.address,
      pickupLocation: item.location,
      dropoffAddress: _dropoffAddress,
      dropoffLocation: _dropoffLocation,
      driverId: _selectedDriverId,
      driverName: _selectedDriverName,
      productUnit: item.unit,
      productImage: item.imageUrls != null && item.imageUrls!.isNotEmpty ? item.imageUrls!.first : null,
      productCategory: item.category,
    );

    setState(() => _isLoading = true);
    final orderId = await _firestoreService.createOrder(order);
    setState(() => _isLoading = false);

    if (orderId != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Purchase Confirmed!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(method == "COD" 
                ? "The driver will be notified for pickup." 
                : "Awaiting farmer verification of your payment."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to list
              },
              child: const Text("Awesome"),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    if (_item == null) {
      return _buildErrorScreen(message: 'Product not found');
    }

    return _buildProductDetailScreen(_item!);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading...'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading product details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen({String? message}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message ?? _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProduct,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailScreen(AgriculturalItem item) {
    final currentUser = _auth.currentUser;
    final isSeller = currentUser?.uid == item.sellerId;
    final priceFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            _buildImageSection(item),
            const SizedBox(height: 20),

            // Basic Info
            _buildBasicInfoSection(item, priceFormatter),
            const SizedBox(height: 20),

            // Description
            _buildDescriptionSection(item),
            const SizedBox(height: 20),

            // Seller Info
            _buildSellerInfoSection(item, isSeller),
            const SizedBox(height: 20),

            // Location with Delivery Drivers
            _buildLocationSection(item),
            const SizedBox(height: 20),

            // Additional Details
            _buildAdditionalDetailsSection(item, dateFormatter),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(item, isSeller),
    );
  }

  Widget _buildImageSection(AgriculturalItem item) {
    final localPaths = item.localImagePaths ?? const <String>[];
    final remoteUrls = item.imageUrls ?? const <String>[];
    final hasLocal = localPaths.isNotEmpty;
    final hasRemote = remoteUrls.isNotEmpty;

    return SizedBox(
      height: 250,
      child: hasLocal || hasRemote
          ? PageView.builder(
              itemCount: hasLocal ? localPaths.length : remoteUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasLocal
                        ? getImageFromFile(localPaths[index])
                        : Image.network(
                            remoteUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Failed to load image'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                );
              },
            )
          : Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No images available'),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection(AgriculturalItem item, NumberFormat priceFormatter) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(item.category, Icons.category, Colors.blue),
                if (item.subcategory != null && item.subcategory!.isNotEmpty)
                  _buildInfoChip(item.subcategory!, Icons.subtitles, Colors.green),
                _buildInfoChip(item.condition, Icons.flare_sharp, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        priceFormatter.format(item.price),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.stock,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: item.isOutOfStock ? Colors.red : Colors.grey[600],
                            ),
                      ),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: item.isOutOfStock ? Colors.red : Colors.black87,
                            ),
                      ),
                      if (item.isLowStock)
                        Text(
                          AppLocalizations.of(context)!.lowStock,
                          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: Icon(icon, size: 16, color: Colors.white),
      backgroundColor: color.withOpacity(0.8),
      labelStyle: const TextStyle(color: Colors.white),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDescriptionSection(AgriculturalItem item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfoSection(AgriculturalItem item, bool isSeller) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                item.sellerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              trailing: IconButton(
                onPressed: _navigateToChat,
                icon: Icon(Icons.message, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(AgriculturalItem item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Location",
                  style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_nearbyDrivers.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          "${_nearbyDrivers.length} drivers nearby",
                          style: TextStyle(fontSize: 12, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (item.address != null && item.address!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                   const Icon(Icons.place, size: 16, color: Colors.grey),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       item.address!,
                       style: const TextStyle(
                         fontSize: 15,
                         color: Colors.black87,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
                ],
              ),
            ),

          if (productLocation != null)
            SizedBox(
              height: 300,
              child: Column(
                children: [
                  // Map Section
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: productLocation!,
                              initialZoom: 12,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.linkedfarm.app',
                              ),
                              MarkerLayer(
                                markers: _buildMapMarkers(),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: FloatingActionButton.small(
                              onPressed: _showLocationOnMap,
                              child: const Icon(Icons.fullscreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delivery Drivers List Section
                  if (_nearbyDrivers.isNotEmpty)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text(
                                  'Nearby Delivery Drivers',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  '${_nearbyDrivers.length} available',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildDriversList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Location not available'),
                  ],
                ),
              ),
            ),

          // Show loading or empty state for drivers
          if (_loadingDrivers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_nearbyDrivers.isEmpty && productLocation != null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_sharp, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No delivery drivers available nearby',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMapMarkers() {
    List<Marker> markers = [];

    // Product marker
    if (productLocation != null && _item != null) {
      markers.add(
        Marker(
          point: productLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      );
    }

    // Delivery driver markers
    for (int i = 0; i < _nearbyDrivers.length; i++) {
      final driver = _nearbyDrivers[i];
      markers.add(
        Marker(
          point: LatLng(driver['latitude'], driver['longitude']),
          width: 32,
          height: 32,
          child: const Icon(Icons.local_shipping, color: Colors.green, size: 30),
        ),
      );
    }

    return markers;
  }

  Widget _buildDriversList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8),
      itemCount: _nearbyDrivers.length,
      itemBuilder: (context, index) {
        final driver = _nearbyDrivers[index];
        return Container(
          width: 200,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.green),
            ),
            title: Text(
              driver['name'],
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${driver['distance'].toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  driver['vehicleType'],
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (driver['rating'] > 0)
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        driver['rating'].toStringAsFixed(1),
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showDriverDetails(driver);
            },
          ),
        );
      },
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delivery Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.green),
              ),
              title: Text(
                driver['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(driver['vehicleType']),
            ),
            SizedBox(height: 16),
            _buildDriverDetailRow(Icons.location_on, 'Distance', '${driver['distance'].toStringAsFixed(1)} km away'),
            _buildDriverDetailRow(Icons.speed, 'Status', 'Available for delivery'),
            if (driver['rating'] > 0)
              _buildDriverDetailRow(Icons.star, 'Rating', driver['rating'].toStringAsFixed(1)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement contact driver functionality
            },
            child: Text('Contact Driver'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsSection(AgriculturalItem item, DateFormat dateFormatter) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Additional Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Available From', 
                item.availableFrom != null 
                    ? dateFormatter.format(item.availableFrom!)
                    : 'Immediately'),
            _buildDetailRow(Icons.local_shipping, 'Delivery', 
                item.deliveryAvailable ? 'Available' : 'Not Available'),
            _buildDetailRow(Icons.date_range, 'Listed On', 
                dateFormatter.format(item.createdAt)),
            if (item.tags != null && item.tags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.tags!
                    .map((tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[200],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar(AgriculturalItem item, bool isSeller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ETB ${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    '${item.quantity} ${item.unit} available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _navigateToChat,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                child: Icon(item.isOutOfStock ? Icons.notification_add : Icons.chat, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: isSeller
                  ? ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This is your own product'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person),
                      label: const Text(
                        'Your Item',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: item.isOutOfStock ? null : () => _showOrderDialog(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isOutOfStock ? Colors.grey : const Color(0xFF2D5A42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        item.isOutOfStock ? 'OUT OF STOCK' : 'COMMIT TO BUY',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// Enhanced Full Screen Map with Delivery Drivers
class EnhancedProductLocationMapScreen extends StatefulWidget {
  final double productLat;
  final double productLng;
  final String productName;
  final List<Map<String, dynamic>> drivers;

  const EnhancedProductLocationMapScreen({
    Key? key,
    required this.productLat,
    required this.productLng,
    required this.productName,
    required this.drivers,
  }) : super(key: key);

  @override
  State<EnhancedProductLocationMapScreen> createState() => _EnhancedProductLocationMapScreenState();
}

class _EnhancedProductLocationMapScreenState extends State<EnhancedProductLocationMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _productLocation;

  @override
  void initState() {
    super.initState();
    _productLocation = LatLng(widget.productLat, widget.productLng);
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Product marker
    markers.add(
      Marker(
        point: _productLocation!,
        width: 45,
        height: 45,
        child: const Icon(Icons.location_on, color: Colors.blue, size: 45),
      ),
    );

    // Delivery driver markers
    for (int i = 0; i < widget.drivers.length; i++) {
      final driver = widget.drivers[i];
      markers.add(
        Marker(
          point: LatLng(driver['latitude'], driver['longitude']),
          width: 35,
          height: 35,
          child: const Icon(Icons.local_shipping, color: Colors.green, size: 35),
        ),
      );
    }

    return markers;
  }

  void _zoomToProduct() {
     _mapController.move(_productLocation!, 14);
  }

  void _showAllMarkers() {
    if (_productLocation != null && widget.drivers.isNotEmpty) {
      final bounds = _calculateBounds();
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  LatLngBounds _calculateBounds() {
    List<LatLng> points = [_productLocation!];
    for (final driver in widget.drivers) {
      points.add(LatLng(driver['latitude'], driver['longitude']));
    }
    return LatLngBounds.fromPoints(points);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.productName} - Delivery Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _zoomToProduct,
            tooltip: 'Zoom to Product',
          ),
          if (widget.drivers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _showAllMarkers,
              tooltip: 'Show All Drivers',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _productLocation!,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.linkedfarm.app',
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          
          // Drivers info panel
          if (widget.drivers.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '${widget.drivers.length} Delivery Drivers Nearby',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Blue marker: Product | Green markers: Delivery drivers',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

// Delivery Location Updater
class DeliveryLocationUpdater {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> startSendingLocation() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;  
      
      // 1️⃣ Check GPS service
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print("❌ Location service disabled");
          return;
        }
      }
      
      // 2️⃣ Check permission
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print("❌ Location permission denied");
          return;
        }
      }  
      
      print("✅ Location permissions granted, starting tracking...");
      
      // 3️⃣ Start listening to location changes
      _location.onLocationChanged.listen((loc) async {
        if (loc.latitude == null || loc.longitude == null) {
          print("⚠️ Invalid location data received");
          return;
        }
        
        final uid = FirebaseAuth.instance.currentUser!.uid;
        try {
          await _firestore.collection("delivery_locations").doc(uid).set({
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "updatedAt": DateTime.now(),
            "isOnline": true,
          });
          print("📍 Location updated: ${loc.latitude}, ${loc.longitude}");
        } catch (e) {
          print("❌ Error updating location: $e");
        }
      }, onError: (error) {
        print("❌ Location listener error: $error");
      });
      
    } catch (e) {
      print("❌ Error in startSendingLocation: $e");
    }
  }
}

// Available Drivers Page
class AvailableDriversPage extends StatefulWidget {
  @override
  State<AvailableDriversPage> createState() => _AvailableDriversPageState();
}

class _AvailableDriversPageState extends State<AvailableDriversPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available Delivery Drivers")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Usersstore")
            .where("userType", isEqualTo: "delivery")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final drivers = snapshot.data!.docs;

          if (drivers.isEmpty) {
            return Center(child: Text("No delivery drivers available"));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveLocationPage(driverId: driver.id),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        SizedBox(width: 12),         
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver["fullName"],
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Car: ${driver["cartype"]}",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Address: ${driver["adress"]}",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Driver License: ${driver["deriving licence"]}",
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.location_pin, color: Colors.redAccent, size: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Live Location Page
class LiveLocationPage extends StatefulWidget {
  final String driverId;
  
  LiveLocationPage({required this.driverId});
  
  @override
  _LiveLocationPageState createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  final MapController _mapController = MapController();
  LatLng? currentPos;

  @override
  void initState() {
    super.initState();
    listenToDriverLocation();
  }

  // LISTEN TO FIRESTORE LIVE UPDATES
  void listenToDriverLocation() {
    FirebaseFirestore.instance
        .collection("delivery_locations")
        .doc(widget.driverId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      if (data["latitude"] == null || data["longitude"] == null) {
        return;
      }
      setState(() {
        currentPos = LatLng(data["latitude"], data["longitude"]);
      });
      // Move map to new location
      _mapController.move(currentPos!, 16);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Location")),
      body: currentPos == null
          ? const Center(child: Text("Waiting for driver location..."))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPos!,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.linkedfarm.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPos!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// Location Service
class LocationService {
  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // get request permission 
  Future<bool> requestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }
  
  // Save location to Firestore
  Future<void> updateLocationToFirestore(String userId, LocationData loc) async {
    await _firestore.collection("live_locations").doc(userId).set({
      "lat": loc.latitude,
      "lng": loc.longitude,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }
  
  // Get current location
  Future<LocationData?> getLocations() async {
    bool ok = await requestPermission();
    if (!ok) return null;
    return await _location.getLocation();
  }

  // Listen for real-time location
  Stream<LocationData> onLocationChanged() {
    return _location.onLocationChanged;
  }
}
