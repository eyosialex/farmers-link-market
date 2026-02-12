import 'dart:async';
import 'package:linkedfarm/Services/io_compatibility.dart' if (dart.library.html) 'package:linkedfarm/Services/web_compatibility.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkedfarm/Services/chat_service.dart';
import 'package:linkedfarm/Chat/chat_model.dart';
import 'package:linkedfarm/Chat/image_preview_page.dart';
import 'package:linkedfarm/Chat/video_player_page.dart';
import 'package:linkedfarm/Chat/widgets/chat_input_field.dart';
import 'package:linkedfarm/Chat/widgets/message_bubble.dart';
import 'package:linkedfarm/User%20Credential/usermodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _webSocketSubscription;
  bool _showEmoji = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Listen to WebSocket for instant notifications or UI updates (No SnackBar)
    _webSocketSubscription = _chatService.webSocketStream.listen((event) {
      // Logic for background message handling can go here
    });
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverUserID,
        _messageController.text,
        type: MessageType.text,
      );
      _messageController.clear();
    }
  }

  Future<void> _pickAndSendMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4', 'mp3', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String ext = result.files.single.extension?.toLowerCase() ?? '';
      
      setState(() => _isUploading = true);
      
      try {
        MessageType type = MessageType.text;
        if (['jpg', 'png', 'jpeg'].contains(ext)) type = MessageType.image;
        else if (ext == 'mp4') type = MessageType.video;
        else if (ext == 'mp3') type = MessageType.audio;
        else if (ext == 'pdf') type = MessageType.pdf;

        String url = await _chatService.uploadMedia(file, 'chat_media');
        
        await _chatService.sendMessage(
          widget.receiverUserID,
          "[Media: $fileName]",
          type: type,
          mediaUrl: url,
          fileName: fileName,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _chatService.getUserStream(widget.receiverUserID),
          builder: (context, snapshot) {
            String status = "Offline";
            Color statusColor = Colors.white70;

            if (snapshot.hasData && snapshot.data!.data() != null) {
              UserModel user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
              if (user.isOnline) {
                status = "Online";
                statusColor = Colors.orangeAccent[100]!;
              } else if (user.lastseen != null) {
                status = _formatLastSeen(user.lastseen!);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverUserEmail, style: const TextStyle(fontSize: 16)),
                Text(
                  status, 
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.normal)
                ),
              ],
            );
          }
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // messages
          Expanded(
            child: _buildMessageList(),
          ),

          // user input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(
        widget.receiverUserID,
        _auth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == _auth.currentUser!.uid;
    String? mediaUrl = data['mediaUrl'];
    String? typeStr = data['messageType'];

    return GestureDetector(
      onTap: () {
        if (typeStr == MessageType.image.name && mediaUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewPage(imageUrl: mediaUrl),
            ),
          );
        } else if (typeStr == MessageType.video.name && mediaUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(
                videoUrl: mediaUrl,
                title: data['fileName'] ?? "Video",
              ),
            ),
          );
        }
      },
      child: MessageBubble(
        data: data,
        isMe: isMe,
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return "last seen just now";
    } else if (difference.inMinutes < 60) {
      return "last seen ${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "last seen ${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "last seen ${DateFormat('E hh:mm a').format(lastSeen)}";
    } else {
      return "last seen ${DateFormat('MMM d, yyyy').format(lastSeen)}";
    }
  }

  Widget _buildMessageInput() {
    return ChatInputField(
      controller: _messageController,
      onSend: sendMessage,
      onAttach: _pickAndSendMedia,
      isUploading: _isUploading,
    );
  }
}
