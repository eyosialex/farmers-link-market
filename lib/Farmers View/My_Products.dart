import 'package:linkedfarm/Farmers%20View/Enter_Sell_Item.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:linkedfarm/Services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:universal_io/io.dart';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _navigateToEdit(AgriculturalItem product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellItem(productToEdit: product),
      ),
    );
  }

  Future<void> _deleteProduct(AgriculturalItem product) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductConfirm(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteAgriculturalItem(product.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productDeletedSuccess)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.somethingWentWrong}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.loginToViewProducts)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProductsTitle),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AgriculturalItem>>(
        stream: _firestoreService.getAgriculturalItemsBySeller(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noProductsListed,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SellItem()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.listFirstProductButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(AgriculturalItem product) {
    return Semantics(
      label: "${product.name}, price ${product.price} ETB, stock ${product.quantity} ${product.unit}",
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                // Fixed: Use abstraction to handle platform specific image loading
                child: (product.localImagePaths != null && product.localImagePaths!.isNotEmpty)
? getImageFromFile(product.localImagePaths![0])
                    : (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                        ? Image.network(
                            product.imageUrls![0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      ContextMenuButton(product),
                      Text(
                    product.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (product.address != null && product.address!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.address!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price} ETB',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stock Management Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  product.quantity > 0 ? Icons.inventory_2 : Icons.warning_amber_rounded,
                                  size: 16,
                                  color: product.isOutOfStock 
                                      ? Colors.red 
                                      : product.isLowStock ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.stockLevel(product.quantity, product.unit),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: product.isOutOfStock 
                                        ? Colors.red 
                                        : product.isLowStock ? Colors.orange : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (product.isOutOfStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.outOfStock,
                                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (product.isLowStock)
                              Text(
                                AppLocalizations.of(context)!.lowStock,
                                style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStockButton(
                              icon: Icons.remove,
                              label: "Decrease stock",
                              onTap: product.quantity > 0 
                                  ? () => _updateStock(product, product.quantity - 1)
                                  : null,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '${product.quantity}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 20),
                            _buildStockButton(
                              icon: Icons.add,
                              label: "Increase stock",
                              onTap: () => _updateStock(product, product.quantity + 1),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats
                  Row(
                    children: [
                      _buildStatChip(Icons.remove_red_eye_outlined, AppLocalizations.of(context)!.viewsLabel(product.views), Colors.green, "Total views: ${product.views}"),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.favorite_outline, AppLocalizations.of(context)!.likesLabel(product.likes), Colors.red, "Total likes: ${product.likes}"),
                      const Spacer(),
                      _buildStatChip(
                        product.isSynced ? Icons.cloud_done : Icons.cloud_off, 
                        product.isSynced ? AppLocalizations.of(context)!.synced : AppLocalizations.of(context)!.offline, 
                        product.isSynced ? Colors.green : Colors.orange,
                        product.isSynced ? "Product is synced to cloud" : "Product is stored locally only"
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget ContextMenuButton(AgriculturalItem product) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _navigateToEdit(product);
        } else if (value == 'delete') {
          _deleteProduct(product);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.green),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.editAction),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.deleteAction),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color, String semanticsLabel) {
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockButton({required IconData icon, required String label, required VoidCallback? onTap, required Color color}) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: onTap == null ? Colors.grey : color),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: onTap == null ? Colors.grey : color,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStock(AgriculturalItem product, int newQuantity) async {
    if (product.id == null) return;
    
    // Optimistic UI update approach would be better but let's do direct for now
    final success = await _firestoreService.updateProductStock(product.id!, newQuantity);
    
    if (success) {
      // Local sync if using Hive but the Consumer should rebuild if the list comes from Firestore stream
      // Actually MyProductsScreen uses Consumer<LocalStorageService> which might not see Firestore changes immediately unless synced.
      // But the seller usually manages their own items which are in localStorage.
      
      // final localStorage = Provider.of<LocalStorageService>(context, listen: false);
      // final updatedProduct = product.copyWith(quantity: newQuantity);
      // await localStorage.saveProduct(updatedProduct);
      
      _showSnackBar(AppLocalizations.of(context)!.quantityUpdated);
    } else {
      _showSnackBar("Failed to update stock");
    }
  }
}
