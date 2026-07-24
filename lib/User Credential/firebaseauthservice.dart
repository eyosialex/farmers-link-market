import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _updateUserStatus(userCredential.user!.uid, true);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }
  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      await _updateUserStatus(userCredential.user!.uid, true);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _updateUserStatus(user.uid, false);
    }
    await _firebaseAuth.signOut();
  }
  Future<void> _updateUserStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection("Usersstore").doc(uid).set({
        'isOnline': isOnline,
        'lastseen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user status: $e");
    }
  }
  Future<void> updateLastSeen() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection("Usersstore").doc(user.uid).update({
          'isOnline': false,
          'lastseen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error updating last seen: $e");
      }
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
