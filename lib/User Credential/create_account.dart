import 'package:linkedfarm/Dlivery View/home_delivery.dart';
import 'package:linkedfarm/Advisor%20View/Advisor_Home.dart';
import 'package:linkedfarm/Farmers%20View/Farmers_Home.dart';
import 'package:linkedfarm/Vendors%20View/Product_Home.dart';
import 'package:linkedfarm/User%20Credential/userfirestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Shopper%20View/Shopper_Home.dart';
import 'log_in_page.dart';
class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});
  @override
  State<CreateAccount> createState() => _CreateAccountState();
}
class _CreateAccountState extends State<CreateAccount> {
  final UserRepository _userRepository = UserRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  int _currentStep = 0;

  // Form controllers for all user types
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmLocationController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();
  final TextEditingController _cropsController = TextEditingController();
  //form control for business or for the vendor
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _productsController = TextEditingController();
  
final TextEditingController _addreess=TextEditingController();
final TextEditingController _drivinglisence=TextEditingController();

final TextEditingController _cartype=TextEditingController();

final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Shopper Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _inputCategoriesController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("🔄 Loading user data for: ${user.uid}");
      final userData = await _userRepository.getUser(user.uid);
      if (userData != null) {
        setState(() {
          _userData = {
            'uid': userData.uid,
            'email': userData.email,
            'fullName': userData.fullName,
            'phoneNumber': userData.phoneNumber,
            'userType': userData.userType,
          };
        });
        print("✅ User data loaded: ${userData.fullName} - ${userData.userType}");
      } else {
        print("❌ No user data found in Firestore");
      }
    } else {
      print("❌ No user logged in");
    }
  }

  Future<void> _completeProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userNotLoggedIn)),
      );
      return;
    }

    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userDataNotFound)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> profileData = {};

      if (_userData!['userType'] == 'farmer') {
        profileData = {
          'farmName': _farmNameController.text.trim(),
          'farmLocation': _farmLocationController.text.trim(),
          'farmSize': _farmSizeController.text.trim(),
          'crops': _cropsController.text.trim(),
          'profileCompleted': true,
        };
      } else if (_userData!['userType'] == 'vendor') {
        profileData = {
          'businessName': _businessNameController.text.trim(),
          'businessType': _businessTypeController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'businessAddress': _businessAddressController.text.trim(),
          'products': _productsController.text.trim(),
          'profileCompleted': true,
        };
      } else if (_userData!['userType'] == 'delivery') {
        profileData = {
          'cartype': _cartype.text.trim(),
          'address': _addreess.text.trim(),
          'driving_license': _drivinglisence.text.trim(),
          'profileCompleted': true,
        };
      } else if (_userData!['userType'] == 'advisor') {
        profileData = {
          'specialization': _specializationController.text.trim(),
          'experience': _experienceController.text.trim(),
          'qualification': _qualificationController.text.trim(),
          'profileCompleted': true,
        };
      } else if (_userData!['userType'] == 'shopper') {
        profileData = {
          'shopName': _shopNameController.text.trim(),
          'shopAddress': _shopAddressController.text.trim(),
          'inputCategories': _inputCategoriesController.text.trim(),
          'profileCompleted': true,
        };
      }
      
      await _userRepository.completeUserProfile(user.uid, profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileCompletedSuccess),
          backgroundColor: Colors.green,
        ),
      );

      Widget targetPage;
      if (_userData!['userType'] == 'farmer') {
        targetPage = const FarmersHomePage();
      } else if (_userData!['userType'] == 'vendor') {
        targetPage = const vendors_page();
      } else if (_userData!['userType'] == 'delivery') {
        targetPage = const HomeDelivery();
      } else if (_userData!['userType'] == 'advisor') {
        targetPage = const AdvisorHomePage();
   
      } else {
        targetPage = const FarmersHomePage();
      }

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );

    } catch (e) {
      print("❌ Error completing profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.profileCompletedFailed}: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Step> _buildSteps() {
    if (_userData == null) {
      return [];
    }

    final userType = _userData!['userType'];
    
    if (userType == 'farmer') {
      return _buildFarmerSteps();
    } else if (userType == 'vendor') {
      return _buildVendorSteps();
    } else if (userType == 'delivery') {
      return _builddliverySteps();
    } else if (userType == 'advisor') {
      return _buildAdvisorSteps();
    } else if (userType == 'shopper') {
      return _buildShopperSteps();
    }
    return [];
  }

  List<Step>_builddliverySteps() {
    return [
      Step(
        title: Text(AppLocalizations.of(context)!.deliveryInfoTitle),
        content: Column(
          children: [
         
            const SizedBox(height: 15),
            TextField(
              controller:_addreess,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yourLocationLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cartype,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.carTypeLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller:_drivinglisence ,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.licenseIdLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context)!.reviewCompleteTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewInfoLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('${AppLocalizations.of(context)!.locationLabel} ${_addreess.text}'),
            Text('${AppLocalizations.of(context)!.licenseIdPrefix} ${_drivinglisence.text}'),
            Text('${AppLocalizations.of(context)!.carTypePrefix} ${_cartype.text}'),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.clickCompleteLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }


  List<Step> _buildFarmerSteps() {
    return [
      Step(
        title: Text(AppLocalizations.of(context)!.farmInfoTitle),
        content: Column(
          children: [
            TextField(
              controller: _farmNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.farmNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _farmLocationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.farmLocationLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _farmSizeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.farmSizeLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cropsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.cropsGrownLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.cropsHint,
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context)!.reviewCompleteTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewInfoLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('${AppLocalizations.of(context)!.farmNameLabel}: ${_farmNameController.text}'),
            Text('${AppLocalizations.of(context)!.farmLocationLabel}: ${_farmLocationController.text}'),
            Text('${AppLocalizations.of(context)!.farmSizeLabel}: ${_farmSizeController.text}'),
            Text('${AppLocalizations.of(context)!.cropsGrownLabel}: ${_cropsController.text}'),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.clickCompleteLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  List<Step> _buildVendorSteps() {
    return [
      Step(
        title: Text(AppLocalizations.of(context)!.businessInfoTitle),
        content: Column(
          children: [
            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.businessNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _businessTypeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.businessTypeLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.businessTypeHint,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contactPersonController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.contactPersonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _businessAddressController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.businessAddressLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _productsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.productsServicesLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.productsServicesHint,
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context)!.reviewCompleteTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewInfoLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('${AppLocalizations.of(context)!.businessNameLabel}: ${_businessNameController.text}'),
            Text('${AppLocalizations.of(context)!.businessTypeLabel}: ${_businessTypeController.text}'),
            Text('${AppLocalizations.of(context)!.contactPersonLabel}: ${_contactPersonController.text}'),
            Text('${AppLocalizations.of(context)!.businessAddressLabel}: ${_businessAddressController.text}'),
            Text('${AppLocalizations.of(context)!.productsServicesLabel}: ${_productsController.text}'),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.clickCompleteLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  List<Step> _buildAdvisorSteps() {
    return [
      Step(
        title: Text(AppLocalizations.of(context)!.professionalProfileTitle),
        content: Column(
          children: [
            TextField(
              controller: _specializationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.specializationLabel,
                hintText: AppLocalizations.of(context)!.specializationHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.experienceLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _qualificationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.qualificationLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context)!.reviewCompleteTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewInfoLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('${AppLocalizations.of(context)!.specializationLabel}: ${_specializationController.text}'),
            Text('${AppLocalizations.of(context)!.experienceLabel}: ${_experienceController.text}'),
            Text('${AppLocalizations.of(context)!.qualificationLabel}: ${_qualificationController.text}'),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.clickCompleteLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  List<Step> _buildShopperSteps() {
    return [
      Step(
        title: Text(AppLocalizations.of(context)!.shopperProfileSetup),
        content: Column(
          children: [
            TextField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: "Shop Name", // Fallback if L10n missing
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _shopAddressController,
              decoration: InputDecoration(
                labelText: "Shop Address",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _inputCategoriesController,
              decoration: InputDecoration(
                labelText: "Input Categories (Pesticides, Seeds, etc.)",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context)!.reviewCompleteTitle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewInfoLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text('Shop Name: ${_shopNameController.text}'),
            Text('Address: ${_shopAddressController.text}'),
            Text('Inputs: ${_inputCategoriesController.text}'),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.clickCompleteLabel,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  String _getUserTypeDisplay(BuildContext context) {
    if (_userData == null) return '';
    final l10n = AppLocalizations.of(context)!;
    
    switch (_userData!['userType']) {
      case 'farmer':
        return l10n.farmerProfileSetup;
      case 'vendor':
        return l10n.vendorProfileSetup;
      case 'advisor':
        return l10n.advisorProfileSetup;
      case 'shopper':
        return l10n.shopperProfileSetup;
      default:
        return l10n.defaultProfileSetup;
    }
  }

  IconData _getUserTypeIcon() {
    if (_userData == null) return Icons.person;
    
    switch (_userData!['userType']) {
      case 'farmer':
        return Icons.agriculture;
      case 'vendor':
        return Icons.business;
      case 'advisor':
        return Icons.school;
      case 'shopper':
        return Icons.shopping_basket;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.completeProfileTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LogInPage(onTap: (){})),
            );
          },
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _getUserTypeIcon(),
                              color: Colors.green[700],
                              size: 40,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.welcomeName(_userData!['fullName']),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getUserTypeDisplay(context),
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stepper
                    Expanded(
                      child: Stepper(
                        currentStep: _currentStep,
                        onStepContinue: () {
                          if (_currentStep < _buildSteps().length - 1) {
                            setState(() {
                              _currentStep++;
                            });
                          } else {
                            _completeProfile();
                          }
                        },
                        onStepCancel: () {
                          if (_currentStep > 0) {
                            setState(() {
                              _currentStep--;
                            });
                          }
                        },
                        steps: _buildSteps(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
