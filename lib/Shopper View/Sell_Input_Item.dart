import 'dart:async';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:linkedfarm/Services/local_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Farmers%20View/Sell_Item_Model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:linkedfarm/Services/farm_persistence_service.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:linkedfarm/Farmers%20View/Position_Sell_Item.dart';
class SellInputItem extends StatefulWidget {
  final AgriculturalItem? productToEdit;

  const SellInputItem({super.key, this.productToEdit});

  @override
  State<SellInputItem> createState() => _SellInputItemState();
}

class _SellInputItemState extends State<SellInputItem> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // Variables
  String _selectedCategory = '';
  String _selectedCondition = 'Fresh';
  String _selectedUnit = 'kg';
  DateTime? _availableFrom;
  bool _deliveryAvailable = false;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _tags = [];
  bool _isUploading = false;
  Map<String, double>? _selectedLocation;
  String? _selectedAddress;
  
  // Services
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();
  final FarmPersistenceService _persistence = FarmPersistenceService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Product categories for agricultural inputs
  final List<String> _categories = [
    'Fertilizers', 'Pesticides', 'Herbicides', 'Fungicides', 'Others'
  ];

  final List<String> _conditions = ['Fresh', 'Dry', 'Organic', 'Processed', 'Frozen'];
  final List<String> _units = ['kg', 'quintal', 'ton', 'sack', 'piece', 'liter'];

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'Cereals': return l10n.catCereals;
      case 'Pulses': return l10n.catPulses;
      case 'Vegetables': return l10n.catVegetables;
      case 'Fruits': return l10n.catFruits;
      case 'Spices': return l10n.catSpices;
      case 'Coffee': return l10n.catCoffee;
      case 'Oil Seeds': return l10n.catOilSeeds;
      case 'Tubers': return l10n.catTubers;
      case 'Livestock': return l10n.catLivestock;
      case 'Fertilizers': return l10n.catFertilizer;
      case 'Pesticides': return l10n.catPesticide;
      case 'Herbicides': return l10n.catHerbicide;
      case 'Fungicides': return l10n.catFungicide;
      default: return l10n.catOthers;
    }
  }

  String _getLocalizedCondition(BuildContext context, String condition) {
    final l10n = AppLocalizations.of(context)!;
    switch (condition) {
      case 'Fresh': return l10n.condFresh;
      case 'Dry': return l10n.condDry;
      case 'Organic': return l10n.condOrganic;
      case 'Processed': return l10n.condProcessed;
      case 'Frozen': return l10n.condFrozen;
      default: return condition;
    }
  }

  String _getLocalizedUnit(BuildContext context, String unit) {
    final l10n = AppLocalizations.of(context)!;
    switch (unit) {
      case 'kg': return l10n.unitKg;
      case 'quintal': return l10n.unitQuintal;
      case 'ton': return l10n.unitTon;
      case 'sack': return l10n.unitSack;
      case 'piece': return l10n.unitPiece;
      case 'liter': return l10n.unitLiter;
      default: return unit;
    }
  }

  @override
  void initState() {
    super.initState();
    _availableFrom = DateTime.now();
    if (widget.productToEdit != null) {
      _loadProductData();
    } else {
      _loadCurrentUserInfo();
    }
  }

  void _loadProductData() {
    final product = widget.productToEdit!;
    _nameController.text = product.name;
    _selectedCategory = _categories.contains(product.category) ? product.category : '';
    _subcategoryController.text = product.subcategory ?? '';
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _quantityController.text = product.quantity.toString();
    _selectedUnit = _units.contains(product.unit) ? product.unit : _units.first;
    _selectedCondition = _conditions.contains(product.condition) ? product.condition : _conditions.first;
    _existingImageUrls = List.from(product.imageUrls ?? []);
    
    if (product.location != null) {
      _selectedLocation = product.location;
      _selectedAddress = product.address;
      locationController.text = product.address ?? "Location Selected";
    }
    
    _sellerNameController.text = product.sellerName;
    _contactInfoController.text = product.contactInfo;
    _availableFrom = product.availableFrom;
    _deliveryAvailable = product.deliveryAvailable;
    _tags = List.from(product.tags ?? []);
    if (product.tags != null) {
      _tagsController.text = ""; 
    }
  }

  void _loadCurrentUserInfo() {
    final user = _auth.currentUser;
    if (user != null) {
      // Pre-fill seller name with user's display name if available
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _sellerNameController.text = user.displayName!;
      }
      
      // Pre-fill contact info with user's email
      if (user.email != null) {
        _contactInfoController.text = user.email!;
      }
    }
  }

  // Image Picker Methods
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
        _showSnackBar(AppLocalizations.of(context)!.photoAddedSuccess);
      }
    } catch (e) {
      _showSnackBar("${AppLocalizations.of(context)!.errorTakingPhoto}: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
        _showSnackBar("${pickedFiles.length} ${AppLocalizations.of(context)!.photoAddedSuccess}");
      }
    } catch (e) {
      _showSnackBar("${AppLocalizations.of(context)!.errorSelectingImages}: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _showSnackBar(AppLocalizations.of(context)!.photoRemoved);
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
    _showSnackBar(AppLocalizations.of(context)!.photoRemoved);
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addPhotosTitle),
        content: Text(AppLocalizations.of(context)!.chooseImageSource),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.cameraAction),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.galleryAction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onLocationSelected(String latitude, String longitude, String address) {
    setState(() {
      _selectedLocation = {
        'lat': double.parse(latitude),
        'lng': double.parse(longitude),
      };
      _selectedAddress = address;
      locationController.text = address; 
    });
    _showSnackBar(AppLocalizations.of(context)!.locationSelectedSuccess);
  }

  void _addTag() {
    if (_tagsController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagsController.text.trim());
        _tagsController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _availableFrom = pickedDate;
        });
      }
    });
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.enterProductName);
      return false;
    }
    if (_selectedCategory.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.selectCategory);
      return false;
    }
    if (_descriptionController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.enterProductDescription);
      return false;
    }
    if (_priceController.text.isEmpty || double.tryParse(_priceController.text) == null) {
      _showSnackBar(AppLocalizations.of(context)!.enterValidPrice);
      return false;
    }
    if (_quantityController.text.isEmpty || int.tryParse(_quantityController.text) == null) {
      _showSnackBar(AppLocalizations.of(context)!.enterValidQuantity);
      return false;
    }
    if (_selectedLocation == null) {
      _showSnackBar(AppLocalizations.of(context)!.selectLocation);
      return false;
    }
    if (_sellerNameController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.enterSellerName);
      return false;
    }
    if (_contactInfoController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.enterContactInfo);
      return false;
    }
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.addAtLeastOnePhoto);
      return false;
    }
    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      return;
    }

    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    // Show detailed loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.uploading),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.uploadingImagesCount(_selectedImages.length),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.takeAMoment,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      print('=== STARTING OFFLINE-FIRST UPLOAD PROCESS ===');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      // 1. Generate unique ID for deduplication
      final String itemId = widget.productToEdit?.id ?? 
                           "${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}";

      // 2. Prepare local image paths
      List<String> localPaths = _selectedImages.map((f) => f.path).toList();

      // 3. Create Item (Mark as unsynced initially)
      AgriculturalItem item = AgriculturalItem(
        id: itemId,
        name: _nameController.text,
        category: _selectedCategory,
        subcategory: _subcategoryController.text.isNotEmpty ? _subcategoryController.text : null,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        unit: _selectedUnit,
        condition: _selectedCondition,
        imageUrls: _existingImageUrls,
        localImagePaths: localPaths,
        location: _selectedLocation,
        address: _selectedAddress,
        sellerName: _sellerNameController.text,
        sellerId: widget.productToEdit?.sellerId ?? currentUser.uid,
        contactInfo: _contactInfoController.text,
        availableFrom: _availableFrom,
        deliveryAvailable: _deliveryAvailable,
        tags: _tags.isNotEmpty ? _tags : null,
        isSynced: false,
      );

      // 4. Save to Local Hive BOX first (Safety)
      final localStorage = Provider.of<LocalStorageService>(context, listen: false);
      await localStorage.saveProduct(item);
      print('📦 Saved locally to Hive: $itemId');

      // 5. Attempt Cloud Upload (Images + Firestore) if possible
      List<String> imageUrls = [];
      bool cloudSuccess = false;
      
      try {
        if (_selectedImages.isNotEmpty) {
          print('📸 Attempting image upload to Cloudinary...');
          imageUrls = await _cloudinaryService.uploadMultipleImages(_selectedImages);
        }
        
        if (imageUrls.isNotEmpty || _selectedImages.isEmpty) {
          final finalItem = item.copyWith(
            imageUrls: [..._existingImageUrls, ...imageUrls],
            isSynced: true,
          );
          
          final String? firestoreId = await _firestoreService.addAgriculturalItem(finalItem);
          if (firestoreId != null) {
            await localStorage.markAsSynced(itemId);
            cloudSuccess = true;
            print('✅ Successfully synced to cloud');
          }
        }
      } catch (e) {
        print('📶 Offline or Cloud error (saved locally): $e');
      }

      Navigator.pop(context); // Close loading dialog

      if (cloudSuccess) {
        _showSuccessMessage(item, imageUrls.length);
      } else {
        _showSnackBar(AppLocalizations.of(context)!.savedLocallySyncLater);
        _clearForm();
        Navigator.pop(context);
      }

    } catch (e) {
      Navigator.pop(context);
      print('❌ Error: $e');
      _showDetailedErrorDialog("Error", e.toString());
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper method for detailed error dialogs
  void _showDetailedErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.errorTitle),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.okAction),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitForm(); // Retry
            },
            child: Text(AppLocalizations.of(context)!.retryAction),
          ),
        ],
      ),
    );
  }

  // Success message to show image count
  void _showSuccessMessage(AgriculturalItem item, int imageCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("✅ ${AppLocalizations.of(context)!.successTitle}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.itemListedSuccess(item.name)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.imagesUploadedCloudinary(imageCount)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.itemLiveMarketplace),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: Text(AppLocalizations.of(context)!.addAnotherAction),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: Text(AppLocalizations.of(context)!.doneAction),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _categoryController.clear();
      _subcategoryController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _quantityController.clear();
      _selectedLocation = null;
      locationController.clear();
      _sellerNameController.clear();
      _contactInfoController.clear();
      _tagsController.clear();
      _selectedCategory = '';
      _selectedCondition = 'Fresh';
      _selectedUnit = 'kg';
      _availableFrom = DateTime.now();
      _deliveryAvailable = false;
      _existingImageUrls.clear();
      _selectedImages.clear();
      _tags.clear();
    });
    _loadCurrentUserInfo(); // Reload user info after clearing
    _showSnackBar(AppLocalizations.of(context)!.formCleared);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit != null 
          ? AppLocalizations.of(context)!.editProduct 
          : AppLocalizations.of(context)!.sellProduceAction),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Section
            _buildSectionHeader(AppLocalizations.of(context)!.productImagesTitle),
            const SizedBox(height: 8),
            
            if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _existingImageUrls.length + _selectedImages.length,
                itemBuilder: (context, index) {
                  if (index < _existingImageUrls.length) {
                    // Existing image
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(_existingImageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // New selected image
                  final newImageIndex = index - _existingImageUrls.length;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: getImageProviderFromFile(_selectedImages[newImageIndex].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(newImageIndex),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _selectedImages.isEmpty 
                    ? AppLocalizations.of(context)!.addPhotosTitle 
                    : AppLocalizations.of(context)!.addMorePhotos(_selectedImages.length),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            if (_selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.addClearPhotosHint,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),

            // Product Information Section
            _buildSectionHeader(AppLocalizations.of(context)!.productInformation),
            _buildTextField(_nameController, AppLocalizations.of(context)!.productNameLabel, Icons.shopping_basket),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.categoryLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(_getLocalizedCategory(context, category)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 12),

            _buildTextField(_subcategoryController, AppLocalizations.of(context)!.subcategoryOptional, Icons.subtitles),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.describeProductDetail,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.priceEtbLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: "0.00",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.quantityLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.scale),
                      hintText: "0",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.unitLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: _units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(_getLocalizedUnit(context, unit)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedUnit = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.conditionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: _conditions.map((String condition) {
                      return DropdownMenuItem<String>(
                        value: condition,
                        child: Text(_getLocalizedCondition(context, condition)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCondition = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Location Section
            _buildSectionHeader(AppLocalizations.of(context)!.locationTitle),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapTestScreen(
                      onLocationSelected: _onLocationSelected,
                    ),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.locationOnMap,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: AppLocalizations.of(context)!.tapToSelectLocation,
                    suffixIcon: _selectedAddress != null 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Seller Information Section
            _buildSectionHeader("Seller Information"),
            _buildTextField(_sellerNameController, "Seller Name *", Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_contactInfoController, "Contact Information *", Icons.phone),
            const SizedBox(height: 12),

            // Availability Section
            _buildSectionHeader("Availability"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showDatePicker,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Available From",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          hintText: _availableFrom?.toString().split(' ')[0] ?? "Select date",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilterChip(
                    label: Text(_deliveryAvailable ? "Delivery Available" : "No Delivery"),
                    selected: _deliveryAvailable,
                    onSelected: (bool selected) {
                      setState(() {
                        _deliveryAvailable = selected;
                      });
                    },
                    checkmarkColor: Colors.white,
                    selectedColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tags Section
            _buildSectionHeader("Tags (Optional)"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: "Add Tags",
                      border: OutlineInputBorder(),
                      hintText: "e.g., organic, premium, local",
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                  tooltip: "Add Tag",
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Display tags
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(_tags.length, (index) {
                  return Chip(
                    label: Text(_tags[index]),
                    onDeleted: () => _removeTag(index),
                    deleteIconColor: Colors.red,
                  );
                }),
              ),

            const SizedBox(height: 30),

            // Submit Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUploading ? Colors.grey : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Uploading..."),
                        ],
                      )
                    : const Text(
                        "List Product for Sale",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    locationController.dispose();
    _sellerNameController.dispose();
    _contactInfoController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
