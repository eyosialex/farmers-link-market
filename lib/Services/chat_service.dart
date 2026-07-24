import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linkedfarm/Services/websocket_service.dart';
import 'package:linkedfarm/Chat/chat_model.dart';
import 'package:linkedfarm/Chat/group_model.dart';
import 'package:linkedfarm/Farmers%20View/Cloudnary_Store.dart';
import 'dart:convert'; // Added for json.decode
import 'package:http/http.dart' as http; // Added for http requests
import 'package:linkedfarm/Chat/chat_interface.dart';

class ChatService extends ChangeNotifier implements IChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Cloudinary Service instead of Firebase Storage
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final WebSocketService _webSocketService = WebSocketService();

  ChatService() {
    _webSocketService.connect();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  // EXPOSE WEBSOCKET STREAM
  Stream get webSocketStream => _webSocketService.stream;

  // SEND MESSAGE (Updated for Polymorphism)
  @override
  Future<void> sendMessage(String receiverID, String message, {MessageType type = MessageType.text, String? mediaUrl, String? fileName}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    
    // Broadcast via WebSocket
    _webSocketService.sendMessage(currentUserId, receiverID, message);

    BaseMessage newMessage;
    
    switch (type) {
      case MessageType.image:
        newMessage = ImageMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverID,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
        );
        break;
      case MessageType.video:
        newMessage = VideoMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverID,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
        );
        break;
      case MessageType.audio:
        newMessage = AudioMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverID,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
        );
        break;
      case MessageType.pdf:
        newMessage = PdfMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverID,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
        );
        break;
      case MessageType.text:
      default:
        newMessage = TextMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverID,
          content: message,
          timestamp: timestamp,
        );
    }

    List<String> ids = [currentUserId, receiverID];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update 'latest_message' for Inbox
    var updateData = {
      'chatRoomId': chatRoomId,
      'otherUserId': receiverID,
      'lastMessage': type == MessageType.text ? message : '[Media]',
      'timestamp': timestamp,
    };

    await _firestore
        .collection('user_chats')
        .doc(currentUserId)
        .collection('chats')
        .doc(receiverID)
        .set(updateData, SetOptions(merge: true));

    var receiverUpdateData = {
      'chatRoomId': chatRoomId,
      'otherUserId': currentUserId,
      'lastMessage': type == MessageType.text ? message : '[Media]',
      'timestamp': timestamp,
    };

    await _firestore
        .collection('user_chats')
        .doc(receiverID)
        .collection('chats')
        .doc(currentUserId)
        .set(receiverUpdateData, SetOptions(merge: true));
  }

  // MEDIA UPLOAD
  @override
  Future<String> uploadMedia(dynamic file, String folder) async {
    String? mediaUrl = await _cloudinaryService.uploadFile(file, folder: folder);
    if (mediaUrl != null) {
      return mediaUrl;
    } else {
      throw Exception("Failed to upload media to Cloudinary");
    }
  }

  // SEARCH USERS
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection('Usersstore')
        .where('fullName', isGreaterThanOrEqualTo: query)
        .where('fullName', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  // GROUP LOGIC
  Future<void> createGroup(String groupName, List<String> memberIds, {String type = 'group'}) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    DocumentReference groupRef = _firestore.collection('groups').doc();
    
    GroupModel newGroup = GroupModel(
      groupId: groupRef.id,
      name: groupName,
      members: memberIds,
      adminIds: [currentUserId],
      type: type,
      lastMessage: type == 'channel' ? "Channel created" : "Group created",
      lastSenderId: currentUserId,
      timestamp: Timestamp.now(),
    );

    await groupRef.set(newGroup.toMap());
  }

  Future<void> sendGroupMessage(String groupId, String message, {MessageType type = MessageType.text, String? mediaUrl, String? fileName, String? parentMessageId}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    BaseMessage newMessage;
    
    switch (type) {
      case MessageType.image:
        newMessage = ImageMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          groupId: groupId,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
          parentMessageId: parentMessageId,
        );
        break;
      case MessageType.video:
        newMessage = VideoMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          groupId: groupId,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
          parentMessageId: parentMessageId,
        );
        break;
      case MessageType.audio:
        newMessage = AudioMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          groupId: groupId,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
          parentMessageId: parentMessageId,
        );
        break;
      case MessageType.pdf:
        newMessage = PdfMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          groupId: groupId,
          timestamp: timestamp,
          mediaUrl: mediaUrl!,
          fileName: fileName,
          parentMessageId: parentMessageId,
        );
        break;
      case MessageType.text:
      default:
        newMessage = TextMessage(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          groupId: groupId,
          content: message,
          timestamp: timestamp,
          parentMessageId: parentMessageId,
        );
    }

    // Broadcast via WebSocket
    _webSocketService.sendMessage(currentUserId, groupId, message);

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add(newMessage.toMap());

    if (parentMessageId == null) {
      await _firestore.collection('groups').doc(groupId).update({
        'lastMessage': type == MessageType.text ? message : '[Media]',
        'lastSenderId': currentUserId,
        'timestamp': timestamp,
      });
    }
  }


  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .where('parentMessageId', isNull: true) // Only show top-level posts
        .snapshots();
  }

  Stream<QuerySnapshot> getComments(String groupId, String parentMessageId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .where('parentMessageId', isEqualTo: parentMessageId)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserGroups() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots();
  }
  
  // GET USER CHATS (INBOX)
  Stream<QuerySnapshot> getUserChats() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('user_chats')
        .doc(currentUserId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // construct chat room ID for the two users
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // REMOVE MEMBER FROM GROUP
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]), // Also remove from admins if they were one
      });
      print('✅ User $userId removed from group $groupId');
    } catch (e) {
      print('❌ Error removing member: $e');
      rethrow;
    }
  }

  // ADD MEMBER TO GROUP
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
      print('✅ User $userId added to group $groupId');
    } catch (e) {
      print('❌ Error adding member: $e');
      rethrow;
    }
  }

  // UPDATE GROUP PHOTO
  Future<void> updateGroupPhoto(String groupId, String photoUrl) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'groupIconUrl': photoUrl,
      });
      print('✅ Group $groupId photo updated');
    } catch (e) {
      print('❌ Error updating group photo: $e');
      rethrow;
    }
  }

  // GET INDIVIDUAL USER STREAM (for online status/last seen)
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('Usersstore').doc(userId).snapshots();
  }
}
