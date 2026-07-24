import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linkedfarm/User%20Credential/log_in_or_register.dart';
import 'package:linkedfarm/User%20Credential/create_account.dart';
import 'package:linkedfarm/Farmers%20View/Farmers_Home.dart';
import 'package:linkedfarm/Vendors%20View/Product_Home.dart';
import 'package:linkedfarm/Advisor%20View/Advisor_Home.dart';
import 'package:linkedfarm/Shopper%20View/Shopper_Home.dart';
import 'package:linkedfarm/Dlivery%20View/home_delivery.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is NOT logged in
        if (!snapshot.hasData) {
          return const LogInOrRegister();
        }

        // User IS logged in, now check their profile status and user type
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('Usersstore')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // This case shouldn't happen normally, but if it does, show login
              return const LogInOrRegister();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final userType = userData['userType'] as String;
            final profileCompleted = userData['profileCompleted'] as bool? ?? false;

            // If profile is not completed and user is not a shopper, redirect to CreateAccount
            if (!profileCompleted && userType != 'shopper') {
              return const CreateAccount();
            }

            // Redirect based on user type
            switch (userType) {
              case 'farmer':
                return const FarmersHomePage();
              case 'vendor':
                return const vendors_page();
              case 'advisor':
                return const AdvisorHomePage();
              case 'delivery':
                return const HomeDelivery();
              case 'shopper':
                return const ShopperHomePage();
              default:
                return const FarmersHomePage();
            }
          },
        );
      },
    );
  }
}
