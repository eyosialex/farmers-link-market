import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, audio, pdf }

/// Interface for anything that can be part of a chat conversation
abstract class ChatEntity {
  String get senderId;
  Timestamp get timestamp;
}

/// Abstract base class for all chat messages
abstract class BaseMessage implements ChatEntity {
  @override
  final String senderId;
  final String senderEmail;
  final String? receiverId;
  final String? groupId;
  @override
  final Timestamp timestamp;
  final String? parentMessageId; // For threading/comments

  BaseMessage({
    required this.senderId,
    required this.senderEmail,
    this.receiverId,
    this.groupId,
    required this.timestamp,
    this.parentMessageId,
  });

  Map<String, dynamic> toMap();

  factory BaseMessage.fromMap(Map<String, dynamic> map) {
    final typeName = map['messageType'] ?? 'text';
    final type = MessageType.values.byName(typeName);
    
    switch (type) {
      case MessageType.image:
        return ImageMessage.fromMap(map);
      case MessageType.video:
        return VideoMessage.fromMap(map);
      case MessageType.audio:
        return AudioMessage.fromMap(map);
      case MessageType.pdf:
        return PdfMessage.fromMap(map);
      case MessageType.text:
        return TextMessage.fromMap(map);
    }
  }
}

/// Specialized message for text content
class TextMessage extends BaseMessage {
  final String content;

  TextMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required this.content,
    required super.timestamp,
    super.parentMessageId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'groupId': groupId,
      'message': content,
      'timestamp': timestamp,
      'messageType': MessageType.text.name,
      'parentMessageId': parentMessageId,
    };
  }

  factory TextMessage.fromMap(Map<String, dynamic> map) {
    return TextMessage(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      content: map['message'],
      timestamp: map['timestamp'],
      parentMessageId: map['parentMessageId'],
    );
  }
}

/// Base class for all media-based messages
abstract class MediaMessage extends BaseMessage {
  final String mediaUrl;
  final String? fileName;

  MediaMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required super.timestamp,
    required this.mediaUrl,
    this.fileName,
    super.parentMessageId,
  });
}

class ImageMessage extends MediaMessage {
  ImageMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required super.timestamp,
    required super.mediaUrl,
    super.fileName,
    super.parentMessageId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'groupId': groupId,
      'message': '[Image]',
      'timestamp': timestamp,
      'messageType': MessageType.image.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'parentMessageId': parentMessageId,
    };
  }

  factory ImageMessage.fromMap(Map<String, dynamic> map) {
    return ImageMessage(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      timestamp: map['timestamp'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      parentMessageId: map['parentMessageId'],
    );
  }
}

class VideoMessage extends MediaMessage {
  VideoMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required super.timestamp,
    required super.mediaUrl,
    super.fileName,
    super.parentMessageId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'groupId': groupId,
      'message': '[Video]',
      'timestamp': timestamp,
      'messageType': MessageType.video.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'parentMessageId': parentMessageId,
    };
  }

  factory VideoMessage.fromMap(Map<String, dynamic> map) {
    return VideoMessage(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      timestamp: map['timestamp'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      parentMessageId: map['parentMessageId'],
    );
  }
}

class AudioMessage extends MediaMessage {
  AudioMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required super.timestamp,
    required super.mediaUrl,
    super.fileName,
    super.parentMessageId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'groupId': groupId,
      'message': '[Audio]',
      'timestamp': timestamp,
      'messageType': MessageType.audio.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'parentMessageId': parentMessageId,
    };
  }

  factory AudioMessage.fromMap(Map<String, dynamic> map) {
    return AudioMessage(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      timestamp: map['timestamp'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      parentMessageId: map['parentMessageId'],
    );
  }
}

class PdfMessage extends MediaMessage {
  PdfMessage({
    required super.senderId,
    required super.senderEmail,
    super.receiverId,
    super.groupId,
    required super.timestamp,
    required super.mediaUrl,
    super.fileName,
    super.parentMessageId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'groupId': groupId,
      'message': '[PDF]',
      'timestamp': timestamp,
      'messageType': MessageType.pdf.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'parentMessageId': parentMessageId,
    };
  }

  factory PdfMessage.fromMap(Map<String, dynamic> map) {
    return PdfMessage(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      groupId: map['groupId'],
      timestamp: map['timestamp'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      parentMessageId: map['parentMessageId'],
    );
  }
}

// Keep the old name as an alias for backward compatibility if needed,
// but it's better to update references to BaseMessage or specific types.
typedef Message = BaseMessage;

