import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_model.dart';

/// Interface for Chat Service logic to ensure consistency across different platforms/implementations
abstract class IChatService {
  Future<void> sendMessage(String receiverId, String message, {required MessageType type, String? mediaUrl, String? fileName});
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId);
  Future<String> uploadMedia(dynamic file, String folder);
}

/// Interface for Chat UI logic (Pages/Controllers)
abstract class IChatPage {
  void sendMessage();
  Future<void> pickAndSendMedia();
}

/// Mixin to provide common formatting and validation logic for chat screens
mixin ChatLogicMixin {
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool isValidMessage(String message) {
    return message.trim().isNotEmpty;
  }
}
