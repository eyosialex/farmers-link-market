import 'package:cloud_firestore/cloud_firestore.dart';
import 'usermodel.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get usersCollection => _firestore.collection('Usersstore');

  Future<void> createUser(UserModel user) async {
    try {
      await usersCollection.doc(user.uid).set(user.toMap());
      print('✅ User created successfully: ${user.uid}');
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await usersCollection.doc(uid).update(updates);
      print('✅ User updated successfully: $uid');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Update user online status
  Future<void> updateUserStatus(String uid, bool isOnline) async {
    try {
      await usersCollection.doc(uid).update({
        'isOnline': isOnline,
        'lastseen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User status updated: $uid - Online: $isOnline');
    } catch (e) {
      print('❌ Error updating user status: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()! as Map<String, dynamic>);
        print('✅ User data retrieved: ${userData.fullName}');
        return userData;
      }
      print('❌ User document does not exist: $uid');
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  Future<bool> userExists(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    return doc.exists;
  }

  Future<void> completeUserProfile(String uid, Map<String, dynamic> profileData) async {
    try {
      await usersCollection.doc(uid).update({
        ...profileData,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User profile completed successfully: $uid');
    } catch (e) {
      print('❌ Error completing user profile: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  Future<List<UserModel>> getUsersByType(String userType) async {
    try {
      final querySnapshot = await usersCollection
          .where('userType', isEqualTo: userType)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting users by type: $e');
      return [];
    }
  }

  Future<List<UserModel>> getVerifiedUsers() async {
    try {
      final querySnapshot = await usersCollection
          .where('profileCompleted', isEqualTo: true)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting verified users: $e');
      return [];
    }
  }

  // Stream for real-time user status updates
  Stream<UserModel?> getUserStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    });
  }
}
