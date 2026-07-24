import 'package:linkedfarm/Dlivery View/home_delivery.dart';
import 'package:linkedfarm/Farmers%20View/Farmers_Home.dart';
import 'package:linkedfarm/Vendors%20View/Product_Home.dart';
import 'package:linkedfarm/Advisor%20View/Advisor_Home.dart';
import 'package:linkedfarm/Shopper%20View/Shopper_Home.dart';
import 'package:linkedfarm/User%20Credential/create_account.dart';
import 'package:linkedfarm/User%20Credential/forget_password.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'TextField.dart';
import 'firebaseauthservice.dart';

class LogInPage extends StatefulWidget {
  final void Function()? onTap;
  const LogInPage({super.key, required this.onTap});
  
  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FirebaseAuthService signin = FirebaseAuthService();
  bool _isLoading = false;

  void login() async {
    final _email = email.text.trim();
    final _password = password.text.trim();
    
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userCredential = await signin.signIn(_email, _password);
      final user = userCredential.user;
      
      if (user != null) {
        // Fetch user data to check user type and if profile is completed
        final userDoc = await FirebaseFirestore.instance
            .collection('Usersstore')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userType = userData['userType'] as String;
          final profileCompleted = userData['profileCompleted'] as bool? ?? false;
          
          if (!profileCompleted && userType != 'shopper') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CreateAccount()),
            );
          } else {
            // Navigate based on user type
            Widget homePage;
            switch (userType) {
              case 'farmer':
                homePage = const FarmersHomePage();
                break;
              case 'vendor':
                homePage = const vendors_page();
                break;
              case 'advisor':
                homePage = const AdvisorHomePage();
                break;
              case 'delivery':
                homePage = const HomeDelivery();
                break;
              case 'shopper':
                homePage = const ShopperHomePage();
                break;
              default:
                homePage = const FarmersHomePage();
            }
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => homePage),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String message = l10n.somethingWentWrong;
      if (e.code == 'user-not-found') {
        message = l10n.userNotFound;
      } else if (e.code == 'wrong-password') {
        message = l10n.wrongPassword;
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
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.loginSubTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                Mytextfield(
                  con: email,
                  HintText: AppLocalizations.of(context)!.emailHint,
                  valid: false,
                ),
                const SizedBox(height: 15),

                Mytextfield(
                  con: password,
                  HintText: AppLocalizations.of(context)!.passwordHint,
                  valid: true,
                ),
                const SizedBox(height: 25),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : GestureDetector(
                        onTap: login,
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
                              AppLocalizations.of(context)!.loginButton,
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
                    Text(AppLocalizations.of(context)!.noAccount),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        AppLocalizations.of(context)!.registerAction,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgetPassword()),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
