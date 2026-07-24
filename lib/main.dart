import 'package:flutter/foundation.dart';
import 'package:linkedfarm/User%20Credential/auth_gate.dart';
import 'package:linkedfarm/User%20Credential/log_in_or_register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:linkedfarm/Game/models/game_state.dart';

import 'package:linkedfarm/Services/local_storage_service.dart';
import 'package:linkedfarm/Farmers%20View/FireStore_Config.dart';
import 'package:linkedfarm/Services/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/l10n/fallback_localization.dart';

import 'package:linkedfarm/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Services
  await LocalStorageService.init(); // Safe for web (Hive)
  final localStorage = LocalStorageService();
  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider<LocalStorageService>.value(value: localStorage),
        Provider<FirestoreService>.value(value: firestoreService),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController textCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUserStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Set user offline when app closes
    _setUserOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = _auth.currentUser;
    
    if (user != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          _setUserOnline(user.uid);
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          _setUserOffline();
          break;
      }
    }
  }

  void _initializeUserStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _setUserOnline(user.uid);
    }
  }

  Future<void> _setUserOnline(String uid) async {
    try {
      await _firestore.collection('Usersstore').doc(uid).update({
        'isOnline': true,
        'lastseen': FieldValue.serverTimestamp(),
      });
      print('✅ User set online: $uid');
    } catch (e) {
      print('❌ Error setting user online: $e');
    }
  }

  Future<void> _setUserOffline() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('Usersstore').doc(user.uid).update({
          'isOnline': false,
          'lastseen': FieldValue.serverTimestamp(),
        });
        print('✅ User set offline: ${user.uid}');
      } catch (e) {
        print('❌ Error setting user offline: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkedFarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green[700],
          secondary: Colors.orange[700],
          surface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
        Locale('om'),
      ],
      locale: localeProvider.locale,
      home: const AuthGate(),
    );
  }
}
