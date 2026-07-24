
import 'package:linkedfarm/User%20Credential/create_account.dart';
import 'package:linkedfarm/User%20Credential/forget_password.dart';
import 'package:linkedfarm/User%20Credential/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'TextField.dart';
import 'firebaseauthservice.dart';
import 'userfirestore.dart';
    
class RegistrationPage extends StatefulWidget {
  final void Function()? onTap;
  const RegistrationPage({super.key, required this.onTap});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}
class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController fullName = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final FirebaseAuthService authService = FirebaseAuthService();
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;
  String? _selectedUserType;

  Future<void> register() async {
    final _email = email.text.trim();
    final _password = password.text.trim();
    final _confirmPassword = confirmPassword.text.trim();
    final _fullName = fullName.text.trim();
    final _phoneNumber = phoneNumber.text.trim();

    // Validation
    if (_email.isEmpty || _password.isEmpty || _confirmPassword.isEmpty || 
        _fullName.isEmpty || _phoneNumber.isEmpty || _selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordsNotMatch)),
      );
      return;
    }

    if (_password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordTooShort)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with Firebase Auth
      final userCredential = await authService.signUp(_email, _password);
      final user = userCredential.user;

      if (user != null) {
        UserModel userModel;
        
        switch (_selectedUserType) {
          case 'farmer':
            userModel = FarmerUser(
              uid: user.uid,
              email: _email,
              fullName: _fullName,
              phoneNumber: _phoneNumber,
              profileCompleted: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            break;
          case 'vendor':
            userModel = VendorUser(
              uid: user.uid,
              email: _email,
              fullName: _fullName,
              phoneNumber: _phoneNumber,
              profileCompleted: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            break;
          default:
            userModel = GenericAppUser(
              uid: user.uid,
              email: _email,
              fullName: _fullName,
              phoneNumber: _phoneNumber,
              userType: _selectedUserType!,
              profileCompleted: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
        }

        await _userRepository.createUser(userModel);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.registrationSuccess)),
        );

        // Navigate to create account to complete profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateAccount()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.somethingWentWrong;
      if (e.code == 'email-already-in-use') {
        message = l10n.emailInUse;
      } else if (e.code == 'weak-password') {
        message = l10n.weakPassword;
      } else if (e.code == 'invalid-email') {
        message = l10n.invalidEmailAddress;
      } else if (e.code == 'network-request-failed') {
        message = l10n.networkError;
      } else {
        message = "${l10n.somethingWentWrong}: [${e.code}] ${e.message}";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.somethingWentWrong}: [${e.code}] ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${AppLocalizations.of(context)!.somethingWentWrong}: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.agriculture, size: 80, color: Colors.green[800]),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.registerSubTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Full Name
                Mytextfield(
                  con: fullName,
                  HintText: AppLocalizations.of(context)!.fullNameHint,
                  valid: false,
                ),
                const SizedBox(height: 15),

                // Email
                Mytextfield(
                  con: email,
                  HintText: AppLocalizations.of(context)!.emailHint,
                  valid: false,
                ),
                const SizedBox(height: 15),

                // Phone Number
                Mytextfield(
                  con: phoneNumber,
                  HintText: AppLocalizations.of(context)!.phoneHint,
                  valid: false,
                ),
                const SizedBox(height: 15),

                // User Type Selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButtonFormField<String>(
                      value: _selectedUserType,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: AppLocalizations.of(context)!.selectRole,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'farmer',
                          child: Text(AppLocalizations.of(context)!.roleFarmer),
                        ),
                        DropdownMenuItem(
                          value: 'vendor',
                          child: Text(AppLocalizations.of(context)!.roleVendor),
                        ),
                           DropdownMenuItem(
                          value: 'advisor',
                          child: Text(AppLocalizations.of(context)!.roleAdvisor),
                        ),
                               DropdownMenuItem(
                          value: 'delivery',
                          child: Text(AppLocalizations.of(context)!.roleDelivery),
                        ),
                        DropdownMenuItem(
                          value: 'shopper',
                          child: Text(AppLocalizations.of(context)!.roleShopper),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Password
                Mytextfield(
                  con: password,
                  HintText: AppLocalizations.of(context)!.passwordHint,
                  valid: true,
                ),
                const SizedBox(height: 15),

                // Confirm Password
                Mytextfield(
                  con: confirmPassword,
                  HintText: AppLocalizations.of(context)!.confirmPasswordHint,
                  valid: true,
                ),
                const SizedBox(height: 25),

                // Register Button
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : GestureDetector(
                        onTap: register,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.registerButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.alreadyHaveAccount),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        AppLocalizations.of(context)!.loginButton,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
