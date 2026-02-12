import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/User%20Credential/usermodel.dart';
import 'package:linkedfarm/User%20Credential/userfirestore.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/Services/locale_provider.dart';
import 'package:linkedfarm/Services/locale_provider.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final bool isMe;

  const ProfilePage({
    super.key,
    required this.userId,
    this.isMe = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserRepository _userRepo = UserRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isLoading = true;
  UserModel? _user;
  bool _isEditing = false;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  // Farmer specific controllers
  late TextEditingController _farmNameController;
  late TextEditingController _farmLocationController;
  late TextEditingController _farmSizeController;
  late TextEditingController _cropsController;
  
  // Vendor specific controllers
  late TextEditingController _businessNameController;
  late TextEditingController _businessTypeController;
  late TextEditingController _businessAddressController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await _userRepo.getUser(widget.userId);
    if (user != null) {
      setState(() {
        _user = user;
        _nameController = TextEditingController(text: user.fullName);
        _phoneController = TextEditingController(text: user.phoneNumber);
        
        _farmNameController = TextEditingController(text: user.farmName ?? "");
        _farmLocationController = TextEditingController(text: user.farmLocation ?? "");
        _farmSizeController = TextEditingController(text: user.farmSize ?? "");
        _cropsController = TextEditingController(text: user.crops ?? "");
        
        _businessNameController = TextEditingController(text: user.businessName ?? "");
        _businessTypeController = TextEditingController(text: user.businessType ?? "");
        _businessAddressController = TextEditingController(text: user.businessAddress ?? "");
        
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;
    
    setState(() => _isLoading = true);
    try {
      final updates = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };

      if (_user!.userType == 'farmer') {
        updates['farmName'] = _farmNameController.text.trim();
        updates['farmLocation'] = _farmLocationController.text.trim();
        updates['farmSize'] = _farmSizeController.text.trim();
        updates['crops'] = _cropsController.text.trim();
      } else if (_user!.userType == 'vendor') {
        updates['businessName'] = _businessNameController.text.trim();
        updates['businessType'] = _businessTypeController.text.trim();
        updates['businessAddress'] = _businessAddressController.text.trim();
      }

      await _userRepo.updateUser(_user!.uid, updates);
      
      final updatedUser = _user!.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        farmName: updates['farmName'],
        farmLocation: updates['farmLocation'],
        farmSize: updates['farmSize'],
        crops: updates['crops'],
        businessName: updates['businessName'],
        businessType: updates['businessType'],
        businessAddress: updates['businessAddress'],
      );

      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      String? imageUrl = await _cloudinaryService.uploadImage(File(pickedFile.path));
      
      if (imageUrl != null) {
        await _userRepo.updateUser(_user!.uid, {'photoUrl': imageUrl});
        final updatedUser = _user!.copyWith(photoUrl: imageUrl);
        setState(() {
          _user = updatedUser;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo upload failed")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text("User not found")));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.isMe ? "My Profile" : "User Profile"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          if (widget.isMe && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.green[100],
                        backgroundImage: _user!.photoUrl != null ? NetworkImage(_user!.photoUrl!) : null,
                        child: _user!.photoUrl == null 
                          ? Text(_user!.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.green))
                          : null,
                      ),
                      if (widget.isMe)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _changePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: "Full Name"),
                      ),
                    )
                  else
                    Text(
                      _user!.fullName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user!.userType.toUpperCase(),
                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Info Section
            _buildInfoCard(
              title: "Contact Information",
              children: [
                _buildInfoTile(Icons.email, "Email", _user!.email),
                if (_isEditing)
                  _buildEditTile(Icons.phone, "Phone Number", _phoneController)
                else
                  _buildInfoTile(Icons.phone, "Phone", _user!.phoneNumber),
              ],
            ),

            // Role specific info
            if (_user!.userType == 'farmer')
              _buildInfoCard(
                title: "Farm Details",
                children: _isEditing 
                  ? [
                      _buildEditTile(Icons.agriculture, "Farm Name", _farmNameController),
                      _buildEditTile(Icons.location_on, "Location", _farmLocationController),
                      _buildEditTile(Icons.settings_overscan, "Size", _farmSizeController),
                      _buildEditTile(Icons.grass, "Crops", _cropsController),
                    ]
                  : [
                      _buildInfoTile(Icons.agriculture, "Farm Name", _user!.farmName ?? "N/A"),
                      _buildInfoTile(Icons.location_on, "Location", _user!.farmLocation ?? "N/A"),
                      _buildInfoTile(Icons.settings_overscan, "Size", _user!.farmSize ?? "N/A"),
                      _buildInfoTile(Icons.grass, "Crops", _user!.crops ?? "N/A"),
                    ],
              ),

            if (_user!.userType == 'vendor')
              _buildInfoCard(
                title: "Business Details",
                children: _isEditing
                  ? [
                      _buildEditTile(Icons.store, "Business Name", _businessNameController),
                      _buildEditTile(Icons.business_center, "Type", _businessTypeController),
                      _buildEditTile(Icons.location_on, "Address", _businessAddressController),
                    ]
                  : [
                      _buildInfoTile(Icons.store, "Business Name", _user!.businessName ?? "N/A"),
                      _buildInfoTile(Icons.business_center, "Type", _user!.businessType ?? "N/A"),
                      _buildInfoTile(Icons.location_on, "Address", _user!.businessAddress ?? "N/A"),
                    ],
              ),

            // Status Section
            _buildInfoCard(
              title: "Activity",
              children: [
                _buildInfoTile(
                  Icons.circle, 
                  "Status", 
                  _user!.isOnline ? "Online" : "Offline", 
                  color: _user!.isOnline ? Colors.green : Colors.grey
                ),
                if (!_user!.isOnline && _user!.lastseen != null)
                  _buildInfoTile(Icons.access_time, "Last Seen", _user!.lastseen.toString().split('.')[0]),
                _buildInfoTile(Icons.calendar_today, "Member Since", _user!.createdAt.toString().split(' ')[0]),
              ],
            ),

            const SizedBox(height: 10),
            const SizedBox(height: 40),
            if (widget.isMe)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50], 
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    side: BorderSide(color: Colors.red.withOpacity(0.3))
                  ),
                  child: const Center(child: Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color ?? Colors.grey[400]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.language, color: Colors.green),
              SizedBox(width: 10),
              Text('Select Language'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, 'English', 'en'),
              _buildLanguageOption(context, 'አማርኛ (Amharic)', 'am'),
              _buildLanguageOption(context, 'Oromiffa (Oromo)', 'om'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String code) {
    return ListTile(
      title: Text(name),
      onTap: () {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildEditTile(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.green[300]),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
